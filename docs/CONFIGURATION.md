# Configuration Guide

This document describes the configuration options available for Code Review Guardian.

## Overview

Code Review Guardian works out of the box with default settings. The configuration file (`.code-review-guardian.yml`) is **automatically generated** based on your detected framework during installation.

**Important**: The configuration file is **optional**. You only need to edit it if you want to customize the default behavior.

## Configuration File

### Location

The configuration file is automatically created at:

```
.code-review-guardian.yml
```

### Auto-Generation

The configuration file is automatically generated based on your framework:

- **Symfony**: Uses Symfony-specific configuration
- **Laravel**: Uses Laravel-specific configuration
- **Generic**: Uses generic PHP configuration

## Configuration Structure

```yaml
framework: symfony  # or laravel, generic

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
    config: phpstan.neon.dist
  
  phpunit:
    enabled: true
    config: phpunit.xml.dist
    coverage: true
    coverage_threshold: 80
  
  security_checker:
    enabled: true
  
  twig_lint:  # Symfony only
    enabled: true
    paths:
      - templates

git:
  provider: auto  # auto, github, gitlab, bitbucket
  api_token_env: GIT_TOKEN
  repository_url: auto

rules:
  block_on_style_failure: true
  block_on_test_failure: true
  block_on_coverage_drop: true
  block_on_security_issues: true

comments:
  enabled: true
  post_review_summary: true
  include_suggestions: true
  format: markdown
```

## Configuration Options

### Framework Detection

- **Type**: `string`
- **Default**: Auto-detected from `composer.json`
- **Options**: `symfony`, `laravel`, `generic`
- **Description**: The framework being used. Automatically detected during installation.

```yaml
framework: symfony
```

### Code Quality Checks

#### `php_cs_fixer`

PHP Code Style checking using PHP-CS-Fixer.

- **Type**: `object`
- **Default**: Enabled with default paths
- **Options**:
  - `enabled`: `true` or `false`
  - `config`: Path to PHP-CS-Fixer config file (default: `.php-cs-fixer.dist.php`)
  - `paths`: Array of paths to check (default: `['src', 'tests']`)

```yaml
php_cs_fixer:
  enabled: true
  config: .php-cs-fixer.dist.php
  paths:
    - src
    - tests
    - app  # Laravel
```

#### `phpstan`

Static analysis using PHPStan.

- **Type**: `object`
- **Default**: Enabled at level 5
- **Options**:
  - `enabled`: `true` or `false`
  - `level`: PHPStan level (0-9, default: 5)
  - `config`: Path to PHPStan config file (default: `phpstan.neon.dist`)

```yaml
phpstan:
  enabled: true
  level: 5
  config: phpstan.neon.dist
```

#### `phpunit`

Test execution using PHPUnit.

- **Type**: `object`
- **Default**: Enabled with coverage
- **Options**:
  - `enabled`: `true` or `false`
  - `config`: Path to PHPUnit config file (default: `phpunit.xml.dist`)
  - `coverage`: Enable code coverage (default: `true`)
  - `coverage_threshold`: Minimum coverage percentage (default: `80`)

```yaml
phpunit:
  enabled: true
  config: phpunit.xml.dist
  coverage: true
  coverage_threshold: 80
```

#### `security_checker`

Security vulnerability checking.

- **Type**: `object`
- **Default**: Enabled
- **Options**:
  - `enabled`: `true` or `false`

```yaml
security_checker:
  enabled: true
```

#### `twig_lint` (Symfony only)

Twig template linting.

- **Type**: `object`
- **Default**: Enabled for Symfony projects
- **Options**:
  - `enabled`: `true` or `false`
  - `paths`: Array of paths containing Twig templates (default: `['templates']`)

```yaml
twig_lint:
  enabled: true
  paths:
    - templates
```

### Git Provider Settings

#### `git`

Git provider configuration (for future PR/MR commenting features).

- **Type**: `object`
- **Default**: Auto-detected
- **Options**:
  - `provider`: `auto`, `github`, `gitlab`, `bitbucket` (default: `auto`)
  - `api_token_env`: Environment variable name for API token (default: `GIT_TOKEN`)
  - `repository_url`: Repository URL (default: `auto` - auto-detected from git remote)

```yaml
git:
  provider: auto
  api_token_env: GIT_TOKEN
  repository_url: auto
```

### Code Review Rules

#### `rules`

Rules for blocking merges based on check results.

- **Type**: `object`
- **Default**: All rules enabled
- **Options**:
  - `block_on_style_failure`: Block merge if code style check fails (default: `true`)
  - `block_on_test_failure`: Block merge if tests fail (default: `true`)
  - `block_on_coverage_drop`: Block merge if coverage drops below threshold (default: `true`)
  - `block_on_security_issues`: Block merge if security issues found (default: `true`)

```yaml
rules:
  block_on_style_failure: true
  block_on_test_failure: true
  block_on_coverage_drop: true
  block_on_security_issues: true
```

### Comment Settings

#### `comments`

Settings for PR/MR comments (future feature).

- **Type**: `object`
- **Default**: All options enabled
- **Options**:
  - `enabled`: Enable PR/MR comments (default: `true`)
  - `post_review_summary`: Post summary comment (default: `true`)
  - `include_suggestions`: Include suggestions in comments (default: `true`)
  - `format`: Comment format - `markdown` or `text` (default: `markdown`)

```yaml
comments:
  enabled: true
  post_review_summary: true
  include_suggestions: true
  format: markdown
```

## Framework-Specific Configurations

### Symfony

```yaml
framework: symfony

checks:
  php_cs_fixer:
    enabled: true
    paths:
      - src
      - tests
  
  twig_lint:
    enabled: true
    paths:
      - templates
```

### Laravel

```yaml
framework: laravel

checks:
  php_cs_fixer:
    enabled: true
    paths:
      - app
      - tests
  
  blade_lint:
    enabled: true
```

### Generic PHP

```yaml
framework: generic

checks:
  php_cs_fixer:
    enabled: true
    paths:
      - src
      - tests
```

## Examples

### Disable Specific Checks

```yaml
checks:
  php_cs_fixer:
    enabled: false  # Disable code style checking
  
  phpstan:
    enabled: false  # Disable static analysis
  
  phpunit:
    enabled: true
    coverage: false  # Disable coverage requirement
```

### Adjust Coverage Threshold

```yaml
checks:
  phpunit:
    enabled: true
    coverage: true
    coverage_threshold: 90  # Require 90% coverage instead of 80%
```

### Custom Paths

```yaml
checks:
  php_cs_fixer:
    enabled: true
    paths:
      - src
      - tests
      - custom/path
```

### Disable Merge Blocking Rules

```yaml
rules:
  block_on_style_failure: false  # Allow merge even if style check fails
  block_on_test_failure: true
  block_on_coverage_drop: false  # Allow merge even if coverage drops
  block_on_security_issues: true
```

## Troubleshooting

### Configuration File Not Found

If the configuration file is missing:

1. Run `composer install` to regenerate it
2. The file is automatically created based on your framework

### Framework Not Detected

If your framework is not detected:

1. Check that your framework package is in `composer.json` require or require-dev
2. The generic configuration will be used if no framework is detected
3. You can manually set `framework: generic` in the config file

### Custom Configuration Not Applied

If your custom configuration is not being used:

1. Check the file location: `.code-review-guardian.yml` in project root
2. Verify YAML syntax is correct
3. Check for typos in configuration keys

## Validation

The configuration file is validated when the script runs:

- Invalid YAML syntax will cause an error
- Unknown configuration keys are ignored (with a warning in the future)
- Missing required tools (PHP-CS-Fixer, PHPStan, PHPUnit) are handled gracefully

## Getting Help

For issues with configuration:

1. Check this documentation
2. Review the [README](../README.md) for usage examples
3. Open an issue on GitHub with:
   - Your configuration file (remove sensitive data)
   - Framework being used
   - Error messages
   - Steps to reproduce

