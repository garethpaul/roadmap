# Document Link Integrity

Status: Completed

## Context

The documentation checker validates exact content and tracked metadata paths,
but it previously followed filesystem entries without proving that Git records
them as ordinary files. It also checked the README plan index without resolving
the repository's other relative Markdown links.

## Objectives

- Require every tracked entry to remain a stage-0 regular Git blob.
- Reject symlinks, gitlinks, merge stages, and executable-mode drift.
- Resolve relative links and images in every tracked Markdown document.
- Reject missing targets, symlink targets, and paths outside the repository.
- Keep external URLs and same-document anchors outside the offline file check.

## Work Completed

- Added NUL-delimited `git ls-files --stage` parsing to the Ruby checker.
- Added dependency-free local Markdown target extraction and URI unescaping.
- Added repository containment, regular-file, and symlink-target checks.
- Documented the tracked-content boundary in README, SECURITY, VISION, and
  CHANGES.

## Verification

- `ruby -c scripts/check-roadmap-docs.rb` passed.
- `make check` passed the complete documentation contract.
- `make -f /home/gjones/code/private/worktrees/roadmap-document-link-integrity/Makefile check`
  passed from `/tmp`.
- Read-only, network-isolated Ruby 2.7.8 and Ruby 3.3.11 containers passed
  `make check` against a standalone staged Git fixture.
- Focused hostile mutations for an executable tracked file, a missing local
  target, a repository-escaping link, and a symlink target were rejected with
  the intended mode or local-target failures.
- `git diff --check` passed.
