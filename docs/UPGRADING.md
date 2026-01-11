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
   The `code-review-guardian.yaml` configuration file is automatically updated during installation.
   If you have custom modifications, you may need to review and update them.

4. **Update the script** (if needed):
   The `code-review-guardian.sh` script is automatically updated during installation.
   If you have custom modifications, you may need to reapply them.

## Version-Specific Upgrade Notes

### Upgrading to 0.0.5

#### New Features

- **Complete configuration implementation**: All YAML configuration options are now fully parsed, validated, and applied
- **Enhanced configuration validation**: Automatic validation of configuration values (types, ranges, valid options)
- **Improved script output**: All configuration values are now displayed when running the script

#### Changes

- **AGENTS_CONFIG.md included in package**: The file is now included in the Composer package and available in `vendor/`
- **Documentation URLs updated**: All GitHub repository URLs now use the correct repository name

#### Migration Steps

1. **Update the package**:
   ```bash
   composer update nowo-tech/code-review-guardian
   ```

2. **No configuration changes required**: Your existing `code-review-guardian.yaml` file remains compatible

3. **Verify the upgrade**:
   ```bash
   # Run the script to see all configuration options being loaded
   ./code-review-guardian.sh
   ```

4. **Check configuration validation**:
   - The script will now validate all configuration values
   - Invalid values will show warnings
   - Review any warnings and update your configuration if needed

#### What's New

- All configuration options are now fully implemented and validated
- Script output shows all active configuration settings
- Better error messages for invalid configuration values
- `docs/AGENTS_CONFIG.md` is now available in the installed package

### Upgrading to 0.0.3

#### Breaking Changes

- **Configuration file renamed**: `.code-review-guardian.yml` → `code-review-guardian.yaml`
  - Removed leading dot for better visibility
  - Changed extension from `.yml` to `.yaml` (standard YAML extension)
  - Files now appear together alphabetically: `code-review-guardian.sh` and `code-review-guardian.yaml`

#### Migration Steps

1. **Update the package**:
   ```bash
   composer update nowo-tech/code-review-guardian
   ```

2. **Rename your configuration file** (if you have an existing `.code-review-guardian.yml`):
   ```bash
   # Rename the old config file to the new name
   mv .code-review-guardian.yml code-review-guardian.yaml
   ```
   
   **Note**: If you don't have a custom configuration, the new file will be automatically created during installation.

3. **Update your `.gitignore`** (if needed):
   - The package automatically updates `.gitignore` to include `code-review-guardian.yaml`
   - You can manually remove the old entry `.code-review-guardian.yml` if present

4. **Verify the upgrade**:
   ```bash
   # Check that both files exist
   ls -la code-review-guardian.*
   # Should show: code-review-guardian.sh and code-review-guardian.yaml
   
   # Test that the script works
   ./code-review-guardian.sh
   ```

#### What Changed

- **Configuration file**: `.code-review-guardian.yml` → `code-review-guardian.yaml`
  - Same format and content, only filename changed
  - Both files now appear together when listing files alphabetically

- **Script behavior**: The script (`code-review-guardian.sh`) now automatically updates on every `composer install` and `composer update`
  - Ensures you always have the latest version with bug fixes and new features

#### Rollback

If you need to rollback to version 0.0.2:

```bash
composer require --dev nowo-tech/code-review-guardian:^0.0.2
mv code-review-guardian.yaml .code-review-guardian.yml
```

### Upgrading to 0.0.1+

This is the initial release. If you're installing for the first time, follow the installation instructions in the README.

#### New Features

- Provider-agnostic code review guardian
- Automatic framework detection
- Framework-specific configuration files
- Git Guardian Angel (GGA) for automated code reviews
- AI Agents support (OpenAI, Anthropic, GitHub Copilot)
- Token configuration via `.env` file

#### Breaking Changes

- None (initial release)

#### Migration Steps

1. Install the package:
   ```bash
   composer require --dev nowo-tech/code-review-guardian
   ```

2. The package will automatically:
   - Detect your framework
   - Install the appropriate configuration file (`code-review-guardian.yaml`)
   - Install the code review script (`code-review-guardian.sh`)
   - Update your `.gitignore` file

3. Run the code review guardian:
   ```bash
   ./code-review-guardian.sh
   ```

4. Customize the configuration file if needed:
   ```bash
   # Edit code-review-guardian.yaml to customize checks and thresholds
   nano code-review-guardian.yaml
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
   cp vendor/nowo-tech/code-review-guardian/config/generic/code-review-guardian.yaml code-review-guardian.yaml
   ```

### Conflicts with custom modifications

If you've modified the script or configuration and it conflicts with the new version:

1. Backup your custom files:
   ```bash
   cp code-review-guardian.sh code-review-guardian.sh.backup
   cp code-review-guardian.yaml code-review-guardian.yaml.backup
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

