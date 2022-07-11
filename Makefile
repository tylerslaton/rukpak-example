###########################
# Configuration Variables #
###########################
ORG ?= quay.io/tyslaton
export IMAGE_TAG ?= latest
export IMAGE_REPO ?= $(ORG)/sample-api
export BUNDLE_IMAGE_REPO ?= $(ORG)/sample-api-bundle
IMAGE ?= $(IMAGE_REPO):$(IMAGE_TAG)
BUNDLE_IMAGE ?= $(BUNDLE_IMAGE_REPO):$(IMAGE_TAG)

CONTAINER_RUNTIME ?= docker
KIND_CLUSTER_NAME ?= sample-api-cluster

###############
# Help Target #
###############
.PHONY: help
help: ## Show this help screen
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

###################
# Code management #
###################
.PHONY: tidy fmt clean verify

##@ code management:

tidy: ## Update dependencies
	$(Q)go mod tidy

fmt: ## Format Go code
	$(Q)go fmt ./...

verify: tidy fmt ## Verify the current code
	git diff --exit-code

clean: ## Remove binaries and test artifacts
	@rm -rf bin

#############
# Build/Run #
#############
.PHONY: build build-container run

##@ build:

build: clean ## Build the binary for the sample-api
	CGO_ENABLED=0 go build -o sample-api

build-container: build ## Build the container image locally
	$(CONTAINER_RUNTIME) build -f app.Dockerfile -t $(IMAGE) .

run: ## Start the sample-api directly
	CGO_ENABLED=0 go run main.go

run-container: build-container ## Start the sample-api after building its container
	$(CONTAINER_RUNTIME) run -p 8080:8080 $(IMAGE)

build-bundle:
	$(CONTAINER_RUNTIME) build -f bundle.Dockerfile -t $(BUNDLE_IMAGE) .

kind-load: build-container ## Load the current code onto the kind cluster as an image
	kind load docker-image $(IMAGE) --name $(KIND_CLUSTER_NAME)

kind-cluster:
	kind delete cluster --name $(KIND_CLUSTER_NAME)
	kind create cluster --name $(KIND_CLUSTER_NAME)
	kind export kubeconfig --name $(KIND_CLUSTER_NAME)

install:
	kubectl apply -f manifests/bundle

local: kind-cluster kind-load install

########
# Test #
########
UNIT_TEST_DIRS=$(shell go list ./... | grep -v /test/)
test-unit: ## Run the unit tests
	go test -count=1 -short $(UNIT_TEST_DIRS)
