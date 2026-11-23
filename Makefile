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
	@command -v docker >/dev/null 2>&1 || { echo "docker is not installed. Install Docker Desktop, OrbStack or Colima (see chapters/00-map-and-lab/README.md)."; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "docker is not running. Start Docker Desktop, OrbStack or Colima, then run make lab again."; exit 1; }
	@if kind get clusters 2>/dev/null | grep -qx "$(CLUSTER)"; then echo "kind cluster '$(CLUSTER)' already exists"; else kind create cluster --config lab/kind-config.yaml; fi
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
	kind delete cluster --name "$(CLUSTER)"
