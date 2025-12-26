# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2025-12-XX

### Added
- Initial release
- Provider-agnostic code review guardian for PHP projects
- **Multi-framework support** with automatic framework detection:
  - Symfony: Optimized configuration for Symfony projects
  - Laravel: Optimized configuration for Laravel projects
  - Generic: Works with any PHP framework
- **Automatic configuration**: Installs framework-specific configuration files
- **Code quality checks**:
  - PHP Code Style (PHP-CS-Fixer)
  - Static Analysis (PHPStan)
  - Tests (PHPUnit)
  - Security checks
- **Provider-agnostic**: Works with GitHub, GitLab, Bitbucket, and any Git hosting service
- Automatic installation via Composer plugin
- **Configurable**: Easy configuration via YAML file (`.code-review-guardian.yml`)
- Shell script (`code-review-guardian.sh`) for running code review checks
- Framework detector that reads `composer.json` to identify the framework
- Support for running individual checks or all checks at once
- Comprehensive documentation (README, CONTRIBUTING, BRANCHING, UPGRADING)
- PHPUnit tests with test fixtures
- PHP-CS-Fixer configuration (PSR-12)
- Docker and Makefile setup for development
- GitHub Actions CI/CD pipeline ready

### Features

- ✅ Works with any PHP project (Symfony, Laravel, Yii, CodeIgniter, etc.)
- ✅ Works with any Git provider (GitHub, GitLab, Bitbucket, etc.)
- ✅ Automatic framework detection
- ✅ Framework-specific configuration files
- ✅ Code style checking (PHP-CS-Fixer)
- ✅ Static analysis (PHPStan)
- ✅ Test execution (PHPUnit)
- ✅ Security checks
- ✅ Configurable via YAML
- ✅ Provider-agnostic design

