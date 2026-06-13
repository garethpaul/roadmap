# Markdown Anchor Integrity

## Status: Pending

## Context

The documentation checker validates repository-local Markdown link targets but
discards URL fragments. A same-file or cross-file link can therefore name a
missing section while `make check` still passes.

## Requirements

- **R1:** Parse inline local Markdown links into path and fragment components.
- **R2:** Preserve existing containment, regular-file, symlink, and tracked-mode
  checks for local paths.
- **R3:** Resolve non-empty fragments against deterministic GitHub-style
  heading anchors in Markdown targets.
- **R4:** Support same-document fragments and duplicate heading suffixes.
- **R5:** Reject missing anchors, fragments on non-Markdown targets, malformed
  percent escapes, and anchor-validation wiring drift.
- **R6:** Keep external and protocol-relative URLs outside this offline gate.

## Implementation Units

### U1. Markdown Link Contract

Extract dependency-free local-link and heading-anchor parsing into a reusable
Ruby module under `scripts/`, preserving path normalization and URL decoding.

### U2. Contract Tests And Checker Wiring

Add focused tests for valid paths, same-file and cross-file anchors, duplicate
headings, missing anchors, non-Markdown fragments, external URLs, titles, and
malformed escaping; route `scripts/check-roadmap-docs.rb` through the module.

### U3. Documentation And Verification

Synchronize maintenance documentation, run Ruby 2.7/3.3 validation, hostile
mutations, and integrity scans, then record exact hosted evidence.

## Scope Boundaries

- Do not make network requests or validate external URL availability.
- Do not implement the full CommonMark grammar; preserve the repository's
  reviewed inline-link syntax boundary.
- Do not modify existing document headings or links except to document the
  contract.

## Verification

- `ruby scripts/test-markdown-link-contract.rb`
- `make check` locally and outside the checkout
- network-isolated Ruby 2.7.8 and Ruby 3.3.11 checks
- missing-anchor, same-file, duplicate-heading, malformed-escape,
  non-Markdown-fragment, checker-wiring, Make-wiring, documentation, status,
  and evidence mutations
- Ruby syntax, workflow YAML, protected-file, secret, artifact, and
  `git diff --check` gates

## Work Completed

Pending implementation.

## Verification Results

Pending implementation and validation; `make check` evidence will be recorded
before completion.
