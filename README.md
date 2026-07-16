# Code Review Guardian

[![CI](https://github.com/nowo-tech/CodeReviewGuardian/actions/workflows/ci.yml/badge.svg)](https://github.com/nowo-tech/CodeReviewGuardian/actions/workflows/ci.yml) [![Packagist Version](https://img.shields.io/packagist/v/nowo-tech/code-review-guardian.svg?style=flat)](https://packagist.org/packages/nowo-tech/code-review-guardian) [![Packagist Downloads](https://img.shields.io/packagist/dt/nowo-tech/code-review-guardian.svg)](https://packagist.org/packages/nowo-tech/code-review-guardian) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![PHP](https://img.shields.io/badge/PHP-8.1%2B-777BB4?logo=php)](https://php.net) [![Symfony](https://img.shields.io/badge/Symfony-6.0%2B%20%7C%207.4%2B%20%7C%208.0%20%7C%208.1%2B-000000?logo=symfony)](https://symfony.com)

> ⭐ **Found this useful?** Install from [Packagist](https://packagist.org/packages/nowo-tech/code-review-guardian) and give the repository a star on [GitHub](https://github.com/nowo-tech/CodeReviewGuardian) if it helps your workflow.

## Documentation


- [GitHub Actions CI requirements](docs/GITHUB_CI.md)
- [Installation](docs/INSTALLATION.md)
- [Configuration](docs/CONFIGURATION.md)
- [Usage](docs/USAGE.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Changelog](docs/CHANGELOG.md)
- [Upgrading](docs/UPGRADING.md)
- [Release](docs/RELEASE.md)
- [Security](docs/SECURITY.md)
- [Engram](docs/ENGRAM.md)
- [Spec-driven development](docs/SPEC-DRIVEN-DEVELOPMENT.md)
- [GitHub Spec Kit](docs/SPEC-KIT.md)

### Additional documentation

- [Token setup](docs/TOKEN_SETUP.md)
- [Git Guardian Angel (GGA)](docs/GGA.md)
- [AI agents configuration](docs/AGENTS_CONFIG.md)
- [Branching strategy](docs/BRANCHING.md)

Provider-agnostic code review guardian for PHP projects. Works with any PHP project: **Symfony**, **Laravel**, **Yii**, **CodeIgniter**, **Slim**, **Laminas**, etc. and any Git provider: **GitHub**, **GitLab**, **Bitbucket**, etc.

## Features

- ✅ Works with any PHP project
- ✅ Works with any Git provider (GitHub, GitLab, Bitbucket, etc.)
- ✅ **Multi-framework support** with automatic framework detection:
 - **Symfony**: Optimized configuration for Symfony projects
 - **Laravel**: Optimized configuration for Laravel projects
 - **Generic**: Works with any PHP framework
- ✅ **Automatic configuration**: Installs framework-specific configuration files
- ✅ **Git Guardian Angel (GGA)**: Provider-agnostic code review system
- ✅ **AI Agents support**: Configure AI-powered code review agents (OpenAI, Anthropic, GitHub Copilot)
- ✅ **Provider-agnostic**: Works with GitHub, GitLab, Bitbucket, and any Git hosting service
- ✅ Automatic installation via Composer plugin
- ✅ **Configurable**: Easy configuration via YAML file

## Installation

```bash
composer require --dev nowo-tech/code-review-guardian
```

After installation, the following files will be copied to your project:
- `code-review-guardian.sh` - Minimal entry point script (project root; about **40** lines — exact count may change between releases)
 - Installed when missing; if a local copy differs from the package, it is left unchanged and a warning is shown
 - To overwrite automatically on install/update, set `extra.code-review-guardian.auto_update_wrapper` to `true` in your project's `composer.json`
 - Acts as a lightweight wrapper that delegates to the implementation in `vendor/`
 - Automatically detects vendor directory and executes the main script
- `code-review-guardian.yaml` - Configuration file (framework-specific, project root)
 - Only installed if it doesn't exist (to preserve your customizations)
- `docs/AGENTS.md` - Code review rules file (framework-specific, used by GGA)
- `docs/GGA.md` - Git Guardian Angel setup guide

**Note:** The actual implementation code runs from `vendor/nowo-tech/code-review-guardian/bin/`, keeping your project root clean and minimal.

**Note:** The wrapper script and `code-review-guardian.yaml` are added to your `.gitignore` during installation (files under `docs/` installed by the plugin are not ignored automatically).

### Removing the package

When you run `composer remove nowo-tech/code-review-guardian`, the plugin removes `code-review-guardian.sh`, `code-review-guardian.yaml`, and `docs/AGENTS.md`, and cleans the Code Review Guardian block from `.gitignore`. **`docs/GGA.md` is not removed** — delete it manually if you no longer need it.

### Environment Configuration

Code Review Guardian requires a Git provider API token for posting review comments. Add it to your `.env` file:

```env
# Git Provider API Token (required for PR/MR comments)
GIT_TOKEN=your_github_or_gitlab_token_here
```

See [`docs/TOKEN_SETUP.md`](docs/TOKEN_SETUP.md) for detailed step-by-step instructions on creating accounts and obtaining tokens for GitHub, GitLab, and Bitbucket.

## Current Status

Code Review Guardian provides a complete infrastructure for code review automation:

- ✅ **Fully Implemented:**
 - Composer plugin (automatic installation)
 - Automatic framework detection
 - Configuration file installation
 - Dependency validation script
 - YAML configuration parsing and loading
 - File filtering according to configured patterns
 - Rules file reading (AGENTS.md)

- 🚧 **In Development:**
 - Full integration with AI APIs (OpenAI, Anthropic, GitHub Copilot)
 - Actual code review execution using AI models
 - Automatic comment posting to PR/MR
 - Automatic Git provider detection from URL

The script currently validates configuration, filters files correctly, and is ready for AI API integration. Full review functionality is under active development.

## Usage

### Run code review

```bash
./code-review-guardian.sh
```

This will validate configuration, filter files according to your settings, and prepare for code review. Full AI-powered review integration is in active development.

### Post review comment to PR/MR

```bash
./code-review-guardian.sh --post-comment
```

This functionality is currently in development. It will post review comments to your pull request or merge request using the Git provider API once fully implemented.

### Show help

```bash
./code-review-guardian.sh --help
```

## Framework Detection

The package **automatically detects** your framework and installs the appropriate configuration:

| Framework | Detection | Configuration |
|-----------|-----------|---------------|
| **Symfony** | `symfony/framework-bundle` | ✅ Symfony-specific |
| **Laravel** | `laravel/framework` | ✅ Laravel-specific |
| **Yii** | `yiisoft/yii2` or `yiisoft/yii` | ✅ Generic |
| **CakePHP** | `cakephp/cakephp` | ✅ Generic |
| **Laminas** | `laminas/laminas-mvc` | ✅ Generic |
| **CodeIgniter** | `codeigniter4/framework` | ✅ Generic |
| **Slim** | `slim/slim` | ✅ Generic |
| **Other** | Not detected | ✅ Generic |

## Configuration

Configuration is stored in `code-review-guardian.yaml`. The file is automatically generated based on your detected framework.

### Symfony Configuration Example

```yaml
framework: symfony

git:
 provider: auto
 api_token_env: GIT_TOKEN

gga:
 enabled: true
 auto_review: true
 post_comments: true

agents:
 enabled: false
 provider: openai
 model: gpt-4
```

### Laravel Configuration Example

```yaml
framework: laravel

git:
 provider: auto
 api_token_env: GIT_TOKEN

gga:
 enabled: true
 auto_review: true
 post_comments: true

agents:
 enabled: false
 provider: openai
 model: gpt-4
```

### Git Provider Token Configuration

The configuration file references a token from your `.env` file:

```yaml
git:
 api_token_env: GIT_TOKEN # Reads from .env file
```

Make sure to add your token to `.env`:

```env
GIT_TOKEN=your_token_here
```

See `docs/GGA.md` for provider-specific setup instructions.

### Customizing Configuration

You can edit `code-review-guardian.yaml` to customize Git Guardian Angel settings, AI agents configuration, and review rules according to your project needs.

### AI Agents and Git Guardian Angel

Code Review Guardian supports AI-powered code review agents:

- **`docs/AGENTS.md`** - Code review rules file (framework-specific, automatically installed based on detected framework)
- **`docs/GGA.md`** - Complete setup guide for Git Guardian Angel (provider-agnostic code review system)

For detailed AI agent configuration instructions, see the package documentation in `vendor/nowo-tech/code-review-guardian/docs/AGENTS_CONFIG.md` or check the [Configuration Guide](docs/CONFIGURATION.md) in the repository.

## Git Provider Support

Code Review Guardian is **provider-agnostic** and works with:

- **GitHub** (GitHub Actions, Pull Requests)
- **GitLab** (GitLab CI, Merge Requests)
- **Bitbucket** (Bitbucket Pipelines, Pull Requests)
- **Any Git hosting service** with standard Git operations

Git provider detection is planned for a future release. Currently, you can configure the provider manually in the configuration file.

## Requirements

- PHP >= 8.1 (see `composer.json` for the exact range)
- Composer 2.x
- Git

## Version information

Supported PHP ranges and dependencies are defined in [`composer.json`](composer.json). Release history and migration notes are in [`docs/CHANGELOG.md`](docs/CHANGELOG.md).

## Development

### Using Docker (Recommended)

The project includes Docker configuration for easy development:

```bash
# Start the container
make up

# Install dependencies
make install

# Run tests
make test

# Run tests with coverage
make test-coverage

# Check code style
make cs-check

# Fix code style
make cs-fix

# Run all QA checks
make qa

# Open shell in container
make shell

# Stop container
make down

# Clean build artifacts
make clean
```

### Without Docker

If you have PHP and Composer installed locally:

```bash
# Clone repository
git clone https://github.com/nowo-tech/CodeReviewGuardian.git
cd CodeReviewGuardian

# Install dependencies
composer install

# Run tests
composer test

# Run tests with coverage
composer test-coverage

# Check code style
composer cs-check

# Fix code style
composer cs-fix

# Run all QA checks
composer qa
```

### Available Make Commands

| Command | Description |
|---------|-------------|
| `make up` | Start Docker container |
| `make down` | Stop Docker container |
| `make shell` | Open shell in container |
| `make install` | Install Composer dependencies |
| `make test` | Run PHPUnit tests |
| `make test-coverage` | Run tests with coverage and print the PHP Lines coverage line |
| `make cs-check` | Check code style (PHP-CS-Fixer) |
| `make cs-fix` | Fix code style |
| `make rector` / `make rector-dry` | Run Rector (apply or dry-run) |
| `make phpstan` | Run PHPStan |
| `make qa` | Run `cs-check` and tests |
| `make release-check` | Full pre-release pipeline (see Makefile) |
| `make composer-sync` | Validate `composer.json` and install dependencies in the container |
| `make clean` | Remove vendor, cache, and coverage artifacts |
| `make setup-hooks` | Install git pre-commit hooks |

## Continuous Integration

The package can be integrated into your CI/CD pipeline. Example for GitHub Actions:

```yaml
name: Code Review

on: [pull_request]

jobs:
 code-review:
  runs-on: ubuntu-latest
  steps:
   - uses: actions/checkout@v3
   - uses: php-actions/composer@v6
   - run: composer require --dev nowo-tech/code-review-guardian
   - run: ./code-review-guardian.sh
```

## Related Packages

### Composer Update Helper

Want to keep your dependencies up to date? Check out **[Composer Update Helper](https://github.com/nowo-tech/ComposerUpdateHelper)** - a perfect complement to Code Review Guardian:

- ✅ **Works with any PHP project**: Symfony, Laravel, Yii, CodeIgniter, etc.
- ✅ **Multi-framework support**: Automatic framework detection and version constraints
- ✅ **Smart updates**: Generates `composer require` commands from outdated dependencies
- ✅ **Release information**: Shows GitHub release links and changelogs
- ✅ **YAML configuration**: Easy-to-use configuration format

```bash
composer require --dev nowo-tech/composer-update-helper
```

Together with Code Review Guardian, you get a complete development workflow:
1. **Composer Update Helper** keeps your dependencies up to date
2. **Code Review Guardian** ensures code quality in your pull requests

## Author

Created by [Héctor Franco Aceituno](https://github.com/HecFranco) at [Nowo.tech](https://nowo.tech)

## Tests and coverage

- Tests: PHPUnit (unit and integration suites)
- PHP: 100%
- TS/JS: N/A
- Python: N/A

## License

The MIT License (MIT). Please see [LICENSE](LICENSE) for more information.

