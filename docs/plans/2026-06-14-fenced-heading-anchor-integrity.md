# Fenced Heading Anchor Integrity

## Status: In Progress

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
