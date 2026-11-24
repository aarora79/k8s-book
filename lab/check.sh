#!/usr/bin/env bash
# Checks that the tools are installed and the lab cluster is healthy.
# Run it with `make check` from the repo root.
set -uo pipefail

CLUSTER="${CLUSTER:-lab}"
WANT_K8S="v1.34"
failures=0

# Sets RUNTIME to docker or podman and points kind at the same one.
. "$(dirname "$0")/runtime.sh"

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; failures=$((failures + 1)); }

echo "Tools"
for tool in kind kubectl go curl jq; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "$tool found at $(command -v "$tool")"
  else
    fail "$tool is not installed (see chapters/00-map-and-lab/README.md)"
  fi
done

if command -v go >/dev/null 2>&1; then
  gov=$(go env GOVERSION | sed 's/^go//')
  major=${gov%%.*}; rest=${gov#*.}; minor=${rest%%.*}
  if [ "$major" -gt 1 ] || { [ "$major" -eq 1 ] && [ "$minor" -ge 24 ]; }; then
    pass "go $gov (need 1.24 or later)"
  else
    fail "go $gov is too old (need 1.24 or later)"
  fi
fi

if command -v kind >/dev/null 2>&1; then
  kv=$(kind version | awk '{print $2}')
  case "$kv" in
    v0.30.*) pass "kind $kv" ;;
    *) fail "kind $kv (the book is tested on v0.30.0)" ;;
  esac
fi

echo "Container runtime"
if [ -n "$RUNTIME" ] && "$RUNTIME" info >/dev/null 2>&1; then
  pass "$RUNTIME is running"
else
  fail "no running container runtime (install and start Docker or Podman)"
fi

echo "Cluster"
if ! cluster_exists "$CLUSTER"; then
  fail "kind cluster '$CLUSTER' does not exist (run make lab)"
else
  pass "kind cluster '$CLUSTER' exists"
  ctx="kind-$CLUSTER"
  sv=$(kubectl --context "$ctx" version -o json 2>/dev/null | jq -r '.serverVersion.gitVersion')
  case "$sv" in
    "$WANT_K8S".*) pass "API server is $sv" ;;
    *) fail "API server version is '$sv' (want $WANT_K8S.x)" ;;
  esac
  ready=$(kubectl --context "$ctx" get nodes -o json 2>/dev/null \
    | jq '[.items[] | select(any(.status.conditions[]; .type == "Ready" and .status == "True"))] | length')
  if [ "${ready:-0}" -eq 3 ]; then
    pass "3 of 3 nodes Ready"
  else
    fail "${ready:-0} of 3 nodes Ready (wait a minute and run make check again)"
  fi
  if arch=$("$RUNTIME" exec "$CLUSTER-worker" uname -m 2>/dev/null); then
    pass "can run commands inside $CLUSTER-worker (arch $arch)"
  else
    fail "cannot $RUNTIME exec into $CLUSTER-worker"
  fi
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "The lab is ready."
else
  echo "$failures check(s) failed."
  exit 1
fi
