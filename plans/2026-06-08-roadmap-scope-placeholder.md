# Roadmap Scope Placeholder

## Status

Completed

## Context

`roadmap` is intentionally sparse, but the repository needs a durable scope
artifact so readers can distinguish placeholder status from active delivery
commitments. The current integrity gate checks copied support metadata but does
not require a scope document.

## Objectives

- Add `SCOPE.md` with explicit placeholder status and non-commitment language.
- Link the scope document from README and issue-template contact links.
- Extend `scripts/check-roadmap-docs.rb` to require the scope document and key
  guardrail language.
- Keep the repository documentation-only.

## Verification

- `make lint`
- `make verify`
- `git diff --check`
