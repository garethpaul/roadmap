# roadmap

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/roadmap` is a public sample, documentation, or utility project. The checked-in files describe a public sample, documentation, or utility project with the structure summarized below.

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `main` branch. The project language mix found during review was: no dominant source language detected.

## Repository Contents

- `README.md` - project overview and local usage notes
- `CHANGES.md` - maintenance history for documentation integrity checks
- `Makefile` - local verification entry points
- `docs/plans` - completed maintenance plans for the current baseline
- `plans` - historical implementation notes
- `scripts` - documentation integrity validators
- `.github` - source or example code
- `SCOPE.md` - explicit placeholder scope and non-commitment guidance
- `SECURITY.md` - security reporting and disclosure guidance
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: .github
- Dependency and build manifests: none detected
- Entry points or build surfaces: none detected
- Test-looking files: no obvious test files detected

## Getting Started

### Prerequisites

- Git

### Setup

```bash
git clone https://github.com/garethpaul/roadmap.git
cd roadmap
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

## Running or Using the Project

- Start with `SCOPE.md` and `VISION.md`. This repository is a placeholder and does not define active roadmap commitments.
- No active roadmap commitments are defined. Do not treat this repository as an
  active delivery plan until owner, audience, timeframe, and commitment level
  are documented.

## Testing and Verification

- `make check` runs the documentation integrity checks for this placeholder repository.
- The integrity checker also requires completed canonical plans under `docs/plans`.
- The integrity checker keeps the overview SVG aligned with the placeholder and
  non-commitment language.
- The integrity checker keeps `VISION.md` aligned with the same no-commitment
  language as `README.md` and `SCOPE.md`.
- The integrity checker keeps `SECURITY.md` explicit that security reports are
  not roadmap commitments.
- The integrity checker keeps the `SCOPE.md` prerequisite checklist aligned on
  roadmap type, owner, audience, timeframe, and commitment level.
- The integrity checker requires README coverage for
  `.github/ISSUE_TEMPLATE/config.yml`, where blank issues disabled remains the
  expected policy until roadmap scope is defined.
- The integrity checker requires the issue-template contact links to include
  the repository security policy and `SCOPE.md`, with unique names and URLs.
- The integrity checker requires README maintenance notes to reference every
  canonical plan under `docs/plans`.

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- No required secret or credential file was identified in the repository scan. If you add integrations later, keep secrets out of git.

## Security and Privacy Notes

- Review changes touching issue templates or contact links; keep them scoped to this repository until the roadmap purpose is defined.

## Maintenance Notes

- See `SCOPE.md` before adding roadmap content or templates.
- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.
- See `docs/plans/2026-06-08-roadmap-baseline.md` for the canonical
  documentation-only baseline.
- See `docs/plans/2026-06-08-readme-scope-guard.md` for the README
  non-commitment language guard.
- See `docs/plans/2026-06-08-overview-placeholder-guard.md` for the overview
  placeholder language guard.
- See `docs/plans/2026-06-09-vision-scope-guard.md` for the VISION
  non-commitment guard.
- See `docs/plans/2026-06-09-readme-issue-template-guard.md` for the README
  issue-template policy guard.
- See `docs/plans/2026-06-09-scope-audience-guard.md` for the scope audience
  prerequisite guard.
- See `docs/plans/2026-06-09-readme-plan-index-guard.md` for the README
  maintenance plan index guard.
- See `docs/plans/2026-06-09-issue-template-contact-links.md` for the
  issue-template contact-link guard.
- See `docs/plans/2026-06-09-security-no-commitment-guard.md` for the
  security-policy no-commitment guard.
- See `docs/plans/2026-06-09-scope-prerequisite-checklist-guard.md` for the
  full scope prerequisite checklist guard.
- See `docs/plans/2026-06-10-issue-template-contact-link-uniqueness.md` for
  the contact-link uniqueness guard.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
