# Plan: chapter 11, capstone: MCP Gateway Registry

Folder: `chapters/11-capstone-mcp-gateway/`. Mostly manifests, scripts and prose; little new Go.

## Goal

Run MCP Gateway Registry on the lab cluster through the reader's own parts, then swap each toy part for the real one and confirm nothing breaks. The swap test is the chapter's "Run it beside the real one".

## Verified facts (2026-11-16)

- MCP Gateway Registry ships a Helm umbrella chart at `charts/mcp-gateway-registry-stack` in `agentic-community/mcp-gateway-registry`. Release 1.25.0 (June 2026) changed its subcharts and requires `helm dependency build` before install.
- The registry stores data in MongoDB (Community Edition or Atlas outside AWS; DocumentDB on AWS).
- The gateway is optional; the registry can run in registry-only mode behind another gateway.

## Check before writing

- The latest release tag and its install path for a local cluster. Read the chart's `values.yaml` in the local checkout (`~/repos/mcp-gateway-registry`) and find the smallest values set that runs on kind: MongoDB in-cluster, no cloud identity provider, one or two example MCP servers.
- Which component serves MCP traffic and which paths, so the chapter 10 gateway can route it. Path-based routing per MCP server is the project's key feature; the chapter should show it.
- Whether registry-only mode lets the chapter 10 toy gateway stand in for the project's own gateway, or whether the project's gateway stays and the toy gateway fronts it.

## Steps

1. **step1: stock install.** Install with Helm and stock Kubernetes parts. Run a smoke test: list servers through the registry API, call one tool through the gateway. Keep this script; it is the acceptance test for every later step.
2. **step2: MCP servers as `McpServer` objects.** Replace the example servers' Deployments with chapter 8 `McpServer` objects. Wire the chapter 8 finalizer to deregister the server through the registry API on delete.
3. **step3: admission.** Label the namespace for the chapter 9 policy, configure its registry allow-list for the project's images, and fix anything it rejects (most likely missing memory limits). Record each fix in the README.
4. **step4: routing.** Put the chapter 10 gateway in front. Each MCP server keeps its own path.
5. **step5: the swap test.** One at a time, replace: chapter 10 gateway with Envoy Gateway; chapter 9 webhook with the CEL policy; chapter 8 client-go operator with the controller-runtime version. Rerun the smoke test after each swap and record the result in a table in the README.
6. **step6 (optional): your scheduler and kubelet.** Run one MCP server's pods on `toy-node` through the chapter 5 scheduler and chapter 6 kubelet, if its image can run in the busybox-style runtime; otherwise explain why not (image pulls, networking) and point to the chapter 6 extensions that would close the gap.

## Tests

- The smoke test passes after every step and every swap.
- Deleting an `McpServer` removes it from the registry's server list.

## README points

- What MCP Gateway Registry does, in two paragraphs, with a link to the repo and the AWS Open Source blog post.
- A table: each toy part, the real part that replaced it in the swap test, and what the toy got wrong or left out.
- Link the archived course's two capstones as further reading.

## Done when

- The smoke test passes on the lab with every toy part in place, and after each swap; CI runs at least step 1 and step 4 (check the cluster fits in a GitHub runner's memory; if not, run the capstone tests on the Mac only and say so in the README).

## Sources

- [MCP Gateway Registry release 1.25.0 notes](https://newreleases.io/project/github/agentic-community/mcp-gateway-registry/release/1.25.0)
- [AWS Open Source blog: Governing AI Assets at Scale with MCP Gateway and Registry](https://aws.amazon.com/blogs/opensource/governing-ai-assets-at-scale-with-mcp-gateway-and-registry/)
