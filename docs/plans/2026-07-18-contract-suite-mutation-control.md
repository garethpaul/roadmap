# Contract Suite Mutation Control

## Status: Completed

## Summary

Observe the documentation contract suites actually rejecting defects, instead of
only proving that guard source text and test names exist in the tree.

## Problem

`scripts/check-roadmap-docs.rb` defended the contract libraries with source-text
pins and pinned the names of the 71 tests that cover them. Both are presence
checks. Presence cannot prove that the test defending a guard still asserts
anything.

Appending a no-op override of the Minitest assertion methods to
`scripts/test-markdown-link-contract.rb` kept every pinned test name
byte-identical and left the reported result at `0 failures`. With the assertion
mechanism neutered, deleting the symlinked-path-component guard from
`scripts/markdown-link-contract.rb` -- a guard no pin covers, defended only by
`test_rejects_targets_reached_through_symlinked_directories` -- still produced
`Roadmap documentation checks passed` and `make check` exit 0. The suite reported
`77 runs, 0 assertions, 0 failures`: the assertion count had collapsed from 144
to 0 and nothing compared it against anything.

`scripts/test-makefile-root.sh` already plants hostile Makefiles out of band and
asserts the resulting diagnostics, so Make authority was measured rather than
asserted. The contract libraries had no equivalent control: nothing planted a
defect into `scripts/markdown-link-contract.rb` or
`scripts/overview-svg-contract.rb` and re-ran the suite. The evidence sentences
pinned in the plan documents, such as `rejected all twelve hostile mutations`
for the Markdown anchor work, therefore required a plan document to record that
mutations had been rejected without any harness reproducing that rejection.

## Design

Add `scripts/test-contract-mutations.rb`, an out-of-band planted-defect control
reached by `make check` through the existing `test` target. It copies the
repository to a temporary directory, plants a defect the shipped suites are
expected to reject, runs the real suite against the copy, and fails when the
suite still passes.

The control is fail-closed by construction rather than by pinning. A neutered
assertion mechanism makes a suite pass unconditionally, so every planted defect
survives and the harness fails. This holds even when the reported assertion count
is forged, which a count threshold alone cannot detect.

Three supporting controls keep a false green from masquerading as detection:

- A clean-tree control runs each suite unmutated first, so a suite that fails for
  an unrelated reason cannot be mistaken for universal detection.
- The clean-tree control also rejects a suite reporting fewer runs or assertions
  than observed today, which catches assertion shadowing directly.
- Each mutation must match exactly one occurrence and must be proven to alter the
  file, so a stale pattern can never be mistaken for a suite that detected a
  defect that was never planted.

Only guards that `scripts/check-roadmap-docs.rb` does not pin as source text are
planted, so each case measures the suite rather than the static checker. A
count threshold alone was rejected because a forged counter defeats it. Extending
the source-text pins was rejected because that deepens the presence check that
failed.

Two candidate mutations were measured and deliberately excluded because they are
behaviourally equivalent rather than defects, and would have produced a spurious
failure:

- Reducing `target.file? && !target.symlink?` to `target.file?`. `exact_path?`
  already rejects a symlinked final component, so the second test is redundant
  defense in depth and removing it changes nothing.
- Comparing link path casing case-insensitively. On a case-sensitive filesystem
  `target.file?` already rejects a wrong-case target, so the case-exactness guard
  only decides on case-insensitive filesystems and hosted Linux validation cannot
  observe it.

## Implementation

- Added `scripts/test-contract-mutations.rb` with a clean-tree control, suite
  runs/assertion floors, and five hostile mutations spanning the Markdown link
  contract and the overview SVG contract.
- Invoked the harness from the `test` target so `make check` and hosted
  validation reach it, leaving the 54-case authority matrix unchanged.
- Pinned the harness invocation and its fail-closed logic in
  `scripts/check-roadmap-docs.rb`, including a minimum mutation count.
- Used plain exit codes rather than Minitest so the control cannot be disabled by
  the same assertion shadowing it detects.
- Roadmap content was unchanged.

## Verification Completed

- `make check` passed from the repository root; the harness reported two
  clean-tree suite controls and five hostile mutations rejected.
- Each of the five mutations was confirmed to fail the shipped suite
  individually; the harness reports `hostile mutation survived` otherwise.
- Deleting the symlinked-path-component guard alone failed `make check` with exit
  2 before this change, confirming the suites are real and load-bearing.
- Assertion shadowing that kept all 71 pinned test names passed `make check` with
  exit 0 before this change and fails with exit 2 after it.
- Assertion shadowing with a forged assertion counter of 1060 defeated the
  count floor and was still rejected by construction, because every planted
  defect survived.
- All 54 existing target, root, shell, and Ruby authority cases passed.
- The Markdown and SVG suites passed at 77 runs with 144 assertions and 7 runs
  with 57 assertions.
- Hosted Ruby 2.7 and Ruby 3.3 matrices were not run locally; the harness avoids
  syntax newer than Ruby 2.7 and relies only on `fileutils`, `open3`,
  `pathname`, `rbconfig`, and `tmpdir`.
