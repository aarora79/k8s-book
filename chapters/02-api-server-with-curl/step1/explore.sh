#!/usr/bin/env bash
# Step 1: look around. Every path here is a plain HTTP GET.
set -euo pipefail
. "$(dirname "$0")/../env.sh"

echo "== version"
curl -sS "$API/version" | jq '{gitVersion, platform}'

echo "== the core group: /api/v1 and some of its resources"
curl -sS "$API/api/v1" | jq -r '.resources[] | select(.name | contains("/") | not) | .name' | head -12

echo "== named groups under /apis"
curl -sS "$API/apis" | jq -r '.groups[].preferredVersion.groupVersion' | head -12

echo "== one resource, described"
curl -sS "$API/api/v1" | jq '.resources[] | select(.name == "pods") | {name, namespaced, kind, verbs}'
