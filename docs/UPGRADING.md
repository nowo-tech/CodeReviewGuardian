# Upgrading Guide

This guide will help you upgrade Code Review Guardian to newer versions.

## General Upgrade Process

1. **Update the package**:
   ```bash
   composer update nowo-tech/code-review-guardian
   ```

2. **Review the CHANGELOG**:
   Check [CHANGELOG.md](CHANGELOG.md) for breaking changes and new features.

3. **Update your configuration** (if needed):
   The `.code-review-guardian.yml` configuration file is automatically updated during installation.
   If you have custom modifications, you may need to review and update them.

4. **Update the script** (if needed):
   The `code-review-guardian.sh` script is automatically updated during installation.
   If you have custom modifications, you may need to reapply them.

## Version-Specific Upgrade Notes

### Upgrading to 0.0.1+

This is the initial release. If you're installing for the first time, follow the installation instructions in the README.

#### New Features

- Provider-agnostic code review guardian
- Automatic framework detection
- Framework-specific configuration files
- Multiple code quality checks (PHP-CS-Fixer, PHPStan, PHPUnit, Security)

#### Breaking Changes

- None (initial release)

#### Migration Steps

1. Install the package:
   ```bash
   composer require --dev nowo-tech/code-review-guardian
   ```

2. The package will automatically:
   - Detect your framework
   - Install the appropriate configuration file (`.code-review-guardian.yml`)
   - Install the code review script (`code-review-guardian.sh`)
   - Update your `.gitignore` file

3. Run the code review guardian:
   ```bash
   ./code-review-guardian.sh
   ```

4. Customize the configuration file if needed:
   ```bash
   # Edit .code-review-guardian.yml to customize checks and thresholds
   nano .code-review-guardian.yml
   ```

## Troubleshooting

### Script not found after upgrade

If the script is missing after upgrading:

```bash
composer install
```

This will reinstall the script files.

### Permission errors

If you get permission errors:

```bash
chmod +x code-review-guardian.sh
```

### Configuration file not found

If the configuration file is missing:

1. Check if the framework was detected correctly:
   ```bash
   # The plugin should show: "Detected framework: SYMFONY" (or LARAVEL, etc.)
   composer install
   ```

2. If the framework was not detected, the generic configuration will be used.

3. You can manually create a configuration file:
   ```bash
   # Copy from the package
   cp vendor/nowo-tech/code-review-guardian/config/generic/.code-review-guardian.yml .code-review-guardian.yml
   ```

### Conflicts with custom modifications

If you've modified the script or configuration and it conflicts with the new version:

1. Backup your custom files:
   ```bash
   cp code-review-guardian.sh code-review-guardian.sh.backup
   cp .code-review-guardian.yml .code-review-guardian.yml.backup
   ```

2. Reinstall the package:
   ```bash
   composer reinstall nowo-tech/code-review-guardian
   ```

3. Reapply your custom modifications if needed

## Getting Help

If you encounter issues during upgrade:

1. Check the [CHANGELOG](CHANGELOG.md) for known issues
2. Review the [README](../README.md) for usage examples
3. Open an issue on GitHub with:
   - Your current version
   - Target version
   - Framework (Symfony, Laravel, etc.)
   - Git provider (GitHub, GitLab, Bitbucket, etc.)
   - Error messages
   - Steps to reproduce

