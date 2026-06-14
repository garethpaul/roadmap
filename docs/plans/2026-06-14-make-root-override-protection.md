# Make Root Override Protection

## Status: Planned

## Context

The Makefile resolves its repository root from the loaded file and uses that
path for every Ruby gate. GNU Make command-line variables outrank an ordinary
assignment, however, so `make ROOT=/tmp check` can redirect validation away
from the checkout instead of preserving the location-independent contract.

## Requirements

- **R1:** Prevent command-line and environment values from replacing the
  Makefile-derived repository root.
- **R2:** Keep the `RUBY` interpreter configurable.
- **R3:** Require the exact protected declaration in the documentation
  checker.
- **R4:** Prove every public Make alias from the checkout and an external
  directory with a hostile `ROOT` argument.
- **R5:** Preserve roadmap content, issue routing, link and SVG contracts,
  hosted workflow behavior, and documentation-only build semantics.

## Implementation Units

### U1. Protected Root

Give the repository-derived root override precedence without changing recipe
paths or configurable tools.

### U2. Static Contract

Extend the roadmap checker to reject weakened, duplicate, displaced, or
caller-controlled root declarations.

### U3. Verification

Run both contract suites, all Make aliases from root and externally, Ruby
2.7/3.3 compatibility checks, hostile mutations, and integrity screening.

## Scope Boundaries

- Do not change roadmap promises, audience, or contribution scope.
- Do not change issue-template routes, workflow actions, or Ruby lanes.
- Do not add dependencies, generated files, or network validation.

## Verification

- `ruby scripts/check-roadmap-docs.rb`
- `make check` from the checkout and an external directory
- `make ROOT=/tmp check`
- root-declaration, checker, plan-status, README-index, and evidence mutations
- Ruby syntax, workflow YAML, protected-file, secret, artifact, and
  `git diff --check` gates
