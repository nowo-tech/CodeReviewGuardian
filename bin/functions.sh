#!/bin/sh
# functions.sh
# Common utility functions for Code Review Guardian

# Emoji variables
E_OK="✅"
E_ERROR="❌"
E_WARNING="⚠️ "
E_INFO="ℹ️ "
E_GUARDIAN="🛡️ "

# Show help function
show_help() {
    cat <<EOF
Usage: code-review-guardian.sh [OPTIONS]

Provider-agnostic code review guardian for PHP projects.
Works with any PHP project (Symfony, Laravel, Yii, CodeIgniter, etc.)
and any Git provider (GitHub, GitLab, Bitbucket, etc.)

OPTIONS:
    --post-comment        Post review comment to PR/MR (requires Git provider token)
    --dry-run             Show what would be executed without running
    --debug               Enable debug mode with verbose output
    -h, --help            Show this help message

EXAMPLES:
    code-review-guardian.sh                              # Run code review
    code-review-guardian.sh --post-comment               # Post comment to PR/MR
    code-review-guardian.sh --dry-run                    # Show what would be executed
    code-review-guardian.sh --debug                      # Run with debug output

CONFIGURATION:
    Configuration file: code-review-guardian.yaml
    The configuration file is automatically generated based on your framework.

    Token configuration:
    - Add GIT_TOKEN to your .env file (or .env.local for local overrides)
    - The script reads the token from the environment variable specified in the YAML config
    - Environment file loading order: .env (base) → .env.local (overrides, higher priority)
    - If .env file doesn't exist, it will be created automatically with a template

GIT PROVIDER SUPPORT:
    Automatically detects and works with:
    - GitHub (GitHub Actions, pull requests)
    - GitLab (GitLab CI, merge requests)
    - Bitbucket (Bitbucket Pipelines, pull requests)

    Set GIT_TOKEN environment variable for API access.

DOCUMENTATION:
    See docs/AGENTS.md for code review rules (used by GGA)
    See docs/GGA.md for Git Guardian Angel setup

EOF
}

# Debug function (outputs to stderr to not interfere with normal output)
debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "$E_INFO [DEBUG] $*" >&2
    fi
}
