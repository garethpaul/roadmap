# Code Example Link Exclusion

Status: Completed

## Context

Heading extraction already ignores heading-like text inside matching backtick
and tilde fences. Link extraction scans the raw document instead, so Markdown
examples inside a fenced block or inline code span are treated as repository
links. A code sample containing `[Example](MISSING.md)` therefore fails
documentation validation even though GitHub renders it as inert code.

## Requirements

- Ignore inline image and link syntax while inside valid backtick or tilde
  fenced code blocks.
- Ignore image and link syntax inside matched inline backtick code spans,
  including spans delimited by multiple backticks.
- Preserve unmatched backticks as ordinary Markdown so rendered links are not
  silently skipped.
- Preserve backslash-escaped opening backticks as literal Markdown rather than
  treating them as code-span delimiters.
- Preserve opening fences with up to three leading spaces and at least three
  matching markers.
- Require a closing fence to use the same marker and at least the opening
  length before link extraction resumes.
- Preserve ordinary, angle-wrapped, percent-encoded, external, protocol-
  relative, local-path, fragment, ATX, Setext, and duplicate-anchor behavior
  outside fences.
- Keep Setext candidates from crossing a fenced-code boundary.
- Add mutation-sensitive focused tests, static contracts, guidance, changelog,
  and completed verification evidence.

## Approach

- Extract the existing fence transition rules into one dependency-free line
  traversal used by both heading and link collection, then mask matched inline
  code spans before link matching.
- Represent fenced lines as boundaries so heading state is reset while link
  scanning receives only rendered Markdown lines.
- Validate all links outside fences through the existing path, fragment, and
  safety pipeline.

## Scope Boundaries

- Do not add a Markdown parser dependency, network validation, or external URL
  fetching.
- Do not add reference-style link syntax or broaden the documented inline-link
  subset.
- Do not change roadmap scope, issue templates, workflow versions, heading
  slug rules, or repository path safety.

## Implementation Units

- `scripts/markdown-link-contract.rb`: share fence-aware line traversal between
  heading and inline-link extraction and exclude matched inline code spans.
- `scripts/test-markdown-link-contract.rb`: cover ignored fenced links,
  preserved outside links, matching markers, and minimum closing lengths.
- `scripts/check-roadmap-docs.rb`: preserve the shared traversal and focused
  regression fixtures.
- `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`: document the fenced-link
  validation boundary.

## Verification

- Run focused Markdown contract tests on the supported local Ruby runtime.
- Run repository-root and external-directory `make check`.
- Run Ruby 2.7 and Ruby 3.3 compatibility gates when available.
- Reject hostile mutations that remove fence exclusion, boundary resets,
  backtick or tilde coverage, closing-marker/length behavior, outside-link
  validation, guidance, or completed-plan evidence.
- Audit the exact diff, generated artifacts, credentials, conflicts, modes,
  binaries, dependencies, workflows, and upstream equality before shipment.

## Risks

- Fence parsing must remain aligned for heading and link validation; separate
  implementations would reintroduce drift.
- Inline code delimiters must match exactly so longer runs and unmatched
  backticks do not hide rendered links.
- Fenced content must be excluded without concatenating surrounding Markdown
  into a new link or Setext heading.

## Work Completed

- Shared one fence-aware line traversal between heading and inline-link
  extraction, preserving matching marker and closing-length rules.
- Excluded links and images inside matching fenced blocks and matched inline
  code spans without hiding rendered links after unmatched delimiters.
- Added focused behavior, static, guidance, changelog, plan-index, and completed
  evidence contracts without changing dependencies or workflows.

## Verification Results

- Nineteen tests and 48 assertions passed in the focused Markdown contract;
  seven overview-SVG tests and 57 assertions also remained green.
- The Git-backed projected final tree's repository-root and external-directory `make check` passed
  on Ruby 2.7.0 and network-isolated Ruby 3.3.11, including hostile `ROOT=/tmp`
  input.
- Eighteen hostile fenced-link mutations were rejected across fence traversal,
  boundary reset, closing and inline delimiter length, escaped-opener parity,
  inline masking, regression registration, guidance, and completed evidence.
- Exact diff, artifact, credential, conflict, mode, binary, dependency,
  workflow, and upstream audits passed with only the eight intended paths.
