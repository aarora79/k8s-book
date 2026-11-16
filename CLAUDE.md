# help-me-learn-k8s

A book that teaches Kubernetes by rebuilding its parts in Go, modeled on Herbert Schildt's *Born to Code in C*. Each chapter builds one working piece, runs it on a local kind cluster beside the real component, and explains the real design.

## Where things are

- `chapters/NN-name/`: one folder per chapter. `README.md` is the chapter text, `stepN/` holds runnable code after each step, `test.sh` and `Makefile` test it.
- `plans/`: work orders for unfinished chapters. Start at `plans/README.md`.
- `lab/`: kind cluster config and `check.sh`.
- `tools/stylecheck/`: enforces the prose rules below.
- `archive/`: the earlier 13-phase course. Do not edit it.

## Commands

```bash
make lab         # create the kind cluster
make check       # verify tools and cluster
make test        # build, vet, stylecheck, then every written chapter's tests
make stylecheck  # prose rules only
make clean       # delete the cluster
```

## Rules

- Prose: no em-dashes and no double hyphens used as dashes; no emojis; do not hard-wrap markdown; active voice; short words; exact versions and numbers.
- Code: Go only for the builds. Chapters 1 to 3 use the standard library only. Every README listing is copied from a step folder; every sample output comes from a real run.
- Python tooling, if any, uses `uv`, never pip.
- Git: one branch and pull request per chapter. Never add attribution lines (`Co-Authored-By`, `Claude-Session`, "Generated with") to commits or pull requests.
- Never state a version, flag or default from memory in chapter text. Check it against kubernetes.io or the Kubernetes source at the pinned tag.
