.PHONY: lint test build verify

lint:
	ruby scripts/check-roadmap-docs.rb

test: lint

build:
	@echo "documentation-only repository; no build step required"

verify: lint test build
