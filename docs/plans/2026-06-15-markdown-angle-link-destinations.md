# Markdown Angle Link Destinations

Status: Planned

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
