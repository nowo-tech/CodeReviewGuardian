# Usage

## Run code review

From the project root:

```bash
./code-review-guardian.sh
```

This validates configuration, applies file filters, and prepares the review workflow.

## Post a review comment (when available)

```bash
./code-review-guardian.sh --post-comment
```

## Help

```bash
./code-review-guardian.sh --help
```

## Configuration

See [CONFIGURATION.md](CONFIGURATION.md) for YAML options and framework-specific examples.

## Git Guardian Angel (GGA)

See [GGA.md](GGA.md) for the provider-agnostic review workflow.
