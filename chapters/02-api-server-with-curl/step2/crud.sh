#!/usr/bin/env bash
# Step 2: create, read, list, patch and delete a pod with curl alone.
set -euo pipefail
. "$(dirname "$0")/../env.sh"
here=$(dirname "$0")

echo "== create namespace $NS"
curl -sS -X POST "$API/api/v1/namespaces" \
  -H 'Content-Type: application/json' \
  -d "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"name\":\"$NS\"}}" \
  | jq -r '.metadata.name // .message'

echo "== create pod hello"
curl -sS -X POST "$API/api/v1/namespaces/$NS/pods" \
  -H 'Content-Type: application/json' \
  -d @"$here/pod.json" \
  | jq '{name: .metadata.name, uid: .metadata.uid, resourceVersion: .metadata.resourceVersion, phase: .status.phase}'

echo "== read it back"
curl -sS "$API/api/v1/namespaces/$NS/pods/hello" | jq '{name: .metadata.name, resourceVersion: .metadata.resourceVersion, nodeName: .spec.nodeName}'

echo "== list pods with label app=hello"
curl -sS "$API/api/v1/namespaces/$NS/pods?labelSelector=app%3Dhello" | jq -r '.items[].metadata.name'

echo "== add a label with a merge patch"
curl -sS -X PATCH "$API/api/v1/namespaces/$NS/pods/hello" \
  -H 'Content-Type: application/merge-patch+json' \
  -d '{"metadata":{"labels":{"chapter":"two"}}}' \
  | jq '{labels: .metadata.labels, resourceVersion: .metadata.resourceVersion}'

echo "== delete it"
curl -sS -X DELETE "$API/api/v1/namespaces/$NS/pods/hello?gracePeriodSeconds=0" \
  | jq '{name: .metadata.name, deletionTimestamp: .metadata.deletionTimestamp}'
