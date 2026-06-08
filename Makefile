.PHONY: build check lint test verify

lint:
	ruby scripts/check-roadmap-docs.rb

test: lint

build:
	@echo "documentation-only repository; no build step required"

verify: lint test build

check: verify
