# Exclude HTML Comments From Markdown Integrity Checks

Status: Completed

## Context

The roadmap Markdown contract excludes fenced and inline code examples but
still scans HTML comments as rendered document content. A commented
`[Example](MISSING.md)` therefore fails link validation, and a commented
heading can incorrectly satisfy a fragment even though GitHub renders neither
as live document structure.

## Goal

Exclude HTML-comment content from local-link and heading-anchor extraction
without hiding rendered Markdown around comments or changing the repository's
documented inline-link subset.

## Requirements

1. Ignore links, images, ATX headings, and Setext heading candidates inside
   closed inline or multiline `<!-- ... -->` comments.
2. Treat an unclosed HTML comment as inert through end of document.
3. Preserve rendered links and headings before and after a closed comment,
   including multiple comments in one document.
4. Preserve comment delimiters inside matching fenced code blocks and matched
   inline code spans as literal code, so they do not hide later rendered
   Markdown.
5. Preserve existing fence, inline-code, angle-destination, percent-decoding,
   path-containment, fragment, duplicate-anchor, and Setext behavior.
6. Add mutation-sensitive tests, static contracts, guidance, changelog, and
   completed verification evidence without adding a Markdown dependency.

## Implementation Units

### Comment-Aware Markdown Projection

- Update `scripts/markdown-link-contract.rb` with a shared comment-masking
  projection used by both link and heading extraction.
- Preserve line boundaries while masking comments so surrounding text cannot
  join into a synthetic link or Setext heading.
- Reuse the existing code-span and fence rules to keep comment delimiters in
  code examples inert.

### Regression And Static Contracts

- Extend `scripts/test-markdown-link-contract.rb` with closed, multiline,
  unclosed, surrounding-content, fenced-code, and inline-code cases.
- Extend `scripts/check-roadmap-docs.rb` so removal of comment masking,
  regression fixtures, guidance, plan status, or evidence fails closed.

### Documentation

- Update `README.md`, `SECURITY.md`, `VISION.md`, and `CHANGES.md` with the
  rendered-comment boundary.
- Mark this plan completed only after focused, repository, external-directory,
  and supported-Ruby validation succeeds.

## Verification

- Run the focused Markdown contract tests and overview-SVG tests.
- Run `make check` from the repository and through the absolute Makefile path
  from an external directory with hostile `ROOT=/tmp`.
- Run Ruby 2.7 and Ruby 3.3 compatibility gates when available.
- Reject hostile mutations that remove closed/unclosed comment handling,
  surrounding-content preservation, code-example protection, static
  registration, guidance, or completed-plan evidence.
- Audit the exact diff, generated artifacts, credentials, conflicts, modes,
  binaries, dependencies, workflows, and upstream relationship before commit.

## Risks And Boundaries

- Comment masking must preserve newlines and code boundaries; deleting comment
  text outright could concatenate surrounding Markdown into a false link or
  heading.
- This remains a dependency-free repository contract, not a complete CommonMark
  parser. The change is limited to standard HTML comment delimiters.
- Roadmap scope, issue templates, workflow versions, and external links remain
  unchanged.

## Assumptions

- HTML comments are authoring metadata and should not participate in rendered
  link or anchor integrity.
- Existing fenced and inline code behavior is authoritative and must remain
  unchanged.

## Work Completed

- Added a shared HTML-comment mask that preserves newlines and protects matched
  inline code spans before link and heading extraction.
- Reused the existing fence-aware segmentation so comment delimiters inside
  fenced examples remain inert and rendered Markdown resumes after each fence.
- Added closed, multiline, unclosed, surrounding-content, ATX/Setext heading,
  inline-code, and fenced-code regression coverage plus static, guidance,
  changelog, and plan contracts.

## Verification Results

- Twenty-three tests and 62 assertions passed in the focused Markdown contract;
  seven overview-SVG tests and 57 assertions also remained green.
- Eight hostile HTML-comment mutations were rejected across link and heading
  masking, delimiters, code-span protection, newline preservation, unclosed
  comments, and fence segmentation.
- The repository and external-directory `make check` passed on Ruby 2.7.0,
  including hostile `ROOT=/tmp` input.
- A network-isolated, read-only Ruby 3.3.11 container passed the external
  Makefile gate.
- Exact diff, artifact, credential, conflict, mode, binary, dependency,
  workflow, and upstream audits passed with only the eight intended paths.
