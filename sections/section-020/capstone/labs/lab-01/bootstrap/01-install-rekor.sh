#!/usr/bin/env bash
# Installs the environment (`ats-121-capstone-020`).
#
# Installs Helm (pinned), the CoreDNS rewrite for rekor.localtest.me, the
# workstation pod and a private Rekor v1, then writes the lab trust files
# (/lab/rekor.pub, signing-config.json, trusted-root.json) in the workstation.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

HELM_VERSION="3.22.1"
REKOR_CHART_VERSION="1.8.7"
REKOR_HOST="rekor.localtest.me"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# manifest_dir: prints the folder that holds this environment's manifests.
manifest_dir() {
  local script_dir candidate
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for candidate in "$script_dir/../manifests" "./manifests" "$script_dir/manifests"; do
    [ -d "$candidate" ] && { (cd "$candidate" && pwd); return 0; }
  done
  echo "manifests folder not found" >&2
  return 1
}

# Runs a command in the workstation pod.
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# install_helm: puts the pinned Helm on the PATH.
install_helm() {
  local have os arch work
  have=""
  command -v helm >/dev/null 2>&1 && have=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
  if [ "$have" != "$HELM_VERSION" ]; then
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"
    case "$arch" in x86_64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; esac
    work="$(mktemp -d)"
    echo "[env] Downloading Helm ${HELM_VERSION} (${os}/${arch})..."
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${os}-${arch}.tar.gz" | tar -xz -C "$work"
    install -m 0755 "$work/${os}-${arch}/helm" "$BIN_DIR/helm"
    rm -rf "$work"
  fi
  helm version --short
}

# add_coredns_rewrite HOST TARGET: makes HOST resolve to TARGET inside the
# cluster. The answer is rewritten back to the asked name: Go programs
# (cosign and rekor-cli included) ignore DNS answers whose name differs from
# the question.
add_coredns_rewrite() {
  local host="$1" target="$2" host_re target_re corefile
  if kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$host"; then
    return 0
  fi
  host_re="$(printf '%s' "$host" | sed 's/\./\\./g')"
  target_re="$(printf '%s' "$target" | sed 's/\./\\./g')"
  echo "[env] Adding the CoreDNS rewrite for ${host}..."
  corefile="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | NAME_LINE="        name regex ${host_re} ${target}" \
      ANSWER_LINE="        answer name ${target_re} ${host}" \
      awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print ENVIRON["NAME_LINE"]
        print ENVIRON["ANSWER_LINE"]
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$corefile" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
}

# install_environment: CoreDNS rewrite, workstation pod, private Rekor, and
# the lab trust files in /lab.
install_environment() {
  local dir
  dir="$(manifest_dir)"
  install_helm
  add_coredns_rewrite "$REKOR_HOST" "rekor-server.rekor-system.svc.cluster.local"

  # lab-start.yaml is also listed under bootstrap.manifests in config.yaml,
  # so it may already be applied. kubectl apply is idempotent.
  echo "[env] Starting the workstation pod..."
  kubectl apply -f "$dir/lab-start.yaml"

  echo "[env] Installing the private Rekor (chart ${REKOR_CHART_VERSION}); this takes several minutes..."
  helm repo add sigstore https://sigstore.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo update sigstore >/dev/null
  helm upgrade --install rekor sigstore/rekor --version "$REKOR_CHART_VERSION" \
    --namespace rekor-system --create-namespace \
    --values "$dir/rekor-values.yaml" \
    --wait --timeout 20m

  kubectl -n workstation rollout status deployment/workstation --timeout=600s
  for _ in $(seq 1 60); do
    ws sh -c 'command -v jq >/dev/null && command -v rev >/dev/null' 2>/dev/null && break
    sleep 5
  done
  echo "[env] Waiting until the workstation reaches Rekor..."
  for _ in $(seq 1 60); do
    ws sh -c 'curl -sf "$REKOR_URL/api/v1/log" >/dev/null' 2>/dev/null && break
    sleep 5
  done
  ws sh /setup/lab-init.sh
}

install_environment
