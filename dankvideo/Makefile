BINARY_NAME=dplay
SHELL_NAME=dankvideo
ICON_NAME=com.danklinux.dankvideo
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

.PHONY: all build dev run clean test fmt vet update-common install uninstall install-user uninstall-user help

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

update-common:
	git submodule update --remote --merge dank-qml-common

install: build
	@install -D -m 755 $(BUILD_DIR)/$(BINARY_NAME) $(DESTDIR)$(INSTALL_DIR)/$(BINARY_NAME)
	@install -D -m 644 distro/$(ICON_NAME).desktop $(DESTDIR)$(APPLICATIONS_DIR)/$(ICON_NAME).desktop
	@install -D -m 644 assets/$(ICON_NAME).svg $(DESTDIR)$(ICON_DIR)/$(ICON_NAME).svg
	@mkdir -p $(DESTDIR)$(QUICKSHELL_DIR)
	@cp -rL $(SHELL_DIR)/* $(DESTDIR)$(QUICKSHELL_DIR)/

uninstall:
	@rm -f $(DESTDIR)$(INSTALL_DIR)/$(BINARY_NAME)
	@rm -f $(DESTDIR)$(APPLICATIONS_DIR)/$(ICON_NAME).desktop
	@rm -f $(DESTDIR)$(ICON_DIR)/$(ICON_NAME).svg
	@rm -rf $(DESTDIR)$(QUICKSHELL_DIR)

install-user: build
	@$(MAKE) install PREFIX=$(HOME)/.local

uninstall-user:
	@$(MAKE) uninstall PREFIX=$(HOME)/.local

help:
	@echo "DankVideo Makefile targets:"
	@echo "  build       - Build the dplay binary"
	@echo "  dev         - Fast development build"
	@echo "  run [video] - Build and run dplay with optional video path"
	@echo "  test / fmt / vet"
	@echo "  install / uninstall"
	@echo "  install-user / uninstall-user"
