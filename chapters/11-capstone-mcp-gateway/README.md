# Chapter 11: Capstone: MCP Gateway Registry

Status: planned. This file is the chapter's plan. The code and the full text come next, following the template in the top-level README.

## What you will build

MCP Gateway Registry running on the lab cluster through your parts: its MCP servers declared as `McpServer` objects (chapter 8), every pod checked by your admission policy (chapter 9), traffic routed by your gateway (chapter 10). Then the swap test: replace each toy part with the real component, one at a time, and confirm the application keeps working.

## What the real one does

[MCP Gateway Registry](https://github.com/agentic-community/mcp-gateway-registry) is a gateway and registry for Model Context Protocol servers. The [archived course](../../archive/README.md) deployed it with stock Kubernetes parts; this chapter deploys it with yours.

## Scope

| Supported | Left out |
| --- | --- |
| The registry, the gateway and two MCP servers | Production identity provider setup |
| Your operator, admission policy and gateway | Your scheduler and kubelet for every pod (they run the test pods only) |

## Build it (planned steps)

1. Deploy the registry with plain manifests and confirm it works.
2. Move its MCP servers to `McpServer` objects.
3. Turn on your admission policy and fix what it rejects.
4. Route through your gateway.
5. The swap test: real gateway, then the CEL policy, then a Kubebuilder operator, rerunning the same checks each time.

## Run it beside the real one

The swap test is this chapter's comparison.

## Break it

1. Kill your operator mid-deploy.
2. Push a pod that violates the policy through a Deployment and find where the error surfaces.

## Improving and expanding

1. Medium: add Prometheus metrics to your operator and gateway; the archived Gemma capstone shows the dashboards.
2. Hard: run one MCP server's pods on `toy-node` through your scheduler and kubelet.

## Further reading

- [MCP Gateway Registry](https://github.com/agentic-community/mcp-gateway-registry)
