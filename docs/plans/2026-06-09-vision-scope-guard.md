# VISION Scope Guard

## Status: Completed

## Context

`roadmap` is a placeholder repository. The README and `SCOPE.md` already state
that no active roadmap commitments are defined, but `VISION.md` is another
public entrypoint and should carry the same explicit non-commitment warning.

## Objectives

- Keep README, SCOPE, and VISION aligned on placeholder status.
- State in VISION that no active roadmap commitments are defined.
- Require owner and timeframe before roadmap commitments are added.
- Extend the documentation integrity checker without adding dependencies.

## Work Completed

- Added explicit no-commitment language to `VISION.md`.
- Extended `scripts/check-roadmap-docs.rb` to require VISION guard phrases.
- Updated README and CHANGES notes for the VISION scope guard.
- Added this completed plan under `docs/plans/`.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- `make verify`
- `git diff --check`
