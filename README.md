# Code Review Guardian

[![CI](https://github.com/nowo-tech/CodeReviewGuardian/actions/workflows/ci.yml/badge.svg)](https://github.com/nowo-tech/CodeReviewGuardian/actions/workflows/ci.yml) [![Latest Stable Version](https://poser.pugx.org/nowo-tech/code-review-guardian/v)](https://packagist.org/packages/nowo-tech/code-review-guardian) [![License](https://poser.pugx.org/nowo-tech/code-review-guardian/license)](https://packagist.org/packages/nowo-tech/code-review-guardian) [![PHP Version Require](https://poser.pugx.org/nowo-tech/code-review-guardian/require/php)](https://packagist.org/packages/nowo-tech/code-review-guardian) [![GitHub stars](https://img.shields.io/github/stars/nowo-tech/CodeReviewGuardian.svg?style=social&label=Star)](https://github.com/nowo-tech/CodeReviewGuardian)

> ⭐ **Found this project useful?** Give it a star on GitHub! It helps us maintain and improve the project.

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
- `code-review-guardian.sh` - Minimal entry point script (project root, ~40 lines)
  - **Automatically updated** on every `composer install` and `composer update`
  - Acts as a lightweight wrapper that delegates to the implementation in `vendor/`
  - Automatically detects vendor directory and executes the main script
- `code-review-guardian.yaml` - Configuration file (framework-specific, project root)
  - Only installed if it doesn't exist (to preserve your customizations)
- `docs/AGENTS.md` - Code review rules file (framework-specific, used by GGA)
- `docs/GGA.md` - Git Guardian Angel setup guide

**Note:** The actual implementation code runs from `vendor/nowo-tech/code-review-guardian/bin/`, keeping your project root clean and minimal.

**Note:** Script and config files are automatically added to your `.gitignore` during installation.

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
  api_token_env: GIT_TOKEN  # Reads from .env file
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

- PHP >= 7.4
- Composer 2.x
- Git

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
| `make test-coverage` | Run tests with code coverage |
| `make cs-check` | Check code style (PSR-12) |
| `make cs-fix` | Fix code style |
| `make qa` | Run all QA checks |
| `make clean` | Remove vendor and cache |
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

## Contributing

Please see [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for details on how to contribute to this project.

For branching strategy, see [docs/BRANCHING.md](docs/BRANCHING.md).

## Changelog

Please see [docs/CHANGELOG.md](docs/CHANGELOG.md) for version history.

## Upgrading

Please see [docs/UPGRADING.md](docs/UPGRADING.md) for upgrade instructions and migration notes.

## Documentation

- **[Configuration Guide](docs/CONFIGURATION.md)** - Detailed configuration options and examples
- **[Contributing Guide](docs/CONTRIBUTING.md)** - How to contribute to the project
- **[Branching Strategy](docs/BRANCHING.md)** - Git workflow and branching policies
- **[Changelog](docs/CHANGELOG.md)** - Version history and changes

## Related Packages

### Composer Update Helper

Want to keep your dependencies up to date? Check out **[Composer Update Helper](https://github.com/nowo-tech/composer-update-helper)** - a perfect complement to Code Review Guardian:

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

## License

The MIT License (MIT). Please see [LICENSE](LICENSE) for more information.

