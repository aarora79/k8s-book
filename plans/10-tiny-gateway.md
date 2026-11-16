# Plan: chapter 10, a tiny gateway

Folder: `chapters/10-tiny-gateway/`. client-go dynamic client (or `sigs.k8s.io/gateway-api` typed clients, pinned) plus `net/http/httputil`.

## Goal

A Gateway API implementation in miniature: a controller that watches `HTTPRoute` objects for its own `GatewayClass` and a Go reverse proxy that routes by host and path. This replaces the Ingress chapter in the original plan.

## Verified facts (2026-11-16)

- Kubernetes SIG Network retired ingress-nginx; the repository was archived on 2026-03-24, and the project recommends Gateway API.
- Gateway API v1.4.0 was released on 2025-10-06; v1.5 added a `safe-upgrades` ValidatingAdmissionPolicy to its standard install; a v1.6.x line exists.

## Check before writing

- The newest Gateway API standard-channel release that supports Kubernetes 1.37, and its install command (`kubectl apply --server-side -f .../standard-install.yaml`). Pin it in `STYLE.md`.

## Design decisions

- `GatewayClass` named `toy` with `controllerName: toy.hmlk8s.dev/gateway-controller`. One `Gateway` with one HTTP listener on port 80.
- The proxy runs as a Deployment exposed on the Mac through a kind `extraPortMappings` entry or `kubectl port-forward`. Prefer port-forward to avoid changing the lab config; check whether a NodePort plus kind port mapping makes the demo clearer.
- The controller and proxy can be one process: the controller builds an immutable route table and swaps it in with `atomic.Pointer`.

## Steps

1. **step1: CRDs and objects only.** Install Gateway API, create the GatewayClass, Gateway and an HTTPRoute; show that nothing serves them and the status stays empty.
2. **step2: a proxy with a fixed table.** `httputil.ReverseProxy` routing `/a` and `/b` to two Services.
3. **step3: the controller.** Watch HTTPRoutes attached to the `toy` Gateway; build the table from `rules[].matches` (path prefix, exact path, hostnames) and `backendRefs` (Service name and port); swap it in. Longest prefix wins; document the tie rules the spec defines and implement them.
4. **step4: weights and status.** Weighted `backendRefs` for a canary split; write `Accepted` and `ResolvedRefs` conditions on each route's `status.parents`; set the GatewayClass `Accepted` condition.

## Tests

- Requests to `/a` and `/b` reach the right backends.
- Adding a route takes effect within 2 seconds without a restart.
- A 90/10 weighted route splits 500 requests within 80 to 97 percent and 3 to 20 percent.
- A route to a missing Service gets `ResolvedRefs=False` and the proxy answers 500 (check what the spec requires).
- Cleanup removes CRD objects (leave the CRDs installed only if later chapters need them).

## README points

- Gateway API's role split: GatewayClass for infrastructure providers, Gateway for platform teams, routes for app teams; why Ingress could not express that.
- Run it beside the real one: install Envoy Gateway (pinned version) in its own namespace and send the same requests through both.
- Break it: two routes claiming the same path; a route pointing at a Service with no endpoints.

## Done when

- Tests pass on the lab and in CI; chapter 11 can route MCP Gateway Registry through this gateway.

## Sources

- [Kubernetes blog: Ingress NGINX retirement](https://kubernetes.io/blog/2025/11/11/ingress-Nginx-retirement/)
- [Kubernetes blog: Gateway API 1.4](https://www.kubernetes.io/blog/2025/11/06/gateway-api-v1-4/)
- [Gateway API getting started](https://gateway-api.sigs.k8s.io/guides)
