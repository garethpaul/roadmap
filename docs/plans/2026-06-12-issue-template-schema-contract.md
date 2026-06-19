# Issue Template Schema Contract

## Status: Completed

## Context

The placeholder roadmap intentionally exposes only Security Policy and
Repository Scope contact routes. The checker validates their names, URLs, and
uniqueness, but it still accepts arbitrary contact descriptions and unrelated
top-level or per-link YAML fields.

## Priority

The issue chooser is a public support boundary. Until the repository defines a
product, owner, audience, timeframe, and commitment level, its complete schema
and user-facing copy should remain explicit and reviewable.

## Requirements

- R1. Parse the issue-template configuration with safe YAML loading.
- R2. Require exactly `blank_issues_enabled` and `contact_links` at the top
  level.
- R3. Require exactly two contact-link mappings in the reviewed order.
- R4. Require each mapping to contain only `name`, `url`, and `about`.
- R5. Preserve the exact approved names, repository-scoped URLs, and
  non-commitment descriptions.
- R6. Keep validation dependency-free on Ruby 2.7 and Ruby 3.3.
- R7. Protect the checker, documentation, and completed plan with focused
  hostile mutations.

## Scope Boundaries

- Do not add issue forms, blank issues, support promises, or roadmap content.
- Do not change the approved contact destinations.
- Do not add Ruby or project dependencies.

## Verification Plan

- `ruby -c scripts/check-roadmap-docs.rb`
- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- `make verify`
- focused hostile issue-template schema and copy mutations
- `git diff --check`

## Work Completed

- Replaced overlapping permissive contact-link checks with one safely parsed,
  exact configuration contract.
- Required the two reviewed routes in order with no extra top-level or per-link
  fields and exact names, repository URLs, and non-commitment descriptions.
- Added non-self-satisfying checker sentinels for safe YAML loading and exact
  parsed comparison.
- Aligned README, SECURITY, VISION, CHANGES, and the canonical plan index with
  the frozen issue-template boundary.

## Verification

- `ruby -c scripts/check-roadmap-docs.rb` passed.
- `ruby scripts/check-roadmap-docs.rb` passed.
- `make check` passed.
- `make verify` passed.
- The Makefile gate passed when invoked from outside the repository.
- Ruby 2.7 and Ruby 3.3 validation passed in clean dependency-free containers.
- 14 focused hostile issue-template mutations were rejected, covering extra
  top-level and per-link fields, blank issues, route order, names, URLs, copy,
  missing and malformed routes, invalid YAML, safe loading, exact comparison,
  documentation, and completed-plan status.
- `git diff --check` passed.
