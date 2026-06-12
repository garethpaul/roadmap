# Changes

## 2026-06-10

- Added pinned, least-privilege GitHub Actions validation for the roadmap
  documentation contract.
- Added explicit Ruby 2.7 and Ruby 3.3 coverage, disabled persisted checkout
  credentials, and enforced the complete reviewed workflow contract.
- Added local secret/editor exclusions and fail-closed tracked-metadata checks.
- Made `make check` independent of the caller's current directory.
- Added fail-closed checks for the hosted workflow and completed plan.
- Added issue-template contact-link uniqueness checks so duplicate names or
  URLs cannot create ambiguous repository support routes.
- Restricted placeholder issue-template contact routes to the approved
  Security Policy and Repository Scope links.

## 2026-06-09

- Required the full `SCOPE.md` prerequisite checklist to stay aligned before
  roadmap content is added.
- Added security-policy no-commitment language and validator coverage so
  vulnerability reporting does not imply roadmap delivery commitments.
- Required repository-scoped issue-template contact links for the security
  policy and `SCOPE.md`.
- Added README plan-index validation so every canonical maintenance plan stays
  discoverable and stale plan links fail the docs check.
- Added an audience prerequisite to `SCOPE.md` and validator coverage so scope
  requirements stay aligned with README.
- Added README issue-template policy coverage so maintainers can find
  `.github/ISSUE_TEMPLATE/config.yml` and keep blank issues disabled until
  roadmap scope is defined.
- Added VISION-level non-commitment language and validator coverage so README,
  SCOPE, and VISION stay aligned on placeholder status.

## 2026-06-08

- Aligned the README overview SVG with the placeholder scope and added
  validator coverage for overview non-commitment language.
- Added README-level non-commitment language and validator coverage so the
  public entrypoint mirrors `SCOPE.md`.
- Added `make check` as the shared repository verification alias.
- Added a documentation integrity check for roadmap scope, required docs, and
  issue-template contact links.
- Replaced copied Twilio/support issue-template links with repository-scoped
  roadmap links and disabled blank issues until scope is defined.
- Removed stale integration claims from the README and overview image.
- Documented `make verify` as the documentation verification command.
- Added `SCOPE.md` with explicit placeholder and non-commitment guidance, plus
  integrity checks that require README and issue-template scope links.
- Added canonical `docs/plans` coverage and made the documentation checker
  require completed plans.
