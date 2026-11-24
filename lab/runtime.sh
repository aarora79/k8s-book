#!/bin/sh
# Picks the container runtime for the lab: Docker or Podman. Source this file
# from another script. It sets RUNTIME and tells kind to use the same one.
#
# To choose yourself, set CONTAINER_RUNTIME to docker or podman. Otherwise the
# first runtime that is installed and running wins, trying docker first.

RUNTIME="${CONTAINER_RUNTIME:-}"

if [ -z "$RUNTIME" ]; then
  for candidate in docker podman; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" info >/dev/null 2>&1; then
      RUNTIME="$candidate"
      break
    fi
  done
fi

if [ -n "$RUNTIME" ]; then
  KIND_EXPERIMENTAL_PROVIDER="$RUNTIME"
  export KIND_EXPERIMENTAL_PROVIDER
fi

# Succeeds if the named kind cluster has nodes. This asks for nodes because
# `kind get clusters` in kind 0.30.0 fails on Podman 6.2.0.
cluster_exists() {
  nodes=$(kind get nodes --name "$1" 2>/dev/null) && [ -n "$nodes" ]
}

# Stops with a clear message unless the chosen runtime is ready.
require_runtime() {
  case "$RUNTIME" in
    docker | podman) ;;
    "")
      echo "No running container runtime found. Install and start Docker or Podman (see chapters/00-map-and-lab/README.md)."
      exit 1
      ;;
    *)
      echo "CONTAINER_RUNTIME must be docker or podman, not '$RUNTIME'."
      exit 1
      ;;
  esac
  if ! "$RUNTIME" info >/dev/null 2>&1; then
    echo "$RUNTIME is not running. Start it, then try again."
    exit 1
  fi
}
