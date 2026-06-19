# Markdown Angle Link Destinations

Status: Completed

## Context

Markdown permits inline link destinations wrapped in angle brackets to contain
literal spaces, such as `<design notes.md#review>`. The local-link parser uses a
single whitespace-free destination pattern, so it silently skips these links
instead of validating their target path and fragment.

## Requirements

- Parse angle-bracket inline destinations with literal spaces as one local
  target.
- Preserve ordinary whitespace-free destinations, optional quoted titles,
  percent decoding, external schemes, and protocol-relative exclusions.
- Reject missing, escaping, malformed, non-Markdown-fragment, and missing-anchor
  angle destinations through the existing validation path.
- Add mutation-sensitive tests and completed verification evidence.

## Approach

- Separate angle-wrapped and ordinary inline destination alternatives in the
  dependency-free parser contract.
- Normalize both alternatives into the same existing path/fragment validation
  pipeline rather than adding a second validator.
- Extend focused tests with valid literal-space paths and broken angle targets;
  protect the new examples in the repository checker.

## Scope Boundaries

- Do not implement reference-style links, images beyond the existing inline
  handling, external URL fetching, or a full CommonMark parser.
- Do not change heading slug generation, fenced-code handling, Setext handling,
  issue templates, hosted workflow coverage, or roadmap placeholder policy.

## Verification

- Run focused Markdown contract tests and the full Ruby documentation gate from
  the repository and an external working directory.
- Reject hostile mutations that restore the whitespace-free-only pattern or
  remove the literal-space and broken-target assertions.
- Audit the exact diff, generated artifacts, credentials, conflicts, modes,
  binaries, large files, and upstream head.

## Risks

- The inline-link pattern remains intentionally scoped; new syntax support must
  not make malformed or external destinations look like local repository paths.

## Implementation Units

- `scripts/markdown-link-contract.rb`: recognize angle-wrapped destinations
  while preserving the shared validation pipeline.
- `scripts/test-markdown-link-contract.rb`: cover valid and invalid literal-space
  angle destinations.
- `scripts/check-roadmap-docs.rb`: require the parser and regression contracts.
- `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`: document the supported
  local-link boundary.

## Work Completed

- Split inline destinations into angle-wrapped and ordinary alternatives, then
  normalized both into the existing repository path and fragment validator.
- Added focused coverage for valid literal-space paths plus missing, escaping,
  missing-anchor, and non-Markdown-fragment angle destinations.
- Added static parser/test contracts and aligned README, security, vision,
  changelog, and canonical plan-index guidance.

## Verification Results

- `ruby scripts/test-markdown-link-contract.rb` passed 13 tests and 34
  assertions across ordinary, percent-encoded, angle-wrapped, fenced, ATX, and
  Setext behavior.
- `make check` passed the complete documentation, 13-test/34-assertion Markdown
  link, 7-test/57-assertion overview SVG, and documentation-only build gate from
  both repository and external working directories.
- Two hostile mutations restoring the whitespace-free-only parser or removing
  the literal-space regression were rejected by the repository checker.
- Ruby syntax and `git diff --check` passed; exact diff, secret,
  generated-artifact, conflict, mode, binary, and upstream audits passed before
  commit.
