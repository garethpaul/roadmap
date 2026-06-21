# Safe Make Authority

## Status: Completed

## Context

The Make root used `lastword`, so checkout paths containing spaces were split.
Caller-controlled `MAKEFILE_LIST`, `MAKEFILES`, `ROOT`, `RUBY`, `SHELL`, and
`.SHELLFLAGS` could also redirect or influence documentation verification.

## Scope Boundaries

- Do not change roadmap promises, scope, issue routes, Markdown links, overview
  SVG semantics, workflow lanes, or documentation-only build behavior.
- Preserve dependency-free Ruby 2.7/3.3 validation.
- Do not add package dependencies, generated artifacts, or network checks.

## Work Completed

- Canonicalize the checked-in Makefile through quoted POSIX tools without
  splitting spaces or interpreting shell-sensitive checkout names.
- Freeze Ruby and shell authority and export the canonical root as data.
- Reject both `MAKEFILE_LIST` replacement channels, `MAKEFILES` preloads, and
  ambiguous multiple-`-f` invocations before a quality command runs.
- Add an executable dependency-free root suite to `make verify` and `make check`.

## Verification Completed

- Ruby 2.7.0 and hosted Ruby 3.3 passed `make check` from the repository root
  and an unrelated directory.
- All 54 executed target, root, shell, and Ruby authority cases passed from a
  path containing spaces, quotes, brackets, an apostrophe, and backticks.
- Both `MAKEFILE_LIST` override channels, a `MAKEFILES` preload, and an
  ambiguous multiple-Makefile invocation failed closed.
- Roadmap docs, Markdown links and anchors, overview SVG contracts, issue
  routes, Ruby/shell syntax, `git diff --check`, and strict Git object validation passed.
