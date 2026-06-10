# Issue Template Contact Link Uniqueness

## Status: Completed

## Context

The repository documentation checker required the canonical Security Policy
and Repository Scope links and kept every contact URL scoped to this
repository. It did not reject duplicate names or URLs, which could make the
issue chooser present ambiguous or redundant support routes.

## Objectives

- Require each issue-template contact-link name to be unique.
- Require each issue-template contact-link URL to be unique.
- Preserve the existing repository-scoped links and placeholder policy.

## Work Completed

- Extended `scripts/check-roadmap-docs.rb` to count non-empty contact-link
  names and URLs and report duplicates deterministically.
- Updated README and VISION maintenance guidance with the uniqueness rule.
- Recorded the guard in the changelog and canonical plan index.

## Verification

- `ruby -c scripts/check-roadmap-docs.rb`
- `ruby scripts/check-roadmap-docs.rb`
- `make lint`
- `make check`
- `make verify`
- `git diff --check`
