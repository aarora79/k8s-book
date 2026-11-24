# Named commands for the book. Chapter 0 explains make.
CLUSTER := lab

# Chapters whose tests pass on the lab. Add a chapter here once its own
# Makefile has a test target and that target passes.
CHAPTERS :=

# Chapter 1 uses Linux system calls, so build and vet for Linux on every host.
GO_LINUX := GOOS=linux

# These names are commands, not files. Without this line, make sees the lab/
# folder and reports "Nothing to be done for lab".
.PHONY: lab check test build vet stylecheck clean

lab:
	@. ./lab/runtime.sh; require_runtime; echo "Using $$RUNTIME"; \
	if cluster_exists "$(CLUSTER)"; then echo "kind cluster '$(CLUSTER)' already exists"; else kind create cluster --config lab/kind-config.yaml; fi
	@kubectl --context "kind-$(CLUSTER)" wait --for=condition=Ready nodes --all --timeout=180s

check:
	@bash lab/check.sh

build:
	$(GO_LINUX) go build ./...

vet:
	$(GO_LINUX) go vet ./...

stylecheck:
	@go run ./tools/stylecheck .

test: build vet stylecheck
	@for chapter in $(CHAPTERS); do $(MAKE) -C "chapters/$$chapter" test || exit 1; done

clean:
	@. ./lab/runtime.sh; require_runtime; kind delete cluster --name "$(CLUSTER)"
