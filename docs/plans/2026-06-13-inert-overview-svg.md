# Inert Overview SVG Contract

## Status: In Progress

## Context

The documentation checker confirms that `docs/readme-overview.svg` exists and
contains required placeholder phrases, but it does not parse the asset. A
malformed document or active SVG element could satisfy those text fragments
while breaking rendering or broadening the asset's behavior.

## Priority

The overview is rendered directly from the public README. It should remain a
well-formed, self-contained image with explicit accessible naming and no
scripts, foreign HTML, event handlers, or linked resources.

## Objectives

- Parse the overview with Ruby's structured XML parser.
- Require the canonical SVG namespace and `svg` root.
- Require the existing `title`/`desc` accessibility relationship.
- Reject script, foreign-object, image, and use elements.
- Reject event-handler attributes and `href`/`xlink:href` references.
- Add focused hostile mutation tests and wire them into `make check`.
- Preserve the checked-in SVG bytes and placeholder wording.

## Planned Verification

- `ruby scripts/test-overview-svg-contract.rb`
- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- Read-only network-isolated Ruby 2.7 and Ruby 3.3 checks
- Focused malformed, active-content, accessibility, and wiring mutations
- `git diff --check`

## Scope Boundary

This contract validates the existing overview asset as inert documentation. It
does not introduce SVG generation, visual regression, or new roadmap content.
