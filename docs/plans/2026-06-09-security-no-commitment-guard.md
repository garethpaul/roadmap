# Security No-Commitment Guard

## Status: Completed

## Context

The roadmap repository is an explicit placeholder with no active commitments.
`SECURITY.md` documented vulnerability reporting mechanics, but it did not
repeat the no-commitment boundary. That could let security-process wording read
like a product or delivery promise.

## Objectives

- Keep the security policy useful for vulnerability reporting.
- State clearly that no active roadmap commitments are defined.
- State clearly that security reports are not roadmap commitments.
- Extend the documentation checker so the boundary cannot drift.

## Work Completed

- Added no-commitment language to `SECURITY.md`.
- Extended `scripts/check-roadmap-docs.rb` to require the security-policy
  commitment boundary.
- Updated README, VISION, and CHANGES notes for the security guard.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make lint`
- `make check`
- `make verify`
- `git diff --check`
