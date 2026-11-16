#!/usr/bin/env bash
# Step 6: no proxy. Talk to the API server over TLS with a service account
# token, the way every component in the cluster does.
set -euo pipefail
NS="${NS:-ch02}"
work=$(mktemp -d)

server=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
  | base64 -d > "$work/ca.crt"
echo "== API server at $server"

echo "== without credentials"
curl -sS --cacert "$work/ca.crt" "$server/api/v1/namespaces/$NS/pods" | jq '{code, reason, message}'

echo "== create a service account that may only read"
kubectl -n "$NS" create serviceaccount reader --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "$NS" create rolebinding reader-view --clusterrole=view --serviceaccount="$NS:reader" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
token=$(kubectl -n "$NS" create token reader --duration=10m)

echo "== list pods as the reader"
curl -sS --cacert "$work/ca.crt" -H "Authorization: Bearer $token" \
  "$server/api/v1/namespaces/$NS/pods" | jq '{kind, items: (.items | length)}'

echo "== try to create a pod as the reader"
curl -sS --cacert "$work/ca.crt" -H "Authorization: Bearer $token" \
  -X POST "$server/api/v1/namespaces/$NS/pods" -H 'Content-Type: application/json' \
  -d @"$(dirname "$0")/../step2/pod.json" | jq '{code, reason, message}'

rm -rf "$work"
