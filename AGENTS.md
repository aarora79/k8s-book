# AGENTS.md

Instructions for AI coding agents working in this repo. Read this file, `STYLE.md`, `README.md` and `plans/README.md` before you change anything.

## What this repo is

A book that teaches Kubernetes by rebuilding its parts in Go, modeled on Herbert Schildt's *Born to Code in C* (Osborne/McGraw-Hill, 1989). Each chapter builds one small, working piece of Kubernetes, runs it on a local kind cluster beside the real component, then explains the real design from the Kubernetes source.

The reader has used Kubernetes a little and can read Go. Write for that reader.

## Layout

| Path | What it holds |
| --- | --- |
| `README.md` | Book overview, chapter table with `Written` or `Planned` status, requirements |
| `STYLE.md` | Prose, code and version rules. The version pins live here. |
| `CLAUDE.md` | Short rules for Claude Code. Same rules as this file. |
| `chapters/NN-name/` | One folder per chapter. `README.md` is the chapter text. |
| `chapters/NN-name/stepN/` | Complete, runnable code after step N. Each step adds one idea. |
| `chapters/NN-name/test.sh` | Named checks that print `ok` or `FAIL` and exit non-zero on failure |
| `chapters/NN-name/ERRATA.md` | Fixes readers report |
| `plans/` | Work orders for unfinished chapters. Start at `plans/README.md`. |
| `lab/kind-config.yaml` | The kind cluster: 1 control plane, 2 workers, iptables kube-proxy, pinned node image digest |
| `lab/check.sh` | Checks tools, versions and cluster health |
| `tools/stylecheck/` | Go program that enforces the prose rules a program can check |
| `_config.yml`, `Gemfile` | Jekyll 4 settings for the GitHub Pages site |
| `.github/workflows/pages.yml` | Builds the site and publishes it on every push to `main` |
| `LICENSE` | Apache License 2.0 |
| `go.mod` | One Go module for the whole repo, module path `github.com/aarora79/help-me-learn-k8s` |

## Current state (2026-11-16)

- Chapters 0, 1 and 2 are written. Chapters 3 to 11 have a plan-style `README.md` only.
- Chapters 0 to 2 have never run on a kind cluster. `plans/00-02-verify-and-repin.md` fixes that and moves the pins from Kubernetes 1.34 to 1.37. Do that plan first; every later chapter depends on the lab.
- These files are referenced by the docs but are missing from the repo. Recreate them before you rely on them:
  - The top-level `Makefile` with targets `lab`, `check`, `test`, `stylecheck`, `clean` and a `CHAPTERS` list.
  - `chapters/01-container-by-hand/Makefile` (`install`, `rootfs`, `shell`, `test`, `test-local`) and `chapters/02-api-server-with-curl/Makefile` (`test`, which starts `kubectl proxy --port=8001`).
  - `.github/workflows/ci.yml` with `static` and `chapters` jobs.
  - `archive/`, the earlier 13-phase course. The README and chapter 11 link to it. Do not invent its content; ask the maintainer for it.

## Commands

These work today:

```bash
go build ./...                # every step folder must build
go vet ./...                  # and pass vet
go run ./tools/stylecheck .   # prose rules
bash lab/check.sh             # tools and cluster health
kind create cluster --config lab/kind-config.yaml
kind delete cluster --name lab
```

Once the top-level `Makefile` exists, use it:

```bash
make lab         # create the kind cluster
make check       # verify tools and cluster
make test        # build, vet, stylecheck, then every written chapter's tests
make stylecheck  # prose rules only
make clean       # delete the cluster
```

## Prose rules

`go run ./tools/stylecheck .` checks most of these. Run it before every commit.

- No em-dashes. No double hyphens standing in for a dash. Use a comma, a colon, a full stop or parentheses.
- No emojis anywhere.
- Do not hard-wrap markdown. One paragraph, list item or sentence group per line.
- Active voice, and name the actor: "the scheduler writes a Binding", not "a Binding is written".
- Short words and short sentences.
- Spell out an acronym the first time a chapter uses it.
- Give exact versions, numbers and file names.

## Diagrams

- Draw every diagram as an SVG file in the chapter's `images/` folder (see `chapters/00-map-and-lab/images/map.svg`) and embed it with `![alt text](images/name.svg)`. Never draw ASCII box diagrams in code blocks; stylecheck rejects them.
- Give the SVG a white background so it reads in dark mode, a `<title>` and a `<desc>`, and alt text that says what the diagram shows.

## Code rules

- Go only for the builds. Chapters 1 to 3 use the Go standard library only. Later chapters may use client-go and controller-runtime, after the reader has built those pieces by hand.
- Step 1 of each chapter runs end to end in about 100 lines. Each later step adds one idea, so `diff step2 step3` shows exactly that idea.
- Every step folder builds with `go build ./...` and passes `go vet ./...` from the repo root.
- Every code listing in a chapter README is copied from a step folder. Never type a listing into the README by hand.
- Every sample output in a chapter README comes from a real run on the lab cluster. Never write output from memory.
- Each chapter's tests pass against a fresh lab cluster and clean up after themselves: namespaces, CRDs, webhooks, iptables chains and background processes.
- Python tooling, if any, uses `uv`, never pip.

## Facts and versions

- Never state a Kubernetes version, flag, field or default from memory in chapter text. Check it against kubernetes.io or the Kubernetes source at the pinned tag, and link the source.
- In a plan, "verified" facts were checked on the date given. "Check" facts must be confirmed before they go into a chapter.
- The pins live in `STYLE.md`, `lab/kind-config.yaml`, `lab/check.sh`, `go.mod`, the top-level README and the `Written for` line at the top of each chapter. When a pin moves, change all of them together and rerun every chapter's tests.

## Chapter README sections

Every chapter uses this section order. Chapters 1 and 2 are the model for layout, tone and depth.

1. What you will build
2. What the real one does
3. Scope
4. Set up
5. Build it
6. Run it beside the real one
7. Break it
8. Design notes
9. Improving and expanding
10. Further reading

## Working on a chapter

1. Read the chapter's plan in `plans/` and its current `README.md`.
2. Write the code in `stepN/` folders, smallest working version first.
3. Write `test.sh` in the style of chapters 1 and 2, and a chapter `Makefile` with at least `test`.
4. Run every command in the README on the lab cluster, including "Run it beside the real one" and "Break it", and paste the real output.
5. Add the chapter to `CHAPTERS` in the top-level `Makefile` once its tests pass.
6. Change the chapter's row in the top-level README from `Planned` to `Written` when it merges.

A chapter is done when `make lab && make check && make test` passes from a fresh clone on an Apple Silicon Mac and in CI, the README reads top to bottom with every link working, and `make stylecheck` passes.

## The website

The book is published at https://aarora79.github.io/k8s-book/ by `.github/workflows/pages.yml`. Jekyll 4 turns every `README.md` into that folder's page and rewrites links between `.md` files, so link chapters with plain relative paths such as `../02-api-server-with-curl/README.md`. Liquid is off for every page (`render_with_liquid: false` in `_config.yml`), so `{{ }}` in Go templates and jsonpath shows as written. `AGENTS.md`, `CLAUDE.md`, `plans/` and `tools/` are left out of the site.

- Every page uses `_layouts/book.html`. It shows one title per page, a page number ("Page 3 of 13") and links to the previous and next page.
- The reading order is the `book_pages` list in `_config.yml`. Add a new page there if it belongs in the book.
- `assets/js/copy-code.js` adds a copy button to the top right of every code block. `assets/main.scss` holds the site's extra styles.

To preview the site locally with Docker:

```bash
docker run --rm -p 127.0.0.1:4000:4000 -v "$PWD":/src -w /src ruby:3.3 \
  bash -c 'bundle install && bundle exec jekyll serve --host 0.0.0.0'
```

## License

Apache License 2.0. See `LICENSE`.

## Git

- One branch and one pull request per chapter, named `chapter-NN-short-name`.
- No attribution lines in commits or pull requests: no `Co-Authored-By`, no `Claude-Session`, no "Generated with" footer.
- Do not edit `archive/`.
