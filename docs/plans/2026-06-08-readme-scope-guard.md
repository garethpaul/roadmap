# README Scope Guard

## Status: Completed

## Context

`roadmap` is a placeholder repository. `SCOPE.md` clearly says there are no
active roadmap commitments, but the README is the public entrypoint most readers
will see first. It should carry the same non-commitment warning and the checker
should keep that warning in place.

## Objectives

- Keep README and `SCOPE.md` aligned on placeholder status.
- State that no active roadmap commitments are defined.
- Tell readers not to treat the repository as an active delivery plan until
  owner, audience, timeframe, and commitment level are documented.
- Extend `make check` to validate the README guard language.

## Work Completed

- Added README non-commitment language under Running or Using the Project.
- Extended `scripts/check-roadmap-docs.rb` to require the README guard phrases.
- Updated VISION and CHANGES.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- `make verify`
- `git diff --check`

## Follow-Up Candidates

- Define whether this repository is a product roadmap, personal roadmap, or
  project index before adding commitments.
- Archive the repository explicitly if it is no longer needed.
