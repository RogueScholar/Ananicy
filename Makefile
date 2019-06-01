#!/usr/bin/make -f

SHELL = /bin/sh

CC = gcc -O2
CDEBUG = -g
CFLAGS = $(CDEBUG) -I. -I$(srcdir)
LDFLAGS = -g
LIBS =

INSTALL = $(command -v install)
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = ${INSTALL} -Dm644

prefix ?= /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(exec_prefix)/lib
libexecdir = $(exec_prefix)/libexec
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
datadir = $(datarootdir)
sysconfdir = $(prefix)/etc
localstatedir = $(prefix)/var
runstatedir ?= /run
includedir = $(prefix)/include
docdir = $(datarootdir)/doc/ananicy
infodir = $(datarootdir)/info
localedir = $(datarootdir)/locale
mandir = $(datarootdir)/man
manext = .1

srcdir := $(dir $(lastword $(MAKEFILE_LIST))) || .

ANANICYD_RULES := $(shell find $(srcdir)/ananicy.d -type f -name "*.rules")
ANANICYD_RULES_INSTALL := $(patsubst $(srcdir)/%.rules, $(DESTDIR)$(sysconfdir)/%.rules, $(ANANICYD_RULES))

ANANICYD_TYPES := $(shell find $(srcdir)/ananicy.d -type f -name "*.types")
ANANICYD_TYPES_INSTALL := $(patsubst $(srcdir)/%.types, $(DESTDIR)$(sysconfdir)/%.types, $(ANANICYD_TYPES))

ANANICYD_GROUPS := $(shell find $(srcdir)/ananicy.d -type f -name "*.cgroups")
ANANICYD_GROUPS_INSTALL := $(patsubst $(srcdir)/%.cgroups, $(DESTDIR)$(sysconfdir)/%.cgroups, $(ANANICYD_GROUPS))

ANANICY_SERVICE := $(DESTDIR)$(libdir)/systemd/system/ananicy.service
ANANICY_CONF := $(DESTDIR)$(sysconfdir)/ananicy.d/ananicy.conf
ANANICY_BIN := $(DESTDIR)$(bindir)/ananicy

AUX = README.md LICENSE CHANGELOG.md

.PHONY: all
all: install

default:  help

$(DESTDIR)$(sysconfdir)/%.cgroups: $(srcdir)/%.cgroups
	$(INSTALL_DATA) $< $@

$(DESTDIR)$(sysconfdir)/%.types: $(srcdir)/%.types
	$(INSTALL_DATA) $< $@

$(DESTDIR)$(sysconfdir)/%.rules: $(srcdir)/%.rules
	$(INSTALL_DATA) $< $@

$(ANANICY_CONF): $(srcdir)/ananicy.d/ananicy.conf
	$(INSTALL_DATA) $< $@

$(ANANICY_BIN): $(srcdir)/ananicy.py
	$(INSTALL_PROGRAM) -Dm755 $< $@


.PHONY: install
## Install ananicy
install: $(ANANICY_CONF) $(ANANICY_BIN)
install: $(ANANICYD_GROUPS_INSTALL)
install: $(ANANICYD_TYPES_INSTALL)
install: $(ANANICYD_RULES_INSTALL)

## Delete ananicy
uninstall:
	@rm -fv $(ANANICY_CONF)
	@rm -rf $(ANANICY_BIN)
	@rm -rf $(ANANICYD_GROUPS_INSTALL)
	@rm -rf $(ANANICYD_TYPES_INSTALL)
	@rm -rf $(ANANICYD_RULES_INSTALL)


## Create debian package
debian:
	$(SHELL) ./package.sh deb

help: ## Show help
	@grep -h "##" $(MAKEFILE_LIST) | grep -v grep | sed -e 's/\\$$//' | column -t -s '##'
