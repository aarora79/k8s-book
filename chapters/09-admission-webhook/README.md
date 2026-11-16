# Chapter 9: An admission webhook

Status: planned. This file is the chapter's plan. The code and the full text come next, following the template in the top-level README.

## What you will build

Two HTTPS endpoints the API server calls on every pod create: a validating webhook that rejects pods with no resource limits or from an unapproved registry, and a mutating webhook that adds default labels. Then the same validating rule written as a ValidatingAdmissionPolicy in CEL, which runs inside the API server with no webhook at all.

## What the real one does

After authentication and authorization, the API server runs admission. Mutating webhooks run first and may change the object; validating webhooks run after and may only say yes or no. The [validating dispatcher](https://github.com/kubernetes/kubernetes/blob/v1.34.0/staging/src/k8s.io/apiserver/pkg/admission/plugin/webhook/validating/dispatcher.go) calls matching webhooks in parallel and fails the request if any says no. Policy engines such as OPA Gatekeeper and Kyverno are admission webhooks.

## Scope

| Supported | Left out |
| --- | --- |
| A validating and a mutating webhook for pods | Webhooks for other resources |
| TLS with a certificate you generate | cert-manager |
| `failurePolicy`, namespace selectors | Reinvocation, side-effect declarations |
| The same rule as a ValidatingAdmissionPolicy | MutatingAdmissionPolicy |

## Build it (planned steps)

1. An HTTPS server that decodes an `AdmissionReview` and always allows; register it and watch the requests arrive.
2. Reject pods without limits, with a clear message.
3. A mutating webhook that returns a JSON patch adding labels.
4. Rewrite the validating rule in CEL and compare.

## Run it beside the real one

Apply the same bad pod with each mechanism in turn and compare the error messages and the time each adds.

## Break it

1. Stop the webhook with `failurePolicy: Fail` and try to create any pod in the namespace.
2. Return a malformed patch from the mutating webhook.

## Improving and expanding

1. Easy: exempt pods with a label.
2. Medium: run two replicas behind a Service.
3. Hard: add a dry-run mode that only warns.

## Further reading

- [Dynamic admission control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
- [Validating admission policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/)
