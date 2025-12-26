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

# Git provider settings
git:
  provider: auto  # auto, github, gitlab, bitbucket
  api_token_env: GIT_TOKEN  # Reads from .env file
  repository_url: auto  # auto-detected from git remote

# Git Guardian Angel (GGA) settings
gga:
  enabled: true
  auto_review: true
  post_comments: true
  review_changed_files_only: true
  max_comments: 50
  provider: codex  # codex, claude, gemini, ollama
  file_patterns:
    - "*.php"
    - "*.twig"  # or *.blade.php for Laravel
  exclude_patterns:
    - "vendor/*"
    - "var/*"  # or storage/* for Laravel
    - "public/build/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  rules_file: "docs/AGENTS.md"
  strict_mode: true

# AI Agents configuration
agents:
  enabled: false
  provider: openai  # openai, anthropic, github_copilot
  model: gpt-4
  temperature: 0.7
  review_scope:
    - code_quality
    - security
    - performance
    - best_practices
    - documentation
  behavior:
    suggest_fixes: true
    explain_issues: true
    provide_examples: true
    severity_threshold: medium

# Code review rules
rules:
  block_on_critical_issues: true
  block_on_security_issues: true

# Comment settings for PR/MR
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

### Git Provider Settings

#### `git`

Git provider configuration for API access.

- **Type**: `object`
- **Default**: Auto-detected
- **Options**:
  - `provider`: `auto`, `github`, `gitlab`, `bitbucket` (default: `auto`)
  - `api_token_env`: Environment variable name for API token (default: `GIT_TOKEN`)
  - `repository_url`: Repository URL (default: `auto` - auto-detected from git remote)

**Important**: The token must be set in your `.env` file:

```env
GIT_TOKEN=your_github_or_gitlab_token_here
```

```yaml
git:
  provider: auto
  api_token_env: GIT_TOKEN
  repository_url: auto
```

### Git Guardian Angel (GGA) Settings

#### `gga`

Configuration for the Git Guardian Angel code review system.

- **Type**: `object`
- **Default**: All options enabled
- **Options**:
  - `enabled`: Enable/disable GGA (default: `true`)
  - `auto_review`: Automatically review new PRs/MRs (default: `true`)
  - `post_comments`: Post review comments to PRs/MRs (default: `true`)
  - `review_changed_files_only`: Only review changed files (default: `true`)
  - `max_comments`: Maximum number of comments per review (default: `50`)

```yaml
gga:
  enabled: true
  auto_review: true
  post_comments: true
  review_changed_files_only: true
  max_comments: 50
  
  # AI Provider for GGA (codex, claude, gemini, ollama)
  provider: codex
  
  # File patterns to review
  file_patterns:
    - "*.php"
    - "*.twig"  # or *.blade.php for Laravel
  
  # Patterns to exclude from review
  exclude_patterns:
    - "vendor/*"
    - "var/*"  # or storage/* for Laravel
    - "public/build/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  
  # Rules file (relative to project root)
  rules_file: "docs/AGENTS.md"
  
  # Strict mode: fail if response is ambiguous
  strict_mode: true
```

### AI Agents Configuration

#### `agents`

Configuration for AI-powered code review agents.

- **Type**: `object`
- **Default**: Disabled
- **Options**:
  - `enabled`: Enable/disable AI agents (default: `false`)
  - `provider`: AI provider - `openai`, `anthropic`, `github_copilot` (default: `openai`)
  - `model`: Model to use (default: `gpt-4`)
  - `temperature`: Temperature setting (default: `0.7`)
  - `review_scope`: Array of review areas (default: all)
  - `behavior`: Agent behavior settings

```yaml
agents:
  enabled: true
  provider: openai
  model: gpt-4
  temperature: 0.7
  review_scope:
    - code_quality
    - security
    - performance
    - best_practices
    - documentation
  behavior:
    suggest_fixes: true
    explain_issues: true
    provide_examples: true
    severity_threshold: medium
```

See `docs/AGENTS_CONFIG.md` for detailed AI agent configuration instructions.

### Code Review Rules

#### `rules`

Rules for blocking merges based on review results.

- **Type**: `object`
- **Default**: All rules enabled
- **Options**:
  - `block_on_critical_issues`: Block merge if critical issues found (default: `true`)
  - `block_on_security_issues`: Block merge if security issues found (default: `true`)

```yaml
rules:
  block_on_critical_issues: true
  block_on_security_issues: true
```

### Comment Settings

#### `comments`

Settings for PR/MR comments.

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

git:
  provider: auto
  api_token_env: GIT_TOKEN

gga:
  enabled: true
  auto_review: true
  post_comments: true
  provider: codex
  file_patterns:
    - "*.php"
    - "*.twig"
  exclude_patterns:
    - "vendor/*"
    - "var/*"
    - "public/build/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  rules_file: "docs/AGENTS.md"
  strict_mode: true

agents:
  enabled: false
  provider: openai
  model: gpt-4
```

### Laravel

```yaml
framework: laravel

git:
  provider: auto
  api_token_env: GIT_TOKEN

gga:
  enabled: true
  auto_review: true
  post_comments: true
  provider: codex
  file_patterns:
    - "*.php"
    - "*.blade.php"
  exclude_patterns:
    - "vendor/*"
    - "storage/*"
    - "public/build/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  rules_file: "docs/AGENTS.md"
  strict_mode: true

agents:
  enabled: false
  provider: openai
  model: gpt-4
```

### Generic PHP

```yaml
framework: generic

git:
  provider: auto
  api_token_env: GIT_TOKEN

gga:
  enabled: true
  auto_review: true
  post_comments: true
  provider: codex
  file_patterns:
    - "*.php"
  exclude_patterns:
    - "vendor/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  rules_file: "docs/AGENTS.md"
  strict_mode: true

agents:
  enabled: false
  provider: openai
  model: gpt-4
```

## Environment Variables

Code Review Guardian requires the following environment variable:

### `GIT_TOKEN`

Git provider API token for posting review comments.

- **Required**: Yes (for posting comments)
- **Location**: `.env` or `.env.local` file in project root
- **Format**: Token from your Git provider (GitHub, GitLab, or Bitbucket)

```env
GIT_TOKEN=your_token_here
```

See `docs/GGA.md` for instructions on obtaining tokens for each provider.

#### Environment File Loading Order

The script loads environment variables from `.env` files in the following order (last one wins):

1. **`.env`** - Base configuration (should be in version control as `.env.example`)
2. **`.env.local`** - Local overrides (should NOT be in version control, highest priority)

This follows the standard pattern used by Symfony and Laravel frameworks.

**Example:**

```env
# .env (base configuration, committed to git as .env.example)
GIT_TOKEN=base_token_here

# .env.local (local overrides, NOT committed, overrides .env)
GIT_TOKEN=local_token_here  # This value will be used
```

**Note**: If the `.env` file doesn't exist, the script will automatically create it with a template. If `.env.example` exists, it will be copied to `.env`. If a required environment variable is missing, it will be added to the appropriate `.env` file.

## Additional Resources

- [AGENTS_CONFIG.md](AGENTS_CONFIG.md) - AI Agent configuration guide (package documentation)
- [GGA.md](GGA.md) - Git Guardian Angel setup guide
- [README.md](../README.md) - Main documentation
