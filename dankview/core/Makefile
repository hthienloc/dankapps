BINARY_NAME=dview
SOURCE_DIR=cmd/dview
BUILD_DIR=bin

GO=go
BUILD_TIME ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
COMMIT ?= $(shell git describe --always --dirty 2>/dev/null || echo unknown)
LDFLAGS = -X main.BuildTime=$(BUILD_TIME) -X main.Commit=$(COMMIT)

.PHONY: all build dev clean test fmt vet deps help

all: build

build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

dev:
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)

clean:
	@rm -rf $(BUILD_DIR)

test:
	CGO_ENABLED=0 $(GO) test ./...

fmt:
	$(GO) fmt ./...

vet:
	CGO_ENABLED=0 $(GO) vet ./...

deps:
	$(GO) mod tidy
	$(GO) mod download

help:
	@echo "Targets: build dev clean test fmt vet deps"
