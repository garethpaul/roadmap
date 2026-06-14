# Make Root Override Protection

## Status: Completed

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

## Work Completed

- Protected the Makefile-derived repository root from command-line and
  environment overrides while preserving configurable Ruby selection.
- Added an exact static declaration contract and completed-evidence checks.
- Preserved the documentation-only build boundary and all existing content,
  link, SVG, issue-template, and hosted-workflow contracts.

## Verification Results

- `ruby scripts/check-roadmap-docs.rb` and both focused contract suites passed.
- `make ROOT=/tmp check` passed while still running repository-owned scripts.
- From both the checkout and an external directory, all five public Make aliases passed.
- Ruby 2.7.8 and Ruby 3.3.11 compatibility validation passed in network-isolated,
  read-only containers.
- Six hostile mutations were rejected across root declaration, checker
  expectation, plan status, README indexing, and recorded evidence.
- Ruby syntax, workflow YAML, protected-file, secret, generated-artifact, and
  `git diff --check` gates passed before shipping.
