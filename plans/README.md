# Plans for Claude Code

These files are work orders. Each one describes a chapter to finish: what to build, which facts are already verified, what to test and when the chapter counts as done. Work through them in order, one chapter per session, and open a pull request per chapter.

## Order

1. [00-02-verify-and-repin.md](00-02-verify-and-repin.md): run chapters 0 to 2 on a real kind cluster, move the version pins to Kubernetes 1.37, fix what breaks. Do this first; every later chapter depends on the lab.
2. [03-mini-kubectl-and-informer.md](03-mini-kubectl-and-informer.md)
3. [04-replicaset-controller.md](04-replicaset-controller.md)
4. [05-toy-scheduler.md](05-toy-scheduler.md)
5. [06-toy-kubelet.md](06-toy-kubelet.md)
6. [07-service-by-hand.md](07-service-by-hand.md)
7. [08-crd-and-operator.md](08-crd-and-operator.md)
8. [09-admission-webhook.md](09-admission-webhook.md)
9. [10-tiny-gateway.md](10-tiny-gateway.md)
10. [11-capstone-mcp-gateway.md](11-capstone-mcp-gateway.md)

## Rules for every chapter

- Read `CLAUDE.md`, `STYLE.md`, the top-level `README.md` and the finished chapters 1 and 2 before starting. Chapters 1 and 2 are the model for layout, tone and depth.
- The chapter's existing `README.md` is its plan in reader-facing form. Replace it with the full chapter, keeping the section order from the top-level README: what you will build, what the real one does, scope, set up, build it, run it beside the real one, break it, design notes, improving and expanding, further reading.
- Code lives in `stepN/` folders. Step 1 runs end to end in about 100 lines. Each later step adds one idea. Every step builds with `go build ./...` and passes `go vet ./...` from the repo root.
- Every code listing in the README is copied from a step folder. Every sample output in the README comes from a real run on the lab cluster, not from memory.
- Each chapter has a `Makefile` with at least `test`, and a `test.sh` in the style of chapters 1 and 2: named checks that print `ok` or `FAIL` and exit non-zero on any failure. Add the chapter to `CHAPTERS` in the top-level `Makefile` when its tests pass.
- Each chapter cleans up after its tests: its namespace, CRDs, webhooks, iptables chains and background processes.
- Bridge every new term: the first time the chapter introduces a term, add an `**Everyday picture.**` quote block that maps a non-technical example to the technical meaning (see `STYLE.md` and chapters 0 to 2), and add the term to `GLOSSARY.md`.
- Run `make stylecheck` before every commit.
- Facts marked "verified" in a plan were checked on 2026-11-16 with sources. Facts marked "check" must be confirmed before they go into the chapter text, from kubernetes.io, the Kubernetes source at the pinned tag, or the project's own docs.
- Update the chapter's row in the top-level README from `Planned` to `Written` when it merges.

## Git

- One branch and one pull request per chapter, named `chapter-NN-short-name`.
- No attribution lines: no `Co-Authored-By`, no `Claude-Session`, no "Generated with" footer, in commits or pull request descriptions.

## Done means

- `make lab && make check && make test` passes from a fresh clone on an Apple Silicon Mac and in CI.
- The chapter README reads top to bottom without gaps, every link resolves, and `make stylecheck` passes.
- You performed the chapter's "Run it beside the real one" and "Break it" sections, and the README reports what happened.
