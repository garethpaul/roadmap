# Hosted Roadmap Document Validation

Status: Completed

## Context

This repository is intentionally a placeholder with no active roadmap
commitments. Its dependency-free Ruby checker protects scope language, issue
contact links, security boundaries, the plan index, and required documentation,
but the default branch did not run that contract in hosted validation.

## Objectives

- Run the maintained documentation contract on pushes and pull requests.
- Install no project or Ruby dependencies in hosted validation.
- Pin third-party actions and grant read-only repository permissions.
- Keep `make check` usable from outside the repository directory.
- Fail closed if the hosted workflow or this completed plan is removed.

## Work Completed

- Added `.github/workflows/check.yml` on a fixed Ubuntu 24.04 runner.
- Pinned checkout to an immutable commit and limited permissions to read access.
- Made the Makefile resolve the Ruby checker relative to itself.
- Extended the checker to validate the workflow controls and completed plan.

## Verification

- `make check`
- `make -f /path/to/repository/Makefile check` from outside the repository
- `ruby -c scripts/check-roadmap-docs.rb`
- `git diff --check`
