# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.2] - 2025-12-26

### Added
- Comprehensive test suite with 100% code coverage
  - 36 tests covering all code paths and edge cases
  - FrameworkDetectorTest: 15 tests covering all framework detection scenarios
  - PluginTest: 21 tests covering installation, update, uninstall, and edge cases
  - Tests for all frameworks (Symfony, Laravel, Yii, CakePHP, Laminas, CodeIgniter, Slim, Generic)
  - Tests for JSON parsing edge cases, file handling, gitignore management, and force updates
- Token setup guide (`docs/TOKEN_SETUP.md`) with step-by-step instructions for GitHub, GitLab, and Bitbucket
- Improved environment variable handling in `code-review-guardian.sh`:
  - Support for `.env` and `.env.local` files (following Symfony/Laravel convention)
  - Automatic creation of `.env` file with template if missing
  - Automatic addition of missing environment variables
  - Proper handling of quoted values and comments in `.env` files

### Changed
- Improved code documentation: All PHP code now has complete PHPDoc comments in English
- Updated GitHub Actions CI/CD pipeline to require 100% code coverage (previously 90%)
- Enhanced environment file loading order: `.env` (base) → `.env.local` (overrides, higher priority)

## [0.0.1] - 2025-12-26

### Added
- Initial release
- Provider-agnostic code review guardian for PHP projects
- **Multi-framework support** with automatic framework detection:
  - Symfony: Optimized configuration for Symfony projects
  - Laravel: Optimized configuration for Laravel projects
  - Generic: Works with any PHP framework (Yii, CakePHP, CodeIgniter, Slim, Laminas, etc.)
- **Automatic configuration**: Installs framework-specific configuration files (`.code-review-guardian.yml`)
- **Git Guardian Angel (GGA)**: Provider-agnostic code review system
  - Automatic review of pull requests and merge requests
  - Post review comments to PRs/MRs
  - Works with GitHub, GitLab, Bitbucket, and any Git hosting service
- **AI Agents support**: Configuration for AI-powered code review agents
  - Support for OpenAI, Anthropic, and GitHub Copilot
  - Configurable review scope and behavior
  - Severity thresholds and review settings
- **Git provider integration**:
  - Automatic provider detection (GitHub, GitLab, Bitbucket)
  - Token configuration via `.env` file (`GIT_TOKEN`)
  - Repository URL auto-detection
- **Documentation files**: Automatic installation of documentation
  - `docs/AGENTS.md` - Code review rules file (framework-specific, used by GGA)
  - `docs/GGA.md` - Git Guardian Angel setup guide
- **Configuration file** (`.code-review-guardian.yml`):
  - Git provider settings
  - Git Guardian Angel (GGA) configuration
  - AI Agents configuration
  - Code review rules
  - Comment settings for PRs/MRs
- Shell script (`code-review-guardian.sh`) for running code review guardian
- Framework detector that reads `composer.json` to identify the framework
- Automatic installation via Composer plugin
- Comprehensive documentation (README, CONTRIBUTING, BRANCHING, UPGRADING, CONFIGURATION)
- PHPUnit tests with comprehensive test coverage (36 tests covering all code paths)
- PHP-CS-Fixer configuration (PSR-12)
- Docker and Makefile setup for development
- GitHub Actions CI/CD pipeline with code coverage validation
- `.gitignore` automatic updates

### Features

- ✅ Works with any PHP project (Symfony, Laravel, Yii, CodeIgniter, etc.)
- ✅ Works with any Git provider (GitHub, GitLab, Bitbucket, etc.)
- ✅ Automatic framework detection from `composer.json`
- ✅ Framework-specific configuration files
- ✅ Git Guardian Angel (GGA) for automated code reviews
- ✅ AI Agents configuration (OpenAI, Anthropic, GitHub Copilot)
- ✅ Token configuration via `.env` file
- ✅ Provider-agnostic design
- ✅ Configurable via YAML
- ✅ Automatic documentation installation
- ✅ Comprehensive test suite with 100% code coverage

