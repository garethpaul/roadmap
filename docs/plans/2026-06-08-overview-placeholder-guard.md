# Overview Placeholder Guard

## Status: Completed

## Context

`roadmap` is intentionally a placeholder repository. README and `SCOPE.md`
state that no active roadmap commitments are defined, but the README overview
image still described the repository as a generic public sample. Since that
image is visible near the top of the README, it needs the same non-commitment
language as the surrounding docs.

## Objectives

- Keep default verification dependency-free.
- Align the overview image with the placeholder scope.
- Fail `make check` when the overview stops stating placeholder and
  non-commitment language.
- Preserve existing README, SCOPE, issue-template, and completed-plan checks.

## Work Completed

- Updated `docs/readme-overview.svg` to describe the repository as a
  placeholder planning repository.
- Added overview language validation to `scripts/check-roadmap-docs.rb`.
- Updated README, VISION, and CHANGES notes for the new guardrail.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- `make verify`
- `git diff --check`
