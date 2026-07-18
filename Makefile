.DEFAULT_GOAL := check

.PHONY: __repository-make-authority build check lint root-test test verify
.SECONDEXPANSION:

override SHELL := /bin/sh
override .SHELLFLAGS := -c
override RUBY := ruby
ifneq ($(filter command line,$(origin MAKEFLAGS)),)
$(error MAKEFLAGS must not be overridden for repository verification)
endif
override REPOSITORY_MAKE_FIRST_FLAGS := $(firstword $(MAKEFLAGS))
ifneq ($(filter -%,$(REPOSITORY_MAKE_FIRST_FLAGS)),)
override REPOSITORY_MAKE_FIRST_FLAGS :=
endif
override REPOSITORY_MAKE_SHORT_FLAGS := $(REPOSITORY_MAKE_FIRST_FLAGS) $(filter-out --%,$(filter -%,$(MAKEFLAGS)))
ifneq ($(findstring n,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring t,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring q,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring i,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(filter --just-print --dry-run --recon --touch --question --ignore-errors,$(MAKEFLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
override MAKEFILES :=
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override REPOSITORY_MAKEFILE := $(value MAKEFILE_LIST)
override EXPECTED_MAKEFILE_LIST := $(value MAKEFILE_LIST)
override CURRENT_MAKEFILE_LIST = $(value MAKEFILE_LIST)
export REPOSITORY_MAKEFILE EXPECTED_MAKEFILE_LIST CURRENT_MAKEFILE_LIST
override ROOT :=

build check lint root-test test verify:: $$(if $$(filter file,$$(origin MAKEFILE_LIST)),,$$(error MAKEFILE_LIST must not be overridden))
build check lint root-test test verify:: __repository-make-authority

__repository-make-authority::
	@if [ "$$CURRENT_MAKEFILE_LIST" != "$$EXPECTED_MAKEFILE_LIST" ]; then \
		printf '%s\n' 'multiple -f Makefiles are not supported' >&2; \
		exit 1; \
	fi

override define RUN_IN_REPO
if [ "$$CURRENT_MAKEFILE_LIST" != "$$EXPECTED_MAKEFILE_LIST" ]; then \
	printf '%s\n' 'multiple -f Makefiles are not supported' >&2; \
	exit 1; \
fi; \
makefile=$${REPOSITORY_MAKEFILE# }; \
if [ -z "$$makefile" ] || [ ! -f "$$makefile" ]; then \
	printf '%s\n' 'repository Makefile path could not be resolved' >&2; \
	exit 1; \
fi; \
case "$$makefile" in \
	*/*) repository_directory=$${makefile%/*} ;; \
	*) repository_directory=. ;; \
esac; \
ROOT=$$(CDPATH= cd -- "$$repository_directory" && pwd -P); \
export ROOT; \
cd "$$ROOT" &&
endef

lint::
	$(RUN_IN_REPO) $(RUBY) scripts/check-roadmap-docs.rb

test:: lint
	$(RUN_IN_REPO) $(RUBY) scripts/test-markdown-link-contract.rb
	$(RUN_IN_REPO) $(RUBY) scripts/test-overview-svg-contract.rb
	$(RUN_IN_REPO) $(RUBY) scripts/test-contract-mutations.rb

build::
	@$(RUN_IN_REPO) printf '%s\n' "documentation-only repository; no build step required"

root-test::
	$(RUN_IN_REPO) /bin/sh scripts/test-makefile-root.sh

verify:: root-test lint test build

check:: verify
