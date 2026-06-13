ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RUBY ?= ruby

.PHONY: build check lint test verify

lint:
	$(RUBY) "$(ROOT)/scripts/check-roadmap-docs.rb"

test: lint
	$(RUBY) "$(ROOT)/scripts/test-markdown-link-contract.rb"
	$(RUBY) "$(ROOT)/scripts/test-overview-svg-contract.rb"

build:
	@echo "documentation-only repository; no build step required"

verify: lint test build

check: verify
