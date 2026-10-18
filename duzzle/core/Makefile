BINARY_NAME=duzzle
SOURCE_DIR=cmd/duzzle
BUILD_DIR=bin

GO=go

.PHONY: all build dev clean test fmt vet deps help

all: build

build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

dev:
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)

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
