# Chapter 3: A mini kubectl and an informer

Status: planned. This file is the chapter's plan. The code and the full text come next, following the template in the top-level README.

## What you will build

A command-line tool, `kk`, with three commands (`get`, `apply`, `watch`) written with nothing but Go's standard library. Then an informer: a small library that lists a resource once, watches from that list's resourceVersion, keeps a local cache, and lists again when the watch returns `410 Gone`. Chapters 4 to 10 build on the ideas in this library, and chapter 4 switches to client-go once you know what it does inside.

## What the real one does

kubectl turns your commands into the requests from chapter 2. Inside every controller, client-go's [Reflector](https://github.com/kubernetes/kubernetes/blob/v1.34.0/staging/src/k8s.io/client-go/tools/cache/reflector.go) runs the list-then-watch loop and its [shared informer](https://github.com/kubernetes/kubernetes/blob/v1.34.0/staging/src/k8s.io/client-go/tools/cache/shared_informer.go) fans events out to handlers and keeps an indexed cache, so controllers read from memory instead of asking the API server again.

## Scope

| Supported | Left out |
| --- | --- |
| `kk get`, `kk watch` for any namespaced resource | Cluster-scoped resources, output formats other than a table |
| `kk apply` as a server-side apply `PATCH` | Client-side apply and its last-applied annotation |
| Bearer token and CA from the kubeconfig's current context | Exec plugins, client certificates |
| Informer: list, watch, cache, relist on 410, event handlers | Indexers, resync periods, shared informer factories |

## Build it (planned steps)

1. Read the kubeconfig and make an authenticated `GET`: `kk get pods` prints a table.
2. `kk watch pods`: list, then decode the watch stream line by line.
3. `kk apply -f pod.yaml`: send `application/apply-patch+yaml` with a field manager name, and watch `managedFields` change.
4. The informer: a goroutine that lists, watches, updates a map keyed by namespace/name, and calls `OnAdd`, `OnUpdate`, `OnDelete`.
5. Resume and recover: reconnect from the last resourceVersion seen; on `410 Gone`, list again and diff the cache to emit the deletes you missed.

## Run it beside the real one

Run `kk watch pods` and `kubectl get pods -w -v=8` side by side, and compare request paths and timing.

## Break it

1. Stop the API server container for 30 seconds with `docker pause lab-control-plane` and watch your informer reconnect.
2. Delete pods while the informer is disconnected and check that the relist emits the deletes.

## Improving and expanding

1. Easy: add `-o json` and `-l` (label selector) to `kk get`.
2. Medium: add an index by label so handlers can ask "all pods with app=x" without scanning.
3. Hard: add watch bookmarks and measure how often you avoid a relist.

## Further reading

- [Kubernetes API concepts](https://kubernetes.io/docs/reference/using-api/api-concepts/)
- [Server-side apply](https://kubernetes.io/docs/reference/using-api/server-side-apply/)
