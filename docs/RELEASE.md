# Release process

## Versioning

This package follows semantic versioning. Git tags use the `v*` prefix (for example `v1.0.0`).

## GitHub Release

Pushing a `v*` tag triggers `.github/workflows/release.yml`, which creates a GitHub Release using the annotated tag message when present.

## Before tagging

- Update [CHANGELOG.md](CHANGELOG.md) with user-facing changes.
- Complete the release security checklist in [SECURITY.md](SECURITY.md) (section **Release security checklist (12.4.1)**).
- Run the full local pipeline: `make release-check`.

## Maintenance

The workflow `.github/workflows/sync-releases.yml` can backfill or update GitHub Releases for existing tags.
