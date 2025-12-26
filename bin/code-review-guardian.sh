#!/bin/sh
# code-review-guardian.sh
# Provider-agnostic code review guardian for PHP projects.
# Works with any PHP project (Symfony, Laravel, Yii, CodeIgniter, etc.)
# and any Git provider (GitHub, GitLab, Bitbucket, etc.)
#
# Usage:
#   ./code-review-guardian.sh                    # Run code review
#   ./code-review-guardian.sh --post-comment     # Post review comment to PR/MR
#   ./code-review-guardian.sh --help             # Show help

set -eu

# Emoji variables
E_OK="✅"
E_ERROR="❌"
E_WARNING="⚠️"
E_INFO="ℹ️ "
E_GUARDIAN="🛡️ "

# Configuration file
CONFIG_FILE="code-review-guardian.yaml"

# Show help function
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Provider-agnostic code review guardian for PHP projects.
Works with any PHP project (Symfony, Laravel, Yii, CodeIgniter, etc.)
and any Git provider (GitHub, GitLab, Bitbucket, etc.)

OPTIONS:
    --post-comment        Post review comment to PR/MR (requires Git provider token)
    --dry-run             Show what would be executed without running
    -h, --help            Show this help message

EXAMPLES:
    $0                              # Run code review
    $0 --post-comment               # Post comment to PR/MR
    $0 --dry-run                    # Show what would be executed

CONFIGURATION:
    Configuration file: $CONFIG_FILE
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

# Check if configuration file exists
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$E_ERROR Configuration file not found: $CONFIG_FILE"
        echo "$E_INFO Run 'composer install' to generate the configuration file."
        exit 1
    fi
}

# Check dependencies and requirements
check_dependencies() {
    local MISSING_DEPS=0

    echo "$E_INFO Checking dependencies..."

    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        echo "$E_ERROR Git is not installed. Please install Git to use Code Review Guardian."
        MISSING_DEPS=1
    else
        echo "$E_OK Git found: $(git --version | head -n1)"
    fi

    # Check PHP
    if ! command -v php >/dev/null 2>&1; then
        echo "$E_ERROR PHP is not installed. Please install PHP >= 7.4 to use Code Review Guardian."
        MISSING_DEPS=1
    else
        PHP_VERSION=$(php -r 'echo PHP_VERSION;' 2>/dev/null || echo "unknown")
        echo "$E_OK PHP found: $PHP_VERSION"

        # Check PHP version (7.4+)
        PHP_MAJOR=$(echo "$PHP_VERSION" | cut -d. -f1)
        PHP_MINOR=$(echo "$PHP_VERSION" | cut -d. -f2)
        if [ "$PHP_MAJOR" -lt 7 ] || ([ "$PHP_MAJOR" -eq 7 ] && [ "$PHP_MINOR" -lt 4 ]); then
            echo "$E_WARNING PHP version $PHP_VERSION is below 7.4. Code Review Guardian requires PHP >= 7.4."
            MISSING_DEPS=1
        fi
    fi

    # Check configuration file
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$E_ERROR Configuration file not found: $CONFIG_FILE"
        echo "$E_INFO Run 'composer install' or 'composer update' to generate the configuration file."
        MISSING_DEPS=1
    else
        echo "$E_OK Configuration file found: $CONFIG_FILE"
    fi

    # Check docs/AGENTS.md (rules file)
    if [ ! -f "docs/AGENTS.md" ]; then
        echo "$E_WARNING Rules file not found: docs/AGENTS.md"
        echo "$E_INFO Run 'composer install' or 'composer update' to install the rules file."
        echo "$E_INFO Code review may not work correctly without the rules file."
    else
        echo "$E_OK Rules file found: docs/AGENTS.md"
    fi

    # Check if we're in a Git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "$E_WARNING Not running in a Git repository."
        echo "$E_INFO Code Review Guardian works best in a Git repository with remote configured."
    else
        echo "$E_OK Git repository detected"

        # Check if remote is configured (optional but recommended)
        if ! git remote >/dev/null 2>&1 || [ -z "$(git remote)" ]; then
            echo "$E_WARNING No Git remote configured. Some features may not work correctly."
        else
            echo "$E_OK Git remote configured: $(git remote | head -n1)"
        fi
    fi

    if [ $MISSING_DEPS -eq 1 ]; then
        echo ""
        echo "$E_ERROR Some required dependencies are missing."
        echo "$E_INFO Please install missing dependencies and try again."
        return 1
    fi

    return 0
}

# Load configuration from YAML file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$E_ERROR Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    # Simple YAML parsing for key values (using awk)
    # This is a basic implementation - for production, consider using a proper YAML parser
    echo "$E_INFO Loading configuration from $CONFIG_FILE..."
}

# Load environment variables from .env files
# Order of precedence (last one wins):
# 1. .env (base configuration)
# 2. .env.local (local overrides, not in git)
load_env_file() {
    local env_file="$1"

    if [ ! -f "$env_file" ]; then
        return 1
    fi

    # Read .env file line by line
    # Handles: KEY=VALUE, KEY="VALUE", KEY='VALUE'
    # Ignores: comments (#), empty lines, whitespace-only lines
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        case "$line" in
            \#*|'')
                continue
                ;;
        esac

        # Trim leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip if empty after trimming
        [ -z "$line" ] && continue

        # Check if line contains =
        if echo "$line" | grep -q '='; then
            # Extract key and value
            key=$(echo "$line" | cut -d'=' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$line" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Remove quotes if present
            value=$(echo "$value" | sed 's/^["'\'']//;s/["'\'']$//')

            # Only export if key is not empty
            if [ -n "$key" ]; then
                export "$key=$value"
            fi
        fi
    done < "$env_file"
}

# Load environment variables from .env files in correct order
load_env_files() {
    # Load .env first (base configuration)
    if [ -f ".env" ]; then
        load_env_file ".env"
    fi

    # Load .env.local second (local overrides, higher priority)
    if [ -f ".env.local" ]; then
        load_env_file ".env.local"
    fi
}

# Read Git token from environment
get_git_token() {
    # Read token environment variable name from config
    TOKEN_ENV_NAME=$(grep -A 2 "api_token_env:" "$CONFIG_FILE" | grep -v "^#" | head -1 | awk '{print $2}' | tr -d '"' || echo "GIT_TOKEN")

    # Default to GIT_TOKEN if not found in config
    if [ -z "$TOKEN_ENV_NAME" ] || [ "$TOKEN_ENV_NAME" = "api_token_env:" ]; then
        TOKEN_ENV_NAME="GIT_TOKEN"
    fi

    # Load .env files in correct order (.env, then .env.local)
    load_env_files

    # Get token from environment (after loading .env files)
    eval "TOKEN=\$$TOKEN_ENV_NAME" 2>/dev/null || TOKEN=""

    # If token is still not found, check if .env files exist
    if [ -z "$TOKEN" ]; then
        echo "$E_WARNING Git token not found: $TOKEN_ENV_NAME"
        echo ""

        # Check if .env files exist
        if [ ! -f ".env" ] && [ ! -f ".env.local" ]; then
            echo "$E_INFO No .env file found. Creating .env file from .env.example if it exists..."

            # Try to create .env from .env.example if it exists
            if [ -f ".env.example" ]; then
                cp ".env.example" ".env"
                echo "$E_OK Created .env file from .env.example"
                echo "$E_INFO Please edit .env and set $TOKEN_ENV_NAME with your Git provider token."
            else
                # Create a basic .env file with a comment
                cat > ".env" <<EOF
# Code Review Guardian Configuration
# Add your Git provider token below
# See docs/TOKEN_SETUP.md for detailed instructions

# Git Provider API Token (required for posting comments to PRs/MRs)
$TOKEN_ENV_NAME=your_token_here
EOF
                echo "$E_OK Created .env file with template"
                echo "$E_INFO Please edit .env and set $TOKEN_ENV_NAME with your Git provider token."
            fi
        else
            # .env file exists but token is not set
            if [ -f ".env" ]; then
                if ! grep -q "^${TOKEN_ENV_NAME}=" .env && ! grep -q "^${TOKEN_ENV_NAME}=" .env.local 2>/dev/null; then
                    echo "$E_INFO Adding $TOKEN_ENV_NAME to .env file..."

                    # Append token to .env file (use .env.local if it exists, otherwise .env)
                    env_target=".env"
                    if [ -f ".env.local" ]; then
                        env_target=".env.local"
                    fi

                    {
                        echo ""
                        echo "# Git Provider API Token (required for posting comments to PRs/MRs)"
                        echo "$TOKEN_ENV_NAME=your_token_here"
                    } >> "$env_target"

                    echo "$E_OK Added $TOKEN_ENV_NAME to $env_target"
                    echo "$E_INFO Please edit $env_target and set $TOKEN_ENV_NAME with your Git provider token."
                else
                    echo "$E_INFO Variable $TOKEN_ENV_NAME exists in .env file but is empty or commented out."
                    echo "$E_INFO Please uncomment or set the value in .env or .env.local"
                fi
            fi
        fi

        echo ""
        echo "$E_INFO See docs/TOKEN_SETUP.md for detailed step-by-step instructions."
        echo "$E_INFO Order of .env file loading: .env (base) → .env.local (overrides)"

        return 1
    fi

    echo "$TOKEN"
}

# Run code review
run_review() {
    echo "$E_GUARDIAN Running Code Review Guardian..."
    echo ""

    load_config

    # Check if GGA is enabled
    GGA_ENABLED=$(grep -A 5 "^gga:" "$CONFIG_FILE" | grep "enabled:" | head -1 | awk '{print $2}' | tr -d '"' || echo "true")

    if [ "$GGA_ENABLED" != "true" ] && [ "$GGA_ENABLED" != "True" ]; then
        echo "$E_INFO Git Guardian Angel is disabled in configuration."
        return 0
    fi

    echo "$E_INFO Git Guardian Angel is enabled."
    echo "$E_INFO This will review code changes in the current branch/PR/MR."
    echo ""

    # Check if agents are enabled
    AGENTS_ENABLED=$(grep -A 2 "^agents:" "$CONFIG_FILE" | grep "enabled:" | head -1 | awk '{print $2}' | tr -d '"' || echo "false")

    if [ "$AGENTS_ENABLED" = "true" ] || [ "$AGENTS_ENABLED" = "True" ]; then
        echo "$E_INFO AI Agents are enabled in configuration."
        echo "$E_INFO See docs/AGENTS.md for code review rules (used by GGA)."
    else
        echo "$E_WARNING AI Agents are disabled in $CONFIG_FILE"
        echo "$E_WARNING To enable AI-powered code reviews, edit $CONFIG_FILE and set:"
        echo "$E_WARNING   agents:"
        echo "$E_WARNING     enabled: true"
        echo "$E_WARNING     provider: openai  # or anthropic, github_copilot"
        echo "$E_WARNING     model: gpt-4"
        echo "$E_WARNING See https://github.com/nowo-tech/code-review-guardian/blob/main/docs/AGENTS_CONFIG.md for detailed configuration instructions"
    fi

    echo ""
    echo "$E_INFO Code review functionality is coming soon!"
    echo "$E_INFO This will use Git Guardian Angel to review your code changes."

    return 0
}

# Post comment to PR/MR
post_comment() {
    echo "$E_INFO Posting review comment to PR/MR..."
    echo ""

    check_config

    TOKEN=$(get_git_token)
    if [ $? -ne 0 ]; then
        echo "$E_ERROR Cannot post comment without Git token."
        return 1
    fi

    echo "$E_INFO Git token found."
    echo "$E_INFO Comment posting functionality is coming soon!"
    echo "$E_INFO This will post review comments to your PR/MR using the Git provider API."

    return 0
}

# Parse command line arguments
POST_COMMENT=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            exit 0
            ;;
        --post-comment)
            POST_COMMENT=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        *)
            echo "$E_ERROR Unknown option: $arg"
            echo "Run '$0 --help' for usage information."
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo "$E_GUARDIAN Code Review Guardian"
    echo "================================"
    echo ""

    # Check dependencies first
    if ! check_dependencies; then
        exit 1
    fi

    echo ""
    check_config
    echo ""

    EXIT_CODE=0

    if [ "$POST_COMMENT" = true ]; then
        post_comment || EXIT_CODE=1
    else
        run_review || EXIT_CODE=1
    fi

    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        echo "$E_OK Code review completed!"
    else
        echo "$E_ERROR Code review failed!"
    fi

    exit $EXIT_CODE
}

main
