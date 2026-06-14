# Fenced Heading Anchor Integrity

## Status: Completed

## Context

The Markdown anchor validator currently treats every ATX-looking line as a
heading. A `#` line inside a fenced code block can therefore satisfy a local
fragment even though GitHub renders it as code and creates no anchor.

## Requirements

- Ignore ATX-looking lines while inside backtick or tilde fenced code blocks.
- Respect opening fences with up to three leading spaces and at least three
  matching fence characters.
- Require a closing fence to use the same marker and at least the opening
  length.
- Resume heading collection after a valid closing fence.
- Preserve the existing GitHub-compatible heading normalization and duplicate
  suffix behavior outside fences.
- Add mutation-sensitive tests and checker wiring for the fence boundary.

## Scope Boundaries

- Do not add a Markdown parser dependency or network validation.
- Do not change external-link handling, local-path safety, SVG policy, issue
  templates, workflow versions, or roadmap commitments.

## Verification

- focused Markdown link contract tests
- repository-root and external-directory `make check`
- Ruby 2.7 and Ruby 3.3 compatibility when available
- hostile fence-open, marker, length, close, and completed-plan mutations
- exact diff, generated-artifact, and credential-pattern audits

## Verification Results

- Ten tests and 29 assertions passed in the focused Markdown link contract.
- The repository-root and external-directory `make check` passed after this
  completed status was recorded.
- Seven hostile fence mutations were rejected across minimum opener length,
  backtick info strings, marker matching, closing length, active fence state,
  closing transitions, and tilde support.
- Read-only, network-isolated Ruby 2.7.8 and Ruby 3.3.11 containers each
  passed the complete `make check` gate after a container-local Git
  `safe.directory` ownership declaration; their focused runs also passed 10
  tests and 29 assertions.
- Final exact-diff, generated-artifact, and credential-pattern audits found
  only the intended contract, test, checker, and completed-plan changes.
