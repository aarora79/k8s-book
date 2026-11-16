#!/usr/bin/env bash
# Runs every step of chapter 2 against the current kubectl context and checks
# the results. Expects `kubectl proxy --port=8001` to be running (make test
# starts one).
set -uo pipefail
cd "$(dirname "$0")"
. ./env.sh
failures=0

check() { # check <name> <pattern> <actual output>
  if grep -qE -- "$2" <<<"$3"; then echo "  ok    $1"; else
    echo "  FAIL  $1: wanted /$2/, got:"; sed 's/^/        /' <<<"$3"; failures=$((failures + 1)); fi
}

out=$(bash step1/explore.sh 2>&1)
check "step1: server is v1.34" '"gitVersion": "v1\.34\.' "$out"
check "step1: pods support watch" '"watch"' "$out"

out=$(bash step2/crud.sh 2>&1)
check "step2: pod created" '"phase": "Pending"' "$out"
check "step2: merge patch added a label" '"chapter": "two"' "$out"
check "step2: delete sets deletionTimestamp" '"deletionTimestamp": "20' "$out"
sleep 2

out=$(bash step3/watch.sh 2>&1)
check "step3: ADDED event" '"type":"ADDED"' "$out"
check "step3: MODIFIED event carries the new label" '"type":"MODIFIED".*"seen":"yes"' "$out"
check "step3: DELETED event" '"type":"DELETED"' "$out"
sleep 2

out=$(bash step4/conflict.sh 2>&1)
check "step4: stale write gets 409" '"code": 409' "$out"
check "step4: retry wins" '"owner": "b"' "$out"
sleep 2

out=$(bash step5/gone.sh 2>&1)
check "step5: resourceVersion 1 is gone" '"code":410' "$out"
check "step5: fresh watch succeeds" 'HTTP 200' "$out"

out=$(bash step6/direct.sh 2>&1)
check "step6: no credentials is refused" '"code": 40[13]' "$out"
check "step6: reader can list" '"kind": "PodList"' "$out"
check "step6: reader cannot create" '"code": 403' "$out"

kubectl delete namespace "$NS" --wait=false >/dev/null 2>&1

echo
if [ "$failures" -eq 0 ]; then echo "chapter 2: all checks passed"; else echo "chapter 2: $failures check(s) failed"; exit 1; fi
