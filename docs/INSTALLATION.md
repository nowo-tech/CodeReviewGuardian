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

### Wrapper script updates

`code-review-guardian.sh` is installed when it does not exist. If you already have a local copy that differs from the package version, the plugin keeps your file and prints a warning.

To allow the plugin to overwrite the wrapper on every install/update, add to your project's `composer.json`:

```json
{
  "extra": {
    "code-review-guardian": {
      "auto_update_wrapper": true
    }
  }
}
```

See [UPGRADING.md](UPGRADING.md) for the 1.1.0 behavior change.

## Token for Git providers

Configure a Git provider API token (for example in `.env`) as described in [TOKEN_SETUP.md](TOKEN_SETUP.md).
