# Credential-Free Roadmap Document Validation

Status: Completed

## Context

The roadmap repository is documentation-only, but its hosted validation still
handles a GitHub token and depends on the runner Ruby. The local checker also
needs to reject unsafe workflow drift and tracked machine-local metadata.

## Work Completed

- Added an exact GitHub Actions contract for Ruby 2.7 and Ruby 3.3 on a fixed
  Ubuntu runner with pinned actions and read-only permissions.
- Disabled persisted checkout credentials and kept the workflow free of
  repository secrets and package installation.
- Added local secret/editor/dependency exclusions and fail-closed tracked-file
  inspection with a safe `.env.example` exception.
- Required one unambiguous completed status in every canonical plan.
- Kept contributor, security, vision, changelog, and README guidance aligned.

## Verification

- `ruby -c scripts/check-roadmap-docs.rb`
- `ruby scripts/check-roadmap-docs.rb`
- `make check`
- Ruby 2.7 and Ruby 3.3 validation
- hostile workflow, plan, metadata, and issue-route mutations
- `git diff --check`
