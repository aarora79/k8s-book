# Style

These rules apply to every file in the repo. `make stylecheck` enforces the ones a program can check.

## Prose

- No em-dashes, and no double hyphens standing in for one. Use a comma, a colon, a full stop or parentheses.
- No emojis in README files or docs.
- Do not hard-wrap markdown. Put one paragraph, list item or sentence group on one line.
- Write in the active voice and name the actor: "the scheduler writes a Binding", not "a Binding is written".
- Short words and short sentences. Cut words that carry no weight.
- Spell out an acronym the first time a chapter uses it.
- Give exact versions, numbers and file names.

## Diagrams

- Draw every diagram as an SVG file in the chapter's `images/` folder and embed it with `![alt text](images/name.svg)`. No ASCII art diagrams in code blocks.
- Give the SVG a white background, a `<title>` and a `<desc>`, and write alt text that says what the diagram shows.

## Code

- Every listing in a README must exist in a step folder and run. Copy snippets from the step folders, never type them into the README by hand.
- Step 1 of each chapter runs end to end in about 100 lines.
- Chapters 1 to 3 use only the Go standard library. Later chapters may use client-go, after the reader has built its pieces by hand.
- Every step folder builds with `go build ./...` and `go vet ./...` from the repo root.
- Each chapter's `make test` must pass against a fresh `make lab` cluster.
- Use `uv` for any Python tooling, never pip.

## Versions

The book is pinned to:

| Tool | Version |
| --- | --- |
| Kubernetes (kind node image) | 1.34.0 |
| kind | 0.30.0 |
| Go | 1.24 |

Each chapter states the versions it was written for at the top. When the pins move, every chapter's tests must pass again before the change merges.
