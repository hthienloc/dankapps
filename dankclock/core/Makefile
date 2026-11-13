BINARY_NAME=dclock
SOURCE_DIR=cmd/dclock
BUILD_DIR=bin

GO=go
QTBASE ?= 0
QTBASE_SRC ?= ../dux-qt-base
QTBASE_BUILD ?= build/dux-qt-base
QTBASE_LIB = $(QTBASE_BUILD)/src/libdux-qt-base.so.0
QTBASE_EMBED_DIR = internal/qtbaseembed/lib
SHELL_DIR=../quickshell
EMBED_DIR = internal/shellembed/dist

BASE_VERSION=$(or $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//'),0.1.0)
COMMIT_COUNT=$(shell git rev-list --count HEAD 2>/dev/null || echo "0")
COMMIT_HASH=$(shell git rev-parse --short=8 HEAD 2>/dev/null || echo "unknown")
VERSION?=$(BASE_VERSION)+git$(COMMIT_COUNT).$(COMMIT_HASH)
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
COMMIT?=$(COMMIT_HASH)

BUILD_LDFLAGS=-ldflags='-s -w -X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.Commit=$(COMMIT)'

ifeq ($(QTBASE),0)
QTBASE_DEP =
QTBASE_TAG =
else
QTBASE_DEP = qtbase
QTBASE_TAG = withqtbase
endif

.PHONY: all build dev qtbase clean-qtbase sync-shell clean test fmt vet deps help

all: build

qtbase:
	@test -f $(QTBASE_SRC)/CMakeLists.txt || { echo "dux-qt-base missing: run git submodule update --init"; exit 1; }
	@test -f $(QTBASE_BUILD)/build.ninja || cmake -S $(QTBASE_SRC) -B $(QTBASE_BUILD) -GNinja -DCMAKE_BUILD_TYPE=Release \
		-DDISTRIBUTOR=$(BINARY_NAME)-source -DGIT_REVISION=$$(git -C $(QTBASE_SRC) rev-parse --short=8 HEAD 2>/dev/null || echo unknown)
	cmake --build $(QTBASE_BUILD)
	@mkdir -p $(QTBASE_EMBED_DIR)
	@strip --strip-unneeded -o $(QTBASE_EMBED_DIR)/libdux-qt-base.so.0 $(QTBASE_LIB)
	@sha256sum $(QTBASE_EMBED_DIR)/libdux-qt-base.so.0 | cut -c1-16 > $(QTBASE_EMBED_DIR)/.dankrev

clean-qtbase:
	@rm -rf $(QTBASE_BUILD)

sync-shell:
	@test -f $(SHELL_DIR)/shell.qml || { echo "quickshell missing at $(SHELL_DIR)"; exit 1; }
	@mkdir -p $(EMBED_DIR)
	@find $(EMBED_DIR) -mindepth 1 ! -name .placeholder -delete
	@tar -C $(SHELL_DIR) --exclude=.qmlls.ini -chf - . | tar -C $(EMBED_DIR) -xf -
	@rm -rf $(EMBED_DIR)/scripts $(EMBED_DIR)/tests $(EMBED_DIR)/.claude
	@rm -f $(EMBED_DIR)/translations/extract_translations.py

build: sync-shell $(QTBASE_DEP)
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -tags 'withshell $(QTBASE_TAG)' $(BUILD_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

dev: $(QTBASE_DEP)
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -tags '$(QTBASE_TAG)' -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)

clean:
	@rm -rf $(BUILD_DIR)
	@test ! -d $(EMBED_DIR) || find $(EMBED_DIR) -mindepth 1 ! -name .placeholder -delete
	@test ! -d $(QTBASE_EMBED_DIR) || find $(QTBASE_EMBED_DIR) -mindepth 1 ! -name .placeholder -delete

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
	@echo "Targets: build dev qtbase clean-qtbase sync-shell clean test fmt vet deps"
	@echo "QTBASE=1 embeds the dux-qt-base runtime from the submodule; by default dclock needs an installed dux-qt-base"
