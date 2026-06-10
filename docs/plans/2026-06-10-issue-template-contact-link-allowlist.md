# Issue Template Contact Link Allowlist

## Status: Completed

## Context

The documentation checker required the Security Policy and Repository Scope
contact links, complete fields, repository-scoped URLs, and unique names and
URLs. It still allowed extra repository routes even though the roadmap has no
defined product, owner, audience, or support model.

## Objectives

- Keep the issue chooser limited to the two approved placeholder routes.
- Reject additional named contact links until roadmap scope is defined.
- Preserve the existing field, URL-scope, and uniqueness checks.

## Work Completed

- Added an exact contact-link name allowlist to the documentation checker.
- Kept Security Policy and Repository Scope as the only approved routes.
- Updated README, SECURITY, VISION, CHANGES, and the canonical plan index.

## Verification

- `ruby -c scripts/check-roadmap-docs.rb`
- `ruby scripts/check-roadmap-docs.rb`
- `make lint`
- `make check`
- `make verify`
- `git diff --check`
