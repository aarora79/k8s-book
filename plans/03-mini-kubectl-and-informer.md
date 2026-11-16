# Plan: chapter 3, a mini kubectl and an informer

Folder: `chapters/03-mini-kubectl-and-informer/`. Standard library only: `net/http`, `crypto/tls`, `encoding/json`, `os`, `flag`. YAML input for `kk apply` goes straight to the server as `application/apply-patch+yaml`, so no YAML library is needed.

## Goal

The reader turns chapter 2's curl calls into a Go client, `kk`, and then into an informer: the list, watch, cache and relist loop that every later controller depends on. The chapter ends by mapping each piece to client-go, which chapter 4 adopts.

## Steps

1. **step1: `kk get`.** Read `$KUBECONFIG` (default `~/.kube/config`). Support only the current context with `certificate-authority-data` plus either a bearer token or `client-certificate-data`/`client-key-data` (kind uses client certificates; check). Parse the kubeconfig with a tiny hand-written parser or by shelling out to `kubectl config view --raw --minify -o json` and decoding JSON; prefer the `kubectl` route and say why in the README (YAML parsing is not this chapter's subject). `kk get pods -n NS` prints NAME, PHASE, NODE, AGE.
2. **step2: resource mapping.** `kk get <resource>` for any namespaced resource by calling discovery (`/api/v1`, `/apis`) once and caching the resource-to-path map in memory. This replaces the hard-coded pods path.
3. **step3: `kk watch`.** List, take `metadata.resourceVersion`, open `?watch=true&resourceVersion=N`, decode the stream with `json.Decoder` one event at a time, print `TYPE name rv`.
4. **step4: `kk apply -f file.yaml`.** `PATCH` with `Content-Type: application/apply-patch+yaml` and `?fieldManager=kk`. Use `force=true` only behind a flag. Show `managedFields` before and after so the reader sees field ownership.
5. **step5: the informer package.** A package `informer` in this chapter with:
   - `type Informer struct` holding the path, a `map[string]json.RawMessage` cache keyed by `namespace/name`, a mutex, and handler funcs `OnAdd`, `OnUpdate`, `OnDelete`.
   - `Run(ctx)`: list, fill the cache, emit `OnAdd` for each, then watch from the list's resourceVersion. On a clean stream end (server timeout), rewatch from the last seen resourceVersion. On an `ERROR` event with code 410, relist, diff the new list against the cache, emit adds, updates and the deletes the reader would otherwise miss.
   - `Get(key)` and `List()` reading from the cache.
   - A demo `main` in `step5/` that prints handler calls for pods.
6. **step6: resilience.** Exponential backoff with jitter on connection errors; a `synced` channel that closes after the first list, so callers can wait for a warm cache.

## Tests (`test.sh`)

- `kk get pods -n kube-system` lists `etcd-lab-control-plane`.
- `kk get deployments -n kube-system` finds `coredns` (proves discovery works for a named group).
- `kk apply` creates a ConfigMap, a second apply with a changed value updates it, and `managedFields` lists manager `kk`.
- Informer: start the step5 demo in the background, create, update and delete a ConfigMap, and check the output shows add, update, delete in order.
- Relist: with the informer running, force a 410 by restarting the informer's watch from resourceVersion `1` (a test-only flag), and check it relists and keeps working.
- Missed deletes: stop the informer, delete a ConfigMap, restart it from its old resourceVersion forced too old, and check it emits the delete after the relist.
- Disconnect: `docker pause lab-control-plane` for 20 seconds while the informer runs; check it logs the backoff and resumes without a relist when the resourceVersion is still in the window.

## README points

- Why `kubectl` itself is a client of the same API, and `kubectl get --raw` as the escape hatch.
- Server-side apply: field managers and conflicts, and why `kubectl apply` moved to it.
- Design notes: client-go's Reflector, DeltaFIFO, Indexer and SharedInformer, each linked at the pinned tag under `staging/src/k8s.io/client-go/tools/cache/`; why informers are shared across controllers in one process; why the cache returns pointers you must not mutate (client-go's rule; check the wording in the source).
- Run it beside the real one: `kk watch pods` and `kubectl get pods -w -v=8` side by side.

## Check before writing

- How kind's kubeconfig authenticates (client certificate expected).
- client-go's current watch-list feature (streaming lists, `sendInitialEvents`) and whether it is on by default in 1.37; mention it in design notes if so.

## Done when

- Steps 1 to 6 build and run; `make test` passes on the lab and in CI.
- Chapter 4 can import or copy the informer for its version 2, or switch to client-go with the README pointing out what each client-go type replaces.
