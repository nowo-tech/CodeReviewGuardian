# Installation

## Requirements

- PHP `>= 8.1` and `< 8.6`
- Composer 2.x
- Git

## Composer

Add the package as a development dependency:

```bash
composer require --dev nowo-tech/code-review-guardian
```

After installation, the Composer plugin copies framework-specific configuration, the `code-review-guardian.sh` entry script, and documentation files into your project. See [USAGE.md](USAGE.md) for how to run the guardian.

## Token for Git providers

Configure a Git provider API token (for example in `.env`) as described in [TOKEN_SETUP.md](TOKEN_SETUP.md).
