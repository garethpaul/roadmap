# README Issue Template Guard

## Status: Completed

## Context

`roadmap` keeps `.github/ISSUE_TEMPLATE/config.yml` scoped to this placeholder
repository and disables blank issues until roadmap scope is defined. The
documentation checker validated that config file, but the README did not have
to point maintainers at the issue-template policy.

## Objectives

- Keep issue-template behavior visible from the public README.
- State that blank issues remain disabled until scope is defined.
- Extend the documentation checker to require the README issue-template note.
- Preserve the existing placeholder, scope, VISION, SVG, and plan checks.

## Work Completed

- Added a README maintenance note for `.github/ISSUE_TEMPLATE/config.yml`.
- Documented that blank issues disabled is the expected policy until scope is
  defined.
- Extended `scripts/check-roadmap-docs.rb` to require those README phrases.
- Updated VISION and CHANGES notes for the README issue-template guard.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- `make verify`
- `git diff --check`
