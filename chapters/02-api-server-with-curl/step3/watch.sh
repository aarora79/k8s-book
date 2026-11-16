#!/usr/bin/env bash
# Step 3: list once, then watch from that list's resourceVersion while
# another process creates, changes and deletes a pod.
set -euo pipefail
. "$(dirname "$0")/../env.sh"
here=$(dirname "$0")
events=$(mktemp)

rv=$(curl -sS "$API/api/v1/namespaces/$NS/pods" | jq -r '.metadata.resourceVersion')
echo "== listed pods at resourceVersion $rv; watching from there for 15 seconds"

# -N turns off curl's buffering so each event prints as it arrives.
curl -sSN "$API/api/v1/namespaces/$NS/pods?watch=true&resourceVersion=$rv&timeoutSeconds=15" > "$events" &
watcher=$!
sleep 1

curl -sS -o /dev/null -X POST "$API/api/v1/namespaces/$NS/pods" \
  -H 'Content-Type: application/json' -d @"$here/../step2/pod.json"
curl -sS -o /dev/null -X PATCH "$API/api/v1/namespaces/$NS/pods/hello" \
  -H 'Content-Type: application/merge-patch+json' -d '{"metadata":{"labels":{"seen":"yes"}}}'
curl -sS -o /dev/null -X DELETE "$API/api/v1/namespaces/$NS/pods/hello?gracePeriodSeconds=0"

wait "$watcher" || true
echo "== events, one JSON object per line"
jq -c '{type, name: .object.metadata.name, resourceVersion: .object.metadata.resourceVersion, labels: .object.metadata.labels}' "$events"
rm -f "$events"
