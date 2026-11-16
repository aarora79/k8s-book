#!/usr/bin/env bash
# Step 5: a watch cannot start from too far back. The API server keeps a
# window of recent changes; older resourceVersions get 410 Gone.
set -euo pipefail
. "$(dirname "$0")/../env.sh"

echo "== watch pods from resourceVersion 1"
curl -sS "$API/api/v1/namespaces/$NS/pods?watch=true&resourceVersion=1&timeoutSeconds=5" | jq -c '{type, code: .object.code, reason: .object.reason, message: .object.message}'

echo "== the fix: list again for a fresh resourceVersion, then watch from that"
rv=$(curl -sS "$API/api/v1/namespaces/$NS/pods" | jq -r '.metadata.resourceVersion')
echo "fresh resourceVersion $rv"
curl -sS -o /dev/null -w 'watch from %{url_effective} -> HTTP %{http_code}\n' \
  "$API/api/v1/namespaces/$NS/pods?watch=true&resourceVersion=$rv&timeoutSeconds=2"
