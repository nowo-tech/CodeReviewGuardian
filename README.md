# Code Review Guardian

[![CI](https://github.com/nowo-tech/code-review-guardian/actions/workflows/ci.yml/badge.svg)](https://github.com/nowo-tech/code-review-guardian/actions/workflows/ci.yml) [![Latest Stable Version](https://poser.pugx.org/nowo-tech/code-review-guardian/v)](https://packagist.org/packages/nowo-tech/code-review-guardian) [![License](https://poser.pugx.org/nowo-tech/code-review-guardian/license)](https://packagist.org/packages/nowo-tech/code-review-guardian) [![PHP Version Require](https://poser.pugx.org/nowo-tech/code-review-guardian/require/php)](https://packagist.org/packages/nowo-tech/code-review-guardian) [![GitHub stars](https://img.shields.io/github/stars/nowo-tech/code-review-guardian.svg?style=social&label=Star)](https://github.com/nowo-tech/code-review-guardian)

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
- ✅ **Code quality checks**:
  - PHP Code Style (PHP-CS-Fixer)
  - Static Analysis (PHPStan)
  - Tests (PHPUnit)
  - Security checks
- ✅ **Provider-agnostic**: Works with GitHub, GitLab, Bitbucket, and any Git hosting service
- ✅ Automatic installation via Composer plugin
- ✅ **Configurable**: Easy configuration via YAML file

## Installation

```bash
composer require --dev nowo-tech/code-review-guardian
```

After installation, the following files will be copied to your project root:
- `code-review-guardian.sh` - The main script for running code review checks
- `.code-review-guardian.yml` - Configuration file (framework-specific)

**Note:** These files are automatically added to your `.gitignore` during installation to prevent them from being committed to your repository.

## Usage

### Run all checks

```bash
./code-review-guardian.sh
```

This will run all available checks:
- Code style (PHP-CS-Fixer)
- Static analysis (PHPStan)
- Tests (PHPUnit)
- Security checks

### Run specific checks

```bash
# Only code style
./code-review-guardian.sh --check-style

# Only static analysis
./code-review-guardian.sh --check-static

# Only tests
./code-review-guardian.sh --check-tests

# Only security checks
./code-review-guardian.sh --check-security

# Run multiple specific checks
./code-review-guardian.sh --check-style --check-tests
```

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

Configuration is stored in `.code-review-guardian.yml`. The file is automatically generated based on your detected framework.

### Symfony Configuration Example

```yaml
framework: symfony

checks:
  php_cs_fixer:
    enabled: true
    config: .php-cs-fixer.dist.php
    paths:
      - src
      - tests
  phpstan:
    enabled: true
    level: 5
  phpunit:
    enabled: true
    coverage: true
    coverage_threshold: 80
  twig_lint:
    enabled: true
```

### Laravel Configuration Example

```yaml
framework: laravel

checks:
  php_cs_fixer:
    enabled: true
    config: .php-cs-fixer.dist.php
    paths:
      - app
      - tests
  blade_lint:
    enabled: true
```

### Customizing Configuration

You can edit `.code-review-guardian.yml` to customize the checks and thresholds according to your project needs.

## Git Provider Support

Code Review Guardian is **provider-agnostic** and works with:

- **GitHub** (GitHub Actions, Pull Requests)
- **GitLab** (GitLab CI, Merge Requests)
- **Bitbucket** (Bitbucket Pipelines, Pull Requests)
- **Any Git hosting service** with standard Git operations

The package automatically detects your Git provider from your repository URL.

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
git clone https://github.com/nowo-tech/code-review-guardian.git
cd code-review-guardian

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

