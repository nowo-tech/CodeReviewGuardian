# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.4] - 2025-12-26

### Improved
- Improved warning message when AI Agents are disabled
  - Changed from info to warning level for better visibility
  - Added clear instructions on how to enable AI Agents in the configuration file
  - Added link to detailed documentation: https://github.com/nowo-tech/CodeReviewGuardian/blob/main/docs/AGENTS_CONFIG.md
  - Users now get actionable guidance instead of just an informational message

## [0.0.3] - 2025-12-26

### Changed
- Renamed configuration file from `.code-review-guardian.yml` to `code-review-guardian.yaml`
  - Removed leading dot so `code-review-guardian.sh` and `code-review-guardian.yaml` appear together alphabetically
  - Changed extension from `.yml` to `.yaml` (standard YAML extension)
  - All configuration files in `config/*/` have been renamed accordingly
  - **Migration**: If you have an existing `.code-review-guardian.yml` file, you can safely rename it to `code-review-guardian.yaml`. The content remains compatible.

### Fixed
- Fixed script file (`code-review-guardian.sh`) not being copied or updated during installation and updates
  - The script now always updates on `composer install` and `composer update` to ensure users have the latest version with bug fixes and new features
  - Previously, the script would only be copied on first installation and never updated, even when updating to a newer package version
  - Updated tests to verify script updates correctly on both install and update commands

### Migration Guide (0.0.2 → 0.0.3)

If you're upgrading from version 0.0.2 or earlier:

1. **Rename your configuration file** (if you have one):
   ```bash
   # If you have .code-review-guardian.yml, rename it to code-review-guardian.yaml
   mv .code-review-guardian.yml code-review-guardian.yaml
   ```

2. **Update the package**:
   ```bash
   composer update nowo-tech/code-review-guardian
   ```

3. **Update your `.gitignore`** (if you have manual entries):
   - Remove: `.code-review-guardian.yml`
   - Ensure: `code-review-guardian.yaml` is present (automatically added during installation)

4. **Verify**:
   ```bash
   # The script should work with the new config file name
   ./code-review-guardian.sh
   ```

The configuration file format and content remain the same - only the filename changed.

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
- `.gitattributes` file to ensure proper package distribution (excludes development files)
- Explicit `files` field in `composer.json` to ensure `bin/code-review-guardian.sh`, `config/`, and `docs/GGA.md` are included in the package

### Changed
- Improved code documentation: All PHP code now has complete PHPDoc comments in English
- Updated GitHub Actions CI/CD pipeline to require 100% code coverage (previously 90%)
- Enhanced environment file loading order: `.env` (base) → `.env.local` (overrides, higher priority)

### Fixed
- Fixed package distribution: `bin/code-review-guardian.sh` is now explicitly included in the Composer package via `composer.json` `files` field
- Fixed `.gitattributes` configuration to ensure all necessary files are included while excluding development-only files

## [0.0.1] - 2025-12-26

### Added
- Initial release
- Provider-agnostic code review guardian for PHP projects
- **Multi-framework support** with automatic framework detection:
  - Symfony: Optimized configuration for Symfony projects
  - Laravel: Optimized configuration for Laravel projects
  - Generic: Works with any PHP framework (Yii, CakePHP, CodeIgniter, Slim, Laminas, etc.)
- **Automatic configuration**: Installs framework-specific configuration files (`code-review-guardian.yaml`)
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
- **Configuration file** (`code-review-guardian.yaml`):
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

