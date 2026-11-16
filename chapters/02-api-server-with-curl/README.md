# Chapter 2: Talk to the API server with curl

Written for Kubernetes 1.34.0, kind 0.30.0.

## What you will build

Nothing but shell scripts: six of them, each a handful of `curl` calls. By the end you will have created, read, patched, watched and deleted Kubernetes objects without kubectl's help, and you will have seen the three responses every Kubernetes client must handle: `409 Conflict`, `410 Gone` and `403 Forbidden`.

```text
== writer B replaces it with owner=b, from its stale copy
{
  "code": 409,
  "reason": "Conflict",
  "message": "Operation cannot be fulfilled on configmaps \"settings\": the object has been modified; please apply your changes to the latest version and try again"
}
```

Every program you write in later chapters talks to the API server in exactly these requests. Chapter 3 wraps them in Go.

## What the real one does

> **Everyday picture.** At a bank you never walk into the vault. You hand a form through the teller's window, the teller checks it and does the work, and you get a receipt back. **In Kubernetes,** the API server is the window and kubectl is a customer. Each form is an HTTP request: a method that says what to do (`GET` to read, `POST` to create, `PATCH` or `PUT` to change, `DELETE` to remove) and a path that says which object.

kubectl is an HTTP client. `kubectl get pods -n ch02` sends `GET /api/v1/namespaces/ch02/pods` and prints a table from the JSON that comes back. Add `-v=8` to any kubectl command and it prints each request and response.

> **Everyday picture.** At an airport, the passport desk checks who you are, the gate checks that your ticket lets you board this flight, and security checks what you carry. You need all three. **In Kubernetes,** the API server runs the same three gates on every request: authentication (who are you), authorization (may you do this), and admission (is this object acceptable).

The API server checks who you are (authentication), whether you may do this (authorization), whether the object passes the admission plugins (chapter 9 adds your own), and then stores the object in etcd. It is the only component that talks to etcd.

> **Everyday picture.** A shared online document numbers each save. If you edit from a copy you opened an hour ago, the editor warns you that someone saved since. **In Kubernetes,** that save number is the `resourceVersion`.

Every object it stores gets a `resourceVersion`, a token that changes on every write. Clients use it two ways: to watch for changes after a known point, and to refuse a write based on a stale read.

## Scope

| Supported | Left out |
| --- | --- |
| Discovery: `/version`, `/api`, `/apis` | OpenAPI schemas |
| Create, get, list, merge patch, replace, delete | Server-side apply (chapter 3), JSON patch, strategic merge patch |
| Label selectors | Field selectors, pagination with `limit` and `continue` |
| Watch, resourceVersion, `410 Gone` | Watch bookmarks |
| `409 Conflict` on a stale replace | |
| Bearer tokens and the cluster CA, `401`/`403` | Client certificates, exec credential plugins |

## Set up

You need the lab from [chapter 0](../00-map-and-lab/README.md), plus `curl` and `jq` on your Mac.

Steps 1 to 5 go through `kubectl proxy`, which listens on your Mac, adds your kubeconfig's credentials to each request and forwards it to the API server. That keeps authentication out of the way until step 6. Start it in its own terminal and leave it running:

```bash
cd chapters/02-api-server-with-curl
make proxy
```

Every script reads `env.sh`, which sets `API=http://127.0.0.1:8001` and `NS=ch02`.

## Build it

### Step 1: look around

> **Everyday picture.** The board in an office lobby lists which company sits on which floor, so a visitor finds the right door without asking around. **In Kubernetes,** the discovery endpoints are that board: they list which resources live under which URL.

The API is a tree of plain URLs. `/api/v1` holds the core group (pods, services, namespaces, nodes). Everything newer lives under `/apis/<group>/<version>`, for example `/apis/apps/v1` for Deployments.

```bash
bash step1/explore.sh
```

```text
== version
{
  "gitVersion": "v1.34.0",
  "platform": "linux/arm64"
}
== the core group: /api/v1 and some of its resources
bindings
componentstatuses
configmaps
...
== one resource, described
{
  "name": "pods",
  "namespaced": true,
  "kind": "Pod",
  "verbs": ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
}
```

This is how kubectl knows that `kubectl get deploy` means `/apis/apps/v1/namespaces/<ns>/deployments`: it asks these discovery endpoints and caches the answer.

### Step 2: create, read, patch, delete

`step2/crud.sh` creates the `ch02` namespace, then a pod from `step2/pod.json`:

```bash
curl -sS -X POST "$API/api/v1/namespaces/$NS/pods" \
  -H 'Content-Type: application/json' \
  -d @"$here/pod.json" \
  | jq '{name: .metadata.name, uid: .metadata.uid, resourceVersion: .metadata.resourceVersion, phase: .status.phase}'
```

The response is the stored object. The API server filled in fields you did not send: a `uid`, a `creationTimestamp`, a `resourceVersion` and many defaults in `spec`.

Changes go through `PATCH`. The `Content-Type` header picks the patch format; a merge patch sends only the fields to change:

```bash
curl -sS -X PATCH "$API/api/v1/namespaces/$NS/pods/hello" \
  -H 'Content-Type: application/merge-patch+json' \
  -d '{"metadata":{"labels":{"chapter":"two"}}}'
```

```bash
bash step2/crud.sh
```

```text
== create pod hello
{
  "name": "hello",
  "uid": "ddaae4be-2111-4b64-9cb6-6d3bfa0fc390",
  "resourceVersion": "424",
  "phase": "Pending"
}
...
== add a label with a merge patch
{
  "labels": { "app": "hello", "chapter": "two" },
  "resourceVersion": "425"
}
== delete it
{
  "name": "hello",
  "deletionTimestamp": "2026-11-16T22:32:03Z"
}
```

The patch moved `resourceVersion` from 424 to 425. Every write does. The delete returns the object with a `deletionTimestamp`: deletion is itself a write that other components see before the object disappears.

### Step 3: watch

> **Everyday picture.** You can walk to the newsstand each morning, or you can subscribe once and have each new issue delivered. A subscription starts from a given issue number. **In Kubernetes,** a list is the walk to the newsstand, a watch is the subscription, and the `resourceVersion` is the issue number it starts from.

A watch is a `GET` with `watch=true` that the API server holds open, sending one JSON object per line each time something changes. Clients start a watch from the `resourceVersion` of a list, so they miss nothing between the list and the watch:

```bash
rv=$(curl -sS "$API/api/v1/namespaces/$NS/pods" | jq -r '.metadata.resourceVersion')
echo "== listed pods at resourceVersion $rv; watching from there for 15 seconds"

# -N turns off curl's buffering so each event prints as it arrives.
curl -sSN "$API/api/v1/namespaces/$NS/pods?watch=true&resourceVersion=$rv&timeoutSeconds=15" > "$events" &
```

The script then creates, labels and deletes the `hello` pod.

```bash
bash step3/watch.sh
```

```text
== events, one JSON object per line
{"type":"ADDED","name":"hello","resourceVersion":"428","labels":{"app":"hello"}}
{"type":"MODIFIED","name":"hello","resourceVersion":"429","labels":{"app":"hello"}}
{"type":"MODIFIED","name":"hello","resourceVersion":"430","labels":{"app":"hello","seen":"yes"}}
...
{"type":"DELETED","name":"hello","resourceVersion":"436","labels":{"app":"hello","seen":"yes"}}
```

Your script made three writes, but the watch shows more. On the lab cluster the scheduler binds the pod to a node and the kubelet reports its status, and each of those writes is an event too. You are watching the components from chapter 0's map at work. The delete also shows up twice: first as a `MODIFIED` that sets `deletionTimestamp`, then as `DELETED` once the object is gone.

### Step 4: two writers, one conflict

Two programs read an object, change it and write it back. Without a check, the second write would erase the first.

> **Everyday picture.** Two clerks copy the same paper form, each makes a change, and each hands theirs back. The office stamps every form with its revision number and rejects any copy whose stamp is out of date: "someone changed this, read the new one first". Nobody locks the form while they work. **In Kubernetes,** that is optimistic concurrency, and the stamp is the `resourceVersion`.

Kubernetes uses optimistic concurrency: a full replace (`PUT`) carries the `resourceVersion` the writer read, and the API server rejects it if the object has changed since.

The script uses a ConfigMap, because nothing else in the cluster writes to it:

```bash
echo "== writer B replaces it with owner=b, from its stale copy"
echo "$b" | jq '.data.owner = "b"' \
  | curl -sS -X PUT "$url" -H 'Content-Type: application/json' -d @- \
  | jq '{code, reason, message}'
```

```bash
bash step4/conflict.sh
```

```text
== writer A replaces it with owner=a
{ "owner": "a", "resourceVersion": "435" }
== writer B replaces it with owner=b, from its stale copy
{
  "code": 409,
  "reason": "Conflict",
  "message": "Operation cannot be fulfilled on configmaps \"settings\": the object has been modified; please apply your changes to the latest version and try again"
}
== writer B reads again and retries
{ "owner": "b", "resourceVersion": "436" }
```

The fix is always the same: read again, reapply your change, write again. Every controller in this book does that.

### Step 5: a watch that is too old

> **Everyday picture.** A newspaper keeps back issues for a few weeks. Ask for one from last year and the office tells you to start a fresh subscription. **In Kubernetes,** that answer is `410 Gone`.

The API server keeps a window of recent changes in memory for watches. Ask for a starting point older than that window and it refuses:

```bash
bash step5/gone.sh
```

```text
== watch pods from resourceVersion 1
{"type":"ERROR","code":410,"reason":"Expired","message":"too old resource version: 1 (3)"}
== the fix: list again for a fresh resourceVersion, then watch from that
fresh resourceVersion 438
watch from http://127.0.0.1:8001/api/v1/namespaces/ch02/pods?watch=true&resourceVersion=438&timeoutSeconds=2 -> HTTP 200
```

The HTTP status is 200; the refusal arrives as an `ERROR` event inside the stream. A client that loses its connection for a while sees exactly this when it tries to resume. It must list again and rebuild its copy of the objects from the fresh list. The informer you build in chapter 3 does this.

### Step 6: no proxy

Inside the cluster nobody uses `kubectl proxy`. Components connect to the API server over TLS and present a credential.

> **Everyday picture.** A visitor to an office gets a badge at the front desk. The badge names the visitor, expires at the end of the day and opens only some doors. **In Kubernetes,** a service account is an identity for a program, a token is its badge, and the role bound to the account decides which doors open. `step6/direct.sh` pulls the server address and its certificate authority from your kubeconfig, creates a service account bound to the read-only `view` role, and asks for a short-lived token:

```bash
token=$(kubectl -n "$NS" create token reader --duration=10m)

echo "== list pods as the reader"
curl -sS --cacert "$work/ca.crt" -H "Authorization: Bearer $token" \
  "$server/api/v1/namespaces/$NS/pods" | jq '{kind, items: (.items | length)}'
```

```bash
bash step6/direct.sh
```

```text
== without credentials
{
  "code": 403,
  "reason": "Forbidden",
  "message": "pods is forbidden: User \"system:anonymous\" cannot list resource \"pods\" in API group \"\" in the namespace \"ch02\""
}
== list pods as the reader
{ "kind": "PodList", "items": 0 }
== try to create a pod as the reader
{
  "code": 403,
  "reason": "Forbidden",
  "message": "pods is forbidden: User \"system:serviceaccount:ch02:reader\" cannot create resource \"pods\" in API group \"\" in the namespace \"ch02\""
}
```

Two different checks said no. Without a token, the API server treated you as the user `system:anonymous`, and no role lets that user list pods. (Clusters that turn anonymous access off answer `401 Unauthorized` instead.) With the token, authentication succeeded and authorization refused the create, because the `view` role only grants reads.

## Run it beside the real one

Run kubectl with full request logging and compare its traffic with your scripts:

```bash
kubectl -n ch02 get pods -v=8 2>&1 | grep -E 'GET|Response Status'
kubectl -n ch02 get pods -w -v=8 2>&1 | grep -E 'GET https'
```

The first command sends one `GET`. The second sends a list, then a watch whose `resourceVersion` matches the list's, the same pattern as step 3.

## Break it

1. Remove `-N` from the watch in step 3 and rerun it with `timeoutSeconds=60`, creating pods by hand in another terminal. Events still arrive, but in bursts, because curl buffers its output.
2. In step 4, change writer B's `PUT` to a merge `PATCH` with the same label. It succeeds. A patch without a `resourceVersion` skips the conflict check, so the last writer wins. Decide when that is acceptable.
3. Delete the `reader` rolebinding and run step 6 again. The list now fails with `403` too.

## Design notes

**Why the resourceVersion is opaque.** On the lab cluster it is etcd's revision number, which is why it only grows. The API server documents it as an opaque string, and clients may only compare it for equality or pass it back. That leaves the server free to change storage. Never do arithmetic on it.

**Why watches expire.** The API server serves watches from an in-memory cache of recent events rather than from etcd, so thousands of clients can watch without each holding an etcd connection. The cache cannot hold history forever, and etcd itself compacts old revisions. `410 Gone` is the server saying it can no longer replay the gap.

**Why optimistic concurrency.** A lock would make every controller wait for every other. Optimistic concurrency lets writers proceed and only makes the loser retry, which suits a system where conflicts are rare and every writer can recompute its change.

## Improving and expanding

1. Easy: page through a large list. Create 50 ConfigMaps in a loop, then list them with `limit=10` and follow `metadata.continue` until it is empty.
2. Easy: list pods with a field selector, `fieldSelector=status.phase%3DRunning`. Try it with a field the server does not support and read the error.
3. Medium: add `allowWatchBookmarks=true` to the step 3 watch, leave it open for a few minutes, and find the `BOOKMARK` events. Explain how they help a client avoid `410 Gone`.
4. Medium: change step 2 to use a JSON patch (`application/json-patch+json`) that removes a label.
5. Hard: write a pod's `status` subresource with a `PUT` to `/status` and find out which fields the API server ignores there and why.

## Further reading

- [Kubernetes API concepts](https://kubernetes.io/docs/reference/using-api/api-concepts/): watches, resourceVersion, patches, pagination
- [Ivan Velichko, How to call the Kubernetes API using a simple HTTP client](https://iximiuz.com/en/posts/kubernetes-api-call-simple-http-client/)
- [Controlling access to the Kubernetes API](https://kubernetes.io/docs/concepts/security/controlling-access/)
