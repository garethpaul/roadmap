# Roadmap Documentation Integrity

## Problem

The repository is intentionally sparse, but its issue-template config and
generated overview still contained copied Twilio/support references. That made
the placeholder look like a service-specific support repository.

## TDD Evidence

1. Added `scripts/check-roadmap-docs.rb` and wired it to `make lint`.
2. Ran the checker before documentation fixes and confirmed it failed on copied
   support references, missing `blank_issues_enabled: false`, and unscoped
   contact links.
3. Replaced the copied links with repository-scoped links, removed stale
   integration claims, and reran the verification gate.

## Verification

- `make lint`
- `make test`
- `make verify`
- `git diff --check`
