.DEFAULT_GOAL := check

.PHONY: build check lint root-test test verify

override SHELL := /bin/sh
override .SHELLFLAGS := -c
override RUBY := ruby
ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
override MAKEFILES :=
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override ROOT := $(shell path='$(subst ','"'"',$(MAKEFILE_LIST))'; path=$$(printf '%s' "$$path" | /usr/bin/sed 's/^ //'); [ -f "$$path" ] || exit 1; directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)
export ROOT
ifeq ($(strip $(ROOT)),)
$(error repository Makefile path could not be resolved)
endif

lint:
	$(RUBY) "$$ROOT/scripts/check-roadmap-docs.rb"

test: lint
	$(RUBY) "$$ROOT/scripts/test-markdown-link-contract.rb"
	$(RUBY) "$$ROOT/scripts/test-overview-svg-contract.rb"

build:
	@echo "documentation-only repository; no build step required"

root-test:
	"$$ROOT/scripts/test-makefile-root.sh"

verify: root-test lint test build

check: verify
