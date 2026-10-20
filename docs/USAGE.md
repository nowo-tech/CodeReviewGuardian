# Usage

## Table of contents

- [Run code review](#run-code-review)
- [Post a review comment (when available)](#post-a-review-comment-when-available)
- [Help](#help)
- [Configuration](#configuration)
- [Git Guardian Angel (GGA)](#git-guardian-angel-gga)

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
