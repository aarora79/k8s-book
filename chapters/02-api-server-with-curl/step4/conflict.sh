#!/usr/bin/env bash
# Step 4: optimistic concurrency. Two writers read the same version; the
# second one to write loses with 409 Conflict instead of silently overwriting.
# A ConfigMap keeps the demo quiet: no scheduler or kubelet writes to it.
set -euo pipefail
. "$(dirname "$0")/../env.sh"
url="$API/api/v1/namespaces/$NS/configmaps/settings"

curl -sS -o /dev/null -X POST "$API/api/v1/namespaces/$NS/configmaps" \
  -H 'Content-Type: application/json' \
  -d '{"apiVersion":"v1","kind":"ConfigMap","metadata":{"name":"settings"},"data":{"owner":"nobody"}}'

echo "== writer A and writer B both read the ConfigMap"
a=$(curl -sS "$url"); b="$a"
echo "both hold resourceVersion $(echo "$a" | jq -r .metadata.resourceVersion)"

echo "== writer A replaces it with owner=a"
echo "$a" | jq '.data.owner = "a"' \
  | curl -sS -X PUT "$url" -H 'Content-Type: application/json' -d @- \
  | jq '{owner: .data.owner, resourceVersion: .metadata.resourceVersion}'

echo "== writer B replaces it with owner=b, from its stale copy"
echo "$b" | jq '.data.owner = "b"' \
  | curl -sS -X PUT "$url" -H 'Content-Type: application/json' -d @- \
  | jq '{code, reason, message}'

echo "== writer B reads again and retries"
curl -sS "$url" | jq '.data.owner = "b"' \
  | curl -sS -X PUT "$url" -H 'Content-Type: application/json' -d @- \
  | jq '{owner: .data.owner, resourceVersion: .metadata.resourceVersion}'

curl -sS -o /dev/null -X DELETE "$url"
