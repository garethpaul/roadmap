# README Plan Index Guard

## Status: Completed

## Context

`roadmap` keeps canonical maintenance records under `docs/plans/` and links
them from README maintenance notes, but the documentation checker did not
require that index to stay complete. A completed plan could be added without a
public README reference, or README could keep a stale link after a plan rename.

## Objectives

- Require README to reference every canonical plan under `docs/plans/`.
- Fail when README references a missing canonical plan.
- Keep the repository documentation-only and avoid adding roadmap commitments.

## Work Completed

- Extended `scripts/check-roadmap-docs.rb` to validate README plan references
  in both directions.
- Added the README reference for this completed plan.
- Updated VISION and CHANGES notes for the README plan-index guard.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- `make verify`
- `git diff --check`
