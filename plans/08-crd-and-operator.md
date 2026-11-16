# Plan: chapter 8, a CRD and an operator

Folder: `chapters/08-crd-and-operator/`. Version 1 uses client-go's dynamic client; version 2 uses controller-runtime at the version pinned in `STYLE.md`.

## Goal

The reader teaches the API server a new type, `McpServer`, and writes the controller that gives it meaning. Chapter 11 deploys MCP Gateway Registry's servers through this resource, so its fields must fit real MCP servers.

## The resource

Group `toy.hmlk8s.dev`, version `v1alpha1`, kind `McpServer`, namespaced. Spec fields: `image` (string, required), `port` (int, default 8000), `path` (string, the URL path the gateway will route, default `/<name>`), `replicas` (int, default 1), `env` (list of name/value). Status: `conditions` (`Ready`, `Progressing`), `observedGeneration`, `url`. Printer columns: Ready, URL, Age. Before fixing the spec, read how MCP Gateway Registry describes a server registration (local checkout at `~/repos/mcp-gateway-registry`) and align field names where it makes sense.

## Steps

1. **step1: the CRD alone.** YAML with an OpenAPI v3 schema, defaults, the status subresource and printer columns. Create objects with `kubectl` and with chapter 3's `kk`; read them with curl. Show schema validation rejecting a bad object.
2. **step2: an operator with client-go.** Dynamic informer for `McpServer`; reconcile into a Deployment and a Service with owner references; use server-side apply with field manager `mcpserver-operator`.
3. **step3: status.** Compute `Ready` from the Deployment's available replicas; write conditions and `observedGeneration` through the status subresource.
4. **step4: a finalizer.** Add `toy.hmlk8s.dev/cleanup`; on deletion, run a cleanup action (log a deregistration, and in chapter 11 call the registry), then remove the finalizer.
5. **step5: controller-runtime.** Rewrite steps 2 to 4 with controller-runtime: typed Go structs for the CRD, `Reconcile`, `Owns(&appsv1.Deployment{})`. Generate the CRD from Go types with `controller-gen` (pin its version) and diff against the hand-written YAML. Compare line counts.

## Tests

- Invalid object (missing `image`) is rejected by the API server with a schema error.
- A valid `McpServer` produces a Deployment and Service; `Ready=True` once the pod is available; `url` set.
- Changing `replicas` updates the Deployment; `observedGeneration` follows `metadata.generation`.
- Deleting the `McpServer` runs the finalizer and garbage collects children.
- Both versions (step4 and step5) pass the same test script.

## README points

- How the API server serves a CRD: discovery, storage, schema validation, defaulting, the status subresource.
- What controller-runtime adds: the manager, shared caches, leader election, metrics; and what it hides.
- Design notes: why `observedGeneration` exists, why finalizers block deletion, why operators should use server-side apply.
- Break it: unpullable image (conditions must say why); remove the finalizer by hand while the operator is down.

## Check before writing

- controller-runtime and controller-gen versions matching client-go v0.37.
- CRD CEL validation rules (`x-kubernetes-validations`) status in 1.37, for the "improving" section.

## Done when

- Both operator versions pass the same tests on the lab and in CI.
