# Issue Template Contact Links

## Status: Completed

## Context

The repository disables blank issues until roadmap scope is defined and keeps
issue-template contact links scoped to this repository. The documentation
checker validated each contact link when present, but it did not require the
expected security-policy and scope links to remain present.

## Objectives

- Require the issue-template config to include repository-scoped contact links.
- Keep the Security Policy link pointed at the repository security policy.
- Keep the Repository Scope link pointed at `SCOPE.md`.
- Preserve the placeholder status without adding roadmap commitments.

## Work Completed

- Extended `scripts/check-roadmap-docs.rb` to require non-empty contact links.
- Required exact Security Policy and Repository Scope contact-link URLs.
- Hardened the contact-link loop so non-mapping entries are reported clearly.
- Updated README, VISION, and CHANGES notes for the contact-link guard.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- `make verify`
- `git diff --check`
