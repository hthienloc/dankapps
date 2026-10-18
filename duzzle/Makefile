BINARY_NAME=duzzle
SHELL_NAME=duzzle
ICON_NAME=com.danklinux.duzzle
CORE_DIR=core
BUILD_DIR=$(CORE_DIR)/bin
PREFIX ?= /usr/local
DESTDIR ?=
INSTALL_DIR=$(PREFIX)/bin
DATA_DIR=$(PREFIX)/share
ICON_DIR=$(DATA_DIR)/icons/hicolor/scalable/apps
APPLICATIONS_DIR=$(DATA_DIR)/applications
QUICKSHELL_DIR=$(DATA_DIR)/quickshell/$(SHELL_NAME)
SHELL_DIR=quickshell

.PHONY: all build dev run clean test fmt vet install uninstall install-user uninstall-user help

all: build

build:
	@$(MAKE) -C $(CORE_DIR) build

dev:
	@$(MAKE) -C $(CORE_DIR) dev

run: dev
	@$(BUILD_DIR)/$(BINARY_NAME) -c $(CURDIR)/$(SHELL_DIR) $(filter-out $@,$(MAKECMDGOALS))

clean:
	@$(MAKE) -C $(CORE_DIR) clean

test:
	@$(MAKE) -C $(CORE_DIR) test

fmt:
	@$(MAKE) -C $(CORE_DIR) fmt

vet:
	@$(MAKE) -C $(CORE_DIR) vet

install: build
	@install -D -m 755 $(BUILD_DIR)/$(BINARY_NAME) $(DESTDIR)$(INSTALL_DIR)/$(BINARY_NAME)
	@install -D -m 644 distro/$(ICON_NAME).desktop $(DESTDIR)$(APPLICATIONS_DIR)/$(ICON_NAME).desktop
	@mkdir -p $(DESTDIR)$(QUICKSHELL_DIR)
	@cp -rL $(SHELL_DIR)/* $(DESTDIR)$(QUICKSHELL_DIR)/

uninstall:
	@rm -f $(DESTDIR)$(INSTALL_DIR)/$(BINARY_NAME)
	@rm -f $(DESTDIR)$(APPLICATIONS_DIR)/$(ICON_NAME).desktop
	@rm -rf $(DESTDIR)$(QUICKSHELL_DIR)

install-user: build
	@$(MAKE) install PREFIX=$(HOME)/.local

uninstall-user:
	@$(MAKE) uninstall PREFIX=$(HOME)/.local

help:
	@echo "Duzzle Makefile targets:"
	@echo "  build       - Build the duzzle binary"
	@echo "  dev         - Fast development build"
	@echo "  run         - Build and run duzzle"
	@echo "  test / fmt / vet"
	@echo "  install / uninstall"
