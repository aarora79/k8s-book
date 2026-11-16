# Chapter 10: A tiny gateway

Status: planned. This file is the chapter's plan. The code and the full text come next, following the template in the top-level README.

## What you will build

A controller that watches Gateway API `HTTPRoute` objects and a reverse proxy in Go that routes requests by host and path to the right Service. This chapter replaces the Ingress chapter in the original plan: Kubernetes retired the ingress-nginx controller in March 2026, the Ingress API is frozen, and the project recommends Gateway API.

## What the real one does

Gateway API splits routing into roles: a GatewayClass (which implementation), a Gateway (a listener, owned by the platform team) and routes such as HTTPRoute (owned by application teams). Implementations such as Envoy Gateway or Istio watch these objects and configure their proxies. Yours does the same with Go's `httputil.ReverseProxy`.

## Scope

| Supported | Left out |
| --- | --- |
| HTTPRoute path prefix and host matching, weighted backends | TLS, header matching, filters |
| One Gateway, one listener | GRPCRoute, TCPRoute |
| Route status conditions | Cross-namespace ReferenceGrants |

## Build it (planned steps)

1. Install the Gateway API CRDs and create a Gateway and an HTTPRoute that nothing serves.
2. A reverse proxy with a hard-coded route table.
3. A controller that builds the route table from HTTPRoutes and swaps it in atomically.
4. Weighted backends for a canary split, and route status.

## Run it beside the real one

Install a real implementation in a second namespace and send the same requests through both.

## Break it

1. Point a route at a Service with no endpoints.
2. Create two routes that claim the same path.

## Improving and expanding

1. Easy: add request logging.
2. Medium: header matches.
3. Hard: TLS termination from a Secret.

## Further reading

- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Ingress NGINX retirement](https://kubernetes.io/blog/2025/11/11/ingress-Nginx-retirement/)
