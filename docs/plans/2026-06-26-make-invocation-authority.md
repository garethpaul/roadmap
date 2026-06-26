# Make Invocation Authority

## Status: Completed

## Summary

Keep documentation verification authoritative when callers provide additional
Makefiles or GNU Make modes that suppress execution or ignore errors.

## Problem

The earlier authority suite loaded extra no-op Makefiles but did not attempt to
replace public recipes. Because the public targets used ordinary single-colon
rules, a later Makefile could replace every leaf recipe and exit zero without
running Markdown, SVG, root, or build checks. Dry-run, touch, question, and
ignore-error modes could also return a false green.

## Design

Use double-colon public targets and attach a repository-owned authority
prerequisite through secondary expansion. A later single-colon replacement is
invalid because GNU Make forbids mixing rule kinds; a later double-colon append
runs only after the authority prerequisite rejects the expanded Makefile list.
Reject caller `MAKEFLAGS` and non-executing or error-ignoring modes at parse
time. Preserve the existing recipe root guard as defense in depth.

An in-recipe-only fix was rejected because the later file can replace that
recipe. A wrapper command was rejected because it would abandon the documented
Make interface instead of fixing its ownership boundary.

## Implementation

- Converted all six public targets to double-colon rules.
- Added the `__repository-make-authority` prerequisite.
- Rejected caller flags and short/long unsafe Make modes.
- Replaced no-op later-file coverage with causal single-colon replacement and
  double-colon append markers.
- Preserved all 54 existing target, root, shell, and Ruby cases.
- Updated static contracts and repository guidance; roadmap content was unchanged.

## Verification Completed

- All 54 existing target, root, shell, and Ruby cases passed.
- Two `MAKEFILE_LIST`, one `MAKEFILES`, and one caller `MAKEFLAGS` rejection
  passed.
- Both single-colon replacement and double-colon append failed before the
  attacker marker executed.
- All ten non-executing or error-ignoring modes failed closed.
- `make check` passed from the repository root and an external hostile path.
- Ruby 2.7 and Ruby 3.3 hosted documentation matrices passed at the exact pull
  request head.
- Markdown, SVG, issue-route, shell/Ruby syntax, strict Git object,
  `git diff --check`, generated-artifact, conflict-marker, and secret-shaped
  content audits passed.
