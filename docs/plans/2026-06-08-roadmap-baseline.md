# Roadmap Baseline

## Status: Completed

## Context

`roadmap` is intentionally a placeholder repository. Its value is in being
clear about that status: no product, audience, or delivery commitments are
defined yet, and support metadata should stay scoped to this repository.

## Objectives

- Preserve the documentation-only placeholder state.
- Require `SCOPE.md`, `VISION.md`, `SECURITY.md`, and the overview asset.
- Keep issue-template contact links repository-scoped and blank issues disabled.
- Reject copied support references from unrelated projects.
- Maintain completed maintenance plans under `docs/plans`.

## Work Completed

- Confirmed `make check` runs the roadmap documentation integrity checker.
- Added canonical `docs/plans` coverage for the current placeholder baseline.
- Extended the checker to require completed `docs/plans` entries with
  `make check` verification.
- Updated README, VISION, and CHANGES to make the baseline discoverable.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- `make verify`
- `git diff --check`

## Follow-Up Candidates

- Define whether this repository is a product roadmap, personal roadmap, or
  project index before adding commitments.
- Archive the repository explicitly if it is no longer needed.
