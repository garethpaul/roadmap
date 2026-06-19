# Setext Heading Anchor Validation

Status: Completed

## Context

The local Markdown link validator derives anchors from ATX headings and ignores
ATX-looking lines inside fenced code blocks. GitHub Markdown also creates
anchors for Setext headings, where a text line is followed by an `===` or `---`
underline. The current validator omits those anchors and can therefore reject a
valid same-file or cross-file fragment link.

## Priorities

1. Recognize Setext level-one and level-two heading anchors using the existing
   GitHub-style slug and duplicate-suffix rules.
2. Ignore Setext-looking content inside fenced code blocks.
3. Avoid treating blank lines, underline-only lines, and thematic breaks as
   headings.
4. Preserve the dependency-free Ruby 2.7 and Ruby 3.3 compatibility boundary.

## Implementation Units

### Anchor Extraction

File: `scripts/markdown-link-contract.rb`

- Track the preceding eligible text line while outside a fenced block.
- Emit a Setext anchor only when the next line is a valid equals or hyphen
  underline and the candidate text is nonblank.
- Reuse the current slug generation and duplicate-anchor allocation path.
- Keep fenced code handling authoritative before heading recognition.

### Regression Coverage

File: `scripts/test-markdown-link-contract.rb`

- Accept same-file and cross-file links targeting Setext headings.
- Cover both underline markers and duplicate suffix allocation across ATX and
  Setext headings.
- Reject fragments that match only fenced, blank, or thematic-break content.

### Repository Contracts

Files: `scripts/check-roadmap-docs.rb`, `README.md`, `SECURITY.md`, `VISION.md`,
`CHANGES.md`

- Require the Setext implementation and tests in the maintained checker.
- Document the expanded heading-anchor subset without claiming full CommonMark
  parsing.
- Require completed plan and verification evidence.

## Verification Completed

- The focused Markdown link contract suite passed: Twelve tests and 33 assertions passed.
- The repository-root and external-directory `make check` passed, together
  with every public Make alias.
- The local Ruby 2.7 lane passed. Ruby 3.3 remains covered by the pinned hosted
  matrix because no local Ruby 3.3 runtime or cached container image was
  available.
- Seven hostile Setext mutations were rejected across detection, fence exclusion,
  duplicate suffixes, list-marker and tab-indentation false positives,
  documentation, and completed plan evidence.
- Exact-path, generated-artifact, diff, conflict-marker, and changed-line secret
  audits passed.

## Boundaries

- Do not add a Markdown parser dependency.
- Do not expand remote URL validation or non-Markdown fragment behavior.
- Do not claim complete CommonMark or GitHub Markdown equivalence.
- Do not merge or close the stacked pull requests without explicit owner
  authorization.
