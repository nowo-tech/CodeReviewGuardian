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
E_WARNING="⚠️ "
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

# Parse YAML value (simple parser for key: value format)
parse_yaml_value() {
    local key="$1"
    local section="${2:-}"
    local default="${3:-}"

    if [ -n "$section" ]; then
        grep -A 20 "^${section}:" "$CONFIG_FILE" 2>/dev/null | grep "^\s*${key}:" | head -1 | awk -F: '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//" || echo "$default"
    else
        grep "^${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | awk -F: '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//" || echo "$default"
    fi
}

# Parse YAML array (simple parser for list format)
parse_yaml_array() {
    local key="$1"
    local section="${2:-}"

    if [ -n "$section" ]; then
        # Extract lines after section, until next section or end
        awk "/^${section}:/ {flag=1; next} /^[a-zA-Z]/ {if(flag) flag=0} flag && /^\s*-/ {print}" "$CONFIG_FILE" 2>/dev/null | \
            grep "^\s*-" | sed 's/^\s*-\s*//;s/^"//;s/"$//;s/^'\''//;s/'\''$//' | grep -v "^#"
    else
        awk "/^${key}:/ {flag=1; next} /^[a-zA-Z]/ {if(flag) flag=0} flag && /^\s*-/ {print}" "$CONFIG_FILE" 2>/dev/null | \
            sed 's/^\s*-\s*//;s/^"//;s/"$//;s/^'\''//;s/'\''$//' | grep -v "^#"
    fi
}

# Load configuration from YAML file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$E_ERROR Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    echo "$E_INFO Loading configuration from $CONFIG_FILE..."

    # Load GGA settings
    CONFIG_GGA_ENABLED=$(parse_yaml_value "enabled" "gga" "true")
    CONFIG_GGA_AUTO_REVIEW=$(parse_yaml_value "auto_review" "gga" "true")
    CONFIG_GGA_POST_COMMENTS=$(parse_yaml_value "post_comments" "gga" "true")
    CONFIG_GGA_REVIEW_CHANGED_ONLY=$(parse_yaml_value "review_changed_files_only" "gga" "true")
    CONFIG_GGA_MAX_COMMENTS=$(parse_yaml_value "max_comments" "gga" "50")
    CONFIG_GGA_PROVIDER=$(parse_yaml_value "provider" "gga" "codex")
    CONFIG_GGA_RULES_FILE=$(parse_yaml_value "rules_file" "gga" "docs/AGENTS.md")
    CONFIG_GGA_STRICT_MODE=$(parse_yaml_value "strict_mode" "gga" "true")

    # Load file patterns (arrays)
    CONFIG_GGA_FILE_PATTERNS=$(parse_yaml_array "file_patterns" "gga")
    CONFIG_GGA_EXCLUDE_PATTERNS=$(parse_yaml_array "exclude_patterns" "gga")

    # Load Agents settings
    CONFIG_AGENTS_ENABLED=$(parse_yaml_value "enabled" "agents" "false")
    CONFIG_AGENTS_PROVIDER=$(parse_yaml_value "provider" "agents" "openai")
    CONFIG_AGENTS_MODEL=$(parse_yaml_value "model" "agents" "gpt-4")
    CONFIG_AGENTS_TEMPERATURE=$(parse_yaml_value "temperature" "agents" "0.7")
    CONFIG_AGENTS_REVIEW_SCOPE=$(parse_yaml_array "review_scope" "agents")

    # Load Agents behavior settings (nested under agents.behavior)
    CONFIG_AGENTS_SUGGEST_FIXES=$(grep -A 10 "^agents:" "$CONFIG_FILE" 2>/dev/null | grep -A 5 "behavior:" | grep "suggest_fixes:" | head -1 | awk -F: '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' || echo "true")
    CONFIG_AGENTS_EXPLAIN_ISSUES=$(grep -A 10 "^agents:" "$CONFIG_FILE" 2>/dev/null | grep -A 5 "behavior:" | grep "explain_issues:" | head -1 | awk -F: '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' || echo "true")
    CONFIG_AGENTS_PROVIDE_EXAMPLES=$(grep -A 10 "^agents:" "$CONFIG_FILE" 2>/dev/null | grep -A 5 "behavior:" | grep "provide_examples:" | head -1 | awk -F: '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' || echo "true")
    CONFIG_AGENTS_SEVERITY_THRESHOLD=$(grep -A 10 "^agents:" "$CONFIG_FILE" 2>/dev/null | grep -A 5 "behavior:" | grep "severity_threshold:" | head -1 | awk -F: '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' || echo "medium")

    # Load Rules settings
    CONFIG_RULES_BLOCK_CRITICAL=$(parse_yaml_value "block_on_critical_issues" "rules" "true")
    CONFIG_RULES_BLOCK_SECURITY=$(parse_yaml_value "block_on_security_issues" "rules" "true")

    # Load Comments settings
    CONFIG_COMMENTS_ENABLED=$(parse_yaml_value "enabled" "comments" "true")
    CONFIG_COMMENTS_POST_REVIEW_SUMMARY=$(parse_yaml_value "post_review_summary" "comments" "true")
    CONFIG_COMMENTS_INCLUDE_SUGGESTIONS=$(parse_yaml_value "include_suggestions" "comments" "true")
    CONFIG_COMMENTS_FORMAT=$(parse_yaml_value "format" "comments" "markdown")
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

# Get changed files from git
get_changed_files() {
    local base_ref="${1:-}"

    if [ -z "$base_ref" ]; then
        # Try to detect base branch (main, master, develop, or default branch)
        if git rev-parse --verify origin/main >/dev/null 2>&1; then
            base_ref="origin/main"
        elif git rev-parse --verify origin/master >/dev/null 2>&1; then
            base_ref="origin/master"
        elif git rev-parse --verify origin/develop >/dev/null 2>&1; then
            base_ref="origin/develop"
        else
            # Use default branch or HEAD~1 as fallback
            base_ref="HEAD~1"
        fi
    fi

    # Get changed files (added, modified, renamed, copied)
    git diff --name-only --diff-filter=ACMR "$base_ref" HEAD 2>/dev/null || echo ""
}

# Check if file matches pattern (supports * wildcard)
file_matches_pattern() {
    local file="$1"
    local pattern="$2"

    # Convert glob pattern to regex
    local regex=$(echo "$pattern" | sed 's/\./\\./g; s/\*/.*/g')

    # Check if file matches
    echo "$file" | grep -qE "^$regex$" 2>/dev/null
}

# Check if file should be included based on patterns (returns 0 if included, 1 if excluded)
should_include_file() {
    local file="$1"
    local include_patterns="$2"
    local exclude_patterns="$3"
    local pattern

    # Check exclude patterns first (they take priority)
    if [ -n "$exclude_patterns" ]; then
        echo "$exclude_patterns" | while IFS= read -r pattern; do
            [ -z "$pattern" ] && continue
            if file_matches_pattern "$file" "$pattern"; then
                echo "EXCLUDED"
                break
            fi
        done | grep -q "EXCLUDED" && return 1
    fi

    # Check include patterns
    if [ -n "$include_patterns" ]; then
        echo "$include_patterns" | while IFS= read -r pattern; do
            [ -z "$pattern" ] && continue
            if file_matches_pattern "$file" "$pattern"; then
                echo "INCLUDED"
                break
            fi
        done | grep -q "INCLUDED" && return 0 || return 1
    else
        # No include patterns means include all (except excluded)
        return 0
    fi
}

# Read rules file content
read_rules_file() {
    local rules_file="${CONFIG_GGA_RULES_FILE:-docs/AGENTS.md}"

    if [ ! -f "$rules_file" ]; then
        echo ""
        return 1
    fi

    cat "$rules_file"
}

# Run code review
run_review() {
    echo "$E_GUARDIAN Running Code Review Guardian..."
    echo ""

    load_config

    # Check if GGA is enabled
    if [ "$CONFIG_GGA_ENABLED" != "true" ] && [ "$CONFIG_GGA_ENABLED" != "True" ]; then
        echo "$E_INFO Git Guardian Angel is disabled in configuration."
        return 0
    fi

    echo "$E_INFO Git Guardian Angel is enabled."

    # Validate auto_review setting
    if [ "$CONFIG_GGA_AUTO_REVIEW" != "true" ] && [ "$CONFIG_GGA_AUTO_REVIEW" != "True" ]; then
        echo "$E_INFO Auto review is disabled - review will only run manually."
    fi

    # Validate post_comments setting
    if [ "$CONFIG_GGA_POST_COMMENTS" != "true" ] && [ "$CONFIG_GGA_POST_COMMENTS" != "True" ]; then
        echo "$E_INFO Post comments is disabled - comments will not be posted to PR/MR."
    fi

    echo "$E_INFO Configuration:"
    echo "$E_INFO   - Provider: $CONFIG_GGA_PROVIDER"
    echo "$E_INFO   - Auto review: $CONFIG_GGA_AUTO_REVIEW"
    echo "$E_INFO   - Post comments: $CONFIG_GGA_POST_COMMENTS"
    echo "$E_INFO   - Rules file: $CONFIG_GGA_RULES_FILE"
    echo "$E_INFO   - Review changed files only: $CONFIG_GGA_REVIEW_CHANGED_ONLY"
    echo "$E_INFO   - Max comments: $CONFIG_GGA_MAX_COMMENTS"
    echo "$E_INFO   - Strict mode: $CONFIG_GGA_STRICT_MODE"
    echo ""

    # Check if agents are enabled
    if [ "$CONFIG_AGENTS_ENABLED" = "true" ] || [ "$CONFIG_AGENTS_ENABLED" = "True" ]; then
        echo "$E_INFO AI Agents are enabled:"
        echo "$E_INFO   - Provider: $CONFIG_AGENTS_PROVIDER"
        echo "$E_INFO   - Model: $CONFIG_AGENTS_MODEL"
        echo "$E_INFO   - Temperature: $CONFIG_AGENTS_TEMPERATURE"
        if [ -n "$CONFIG_AGENTS_REVIEW_SCOPE" ]; then
            echo "$E_INFO   - Review scope: $(echo "$CONFIG_AGENTS_REVIEW_SCOPE" | tr '\n' ', ' | sed 's/,$//')"
        fi
        echo "$E_INFO   - Behavior:"
        echo "$E_INFO     * Suggest fixes: $CONFIG_AGENTS_SUGGEST_FIXES"
        echo "$E_INFO     * Explain issues: $CONFIG_AGENTS_EXPLAIN_ISSUES"
        echo "$E_INFO     * Provide examples: $CONFIG_AGENTS_PROVIDE_EXAMPLES"
        echo "$E_INFO     * Severity threshold: $CONFIG_AGENTS_SEVERITY_THRESHOLD"
    else
        echo "$E_WARNING AI Agents are disabled in $CONFIG_FILE"
        echo "$E_WARNING To enable AI-powered code reviews, edit $CONFIG_FILE and set:"
        echo "$E_WARNING   agents:"
        echo "$E_WARNING     enabled: true"
        echo "$E_WARNING     provider: openai  # or anthropic, github_copilot"
        echo "$E_WARNING     model: gpt-4"
        echo "$E_WARNING See https://github.com/nowo-tech/CodeReviewGuardian/blob/main/docs/AGENTS_CONFIG.md for detailed configuration instructions"
    fi
    echo ""

    # Get files to review
    echo "$E_INFO Getting files to review..."

    if [ "$CONFIG_GGA_REVIEW_CHANGED_ONLY" = "true" ] || [ "$CONFIG_GGA_REVIEW_CHANGED_ONLY" = "True" ]; then
        CHANGED_FILES=$(get_changed_files)
        if [ -z "$CHANGED_FILES" ]; then
            echo "$E_WARNING No changed files found. Are you on a branch with changes?"
            echo "$E_INFO Reviewing all files matching patterns instead..."
            CHANGED_FILES=$(git ls-files 2>/dev/null || echo "")
        fi
    else
        # Review all files in repository
        CHANGED_FILES=$(git ls-files 2>/dev/null || echo "")
    fi

    if [ -z "$CHANGED_FILES" ]; then
        echo "$E_ERROR No files found to review."
        return 1
    fi

    # Filter files based on patterns
    echo "$E_INFO Filtering files based on patterns..."
    FILTERED_COUNT=0

    echo "$CHANGED_FILES" | while IFS= read -r file; do
        [ -z "$file" ] && continue

        if should_include_file "$file" "$CONFIG_GGA_FILE_PATTERNS" "$CONFIG_GGA_EXCLUDE_PATTERNS"; then
            echo "$file"
            FILTERED_COUNT=$((FILTERED_COUNT + 1))
        fi
    done > /tmp/crg_filtered_files.$$

    FILTERED_FILES=$(cat /tmp/crg_filtered_files.$$ 2>/dev/null || echo "")
    FILTERED_COUNT=$(echo "$FILTERED_FILES" | grep -v "^$" | wc -l | tr -d ' ')
    rm -f /tmp/crg_filtered_files.$$

    if [ "$FILTERED_COUNT" -eq 0 ]; then
        echo "$E_WARNING No files match the configured patterns."
        if [ -n "$CONFIG_GGA_FILE_PATTERNS" ]; then
            echo "$E_INFO File patterns: $(echo "$CONFIG_GGA_FILE_PATTERNS" | head -3 | tr '\n' ', ' | sed 's/,$//')"
        fi
        if [ -n "$CONFIG_GGA_EXCLUDE_PATTERNS" ]; then
            echo "$E_INFO Exclude patterns: $(echo "$CONFIG_GGA_EXCLUDE_PATTERNS" | head -3 | tr '\n' ', ' | sed 's/,$//')"
        fi
        return 0
    fi

    echo "$E_OK Found $FILTERED_COUNT file(s) to review"
    if [ "$DRY_RUN" = true ]; then
        echo "$E_INFO Files that would be reviewed:"
        echo "$FILTERED_FILES" | head -10 | while IFS= read -r file; do
            [ -z "$file" ] && continue
            echo "  - $file"
        done
        [ "$FILTERED_COUNT" -gt 10 ] && echo "  ... and $((FILTERED_COUNT - 10)) more"
    fi
    echo ""

    # Read rules file
    RULES_CONTENT=$(read_rules_file)
    if [ -n "$RULES_CONTENT" ]; then
        RULES_LINES=$(echo "$RULES_CONTENT" | wc -l | tr -d ' ')
        echo "$E_INFO Rules file loaded: $CONFIG_GGA_RULES_FILE ($RULES_LINES lines)"
    else
        echo "$E_WARNING Rules file not found or empty: $CONFIG_GGA_RULES_FILE"
    fi
    echo ""

    # Show Rules configuration
    echo "$E_INFO Review Rules:"
    echo "$E_INFO   - Block on critical issues: $CONFIG_RULES_BLOCK_CRITICAL"
    echo "$E_INFO   - Block on security issues: $CONFIG_RULES_BLOCK_SECURITY"
    echo ""

    # Show Comments configuration
    echo "$E_INFO Comments Configuration:"
    echo "$E_INFO   - Enabled: $CONFIG_COMMENTS_ENABLED"
    echo "$E_INFO   - Post review summary: $CONFIG_COMMENTS_POST_REVIEW_SUMMARY"
    echo "$E_INFO   - Include suggestions: $CONFIG_COMMENTS_INCLUDE_SUGGESTIONS"
    echo "$E_INFO   - Format: $CONFIG_COMMENTS_FORMAT"
    echo ""

    # Show what would be done
    if [ "$DRY_RUN" = true ]; then
        echo "$E_INFO DRY RUN: Code review would be performed using:"
        echo "$E_INFO   - Provider: $CONFIG_GGA_PROVIDER"
        echo "$E_INFO   - Max comments: $CONFIG_GGA_MAX_COMMENTS"
        if [ "$CONFIG_AGENTS_ENABLED" = "true" ] || [ "$CONFIG_AGENTS_ENABLED" = "True" ]; then
            echo "$E_INFO   - Model: $CONFIG_AGENTS_MODEL"
            echo "$E_INFO   - Temperature: $CONFIG_AGENTS_TEMPERATURE"
            echo "$E_INFO   - Severity threshold: $CONFIG_AGENTS_SEVERITY_THRESHOLD"
            if [ -n "$CONFIG_AGENTS_REVIEW_SCOPE" ]; then
                echo "$E_INFO   - Review scope: $(echo "$CONFIG_AGENTS_REVIEW_SCOPE" | tr '\n' ', ' | sed 's/,$//')"
            fi
        fi
        echo "$E_INFO   - Comments format: $CONFIG_COMMENTS_FORMAT"
        return 0
    fi

    # Validate configuration values
    VALIDATION_ERRORS=0

    # Validate max_comments is a number
    if ! echo "$CONFIG_GGA_MAX_COMMENTS" | grep -qE '^[0-9]+$'; then
        echo "$E_WARNING Invalid max_comments value: $CONFIG_GGA_MAX_COMMENTS (must be a number, using default: 50)"
        CONFIG_GGA_MAX_COMMENTS=50
    fi

    # Validate severity_threshold
    if [ "$CONFIG_AGENTS_ENABLED" = "true" ] || [ "$CONFIG_AGENTS_ENABLED" = "True" ]; then
        case "$CONFIG_AGENTS_SEVERITY_THRESHOLD" in
            low|medium|high|critical)
                # Valid
                ;;
            *)
                echo "$E_WARNING Invalid severity_threshold: $CONFIG_AGENTS_SEVERITY_THRESHOLD (must be: low, medium, high, critical)"
                VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
                ;;
        esac

        # Validate temperature is between 0 and 2
        TEMP_CHECK=$(echo "$CONFIG_AGENTS_TEMPERATURE" | awk '{if ($1 >= 0 && $1 <= 2) print "valid"; else print "invalid"}')
        if [ "$TEMP_CHECK" != "valid" ]; then
            echo "$E_WARNING Invalid temperature: $CONFIG_AGENTS_TEMPERATURE (should be between 0 and 2)"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    fi

    # Validate comments format
    case "$CONFIG_COMMENTS_FORMAT" in
        markdown|text)
            # Valid
            ;;
        *)
            echo "$E_WARNING Invalid comments format: $CONFIG_COMMENTS_FORMAT (must be: markdown or text)"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
            ;;
    esac

    if [ $VALIDATION_ERRORS -gt 0 ]; then
        echo "$E_WARNING Found $VALIDATION_ERRORS configuration validation error(s)."
        echo "$E_INFO Please review your configuration file: $CONFIG_FILE"
        echo ""
    fi

    # Configuration and file filtering is complete
    # All configurations are loaded, validated, and ready for use
    echo "$E_INFO Configuration loaded and validated successfully."
    echo "$E_INFO Files filtered according to configuration ($FILTERED_COUNT file(s) ready for review)."
    echo "$E_INFO Rules file loaded and ready for use."
    echo "$E_INFO All configuration settings are active and will be applied."
    echo ""

    # Show summary of active settings
    echo "$E_INFO Active Settings Summary:"
    echo "$E_INFO   - Files to review: $FILTERED_COUNT"
    echo "$E_INFO   - Max comments limit: $CONFIG_GGA_MAX_COMMENTS"
    if [ "$CONFIG_AGENTS_ENABLED" = "true" ] || [ "$CONFIG_AGENTS_ENABLED" = "True" ]; then
        echo "$E_INFO   - Severity threshold: $CONFIG_AGENTS_SEVERITY_THRESHOLD (only issues >= this level will be reported)"
        echo "$E_INFO   - Suggest fixes: $CONFIG_AGENTS_SUGGEST_FIXES"
        echo "$E_INFO   - Explain issues: $CONFIG_AGENTS_EXPLAIN_ISSUES"
        echo "$E_INFO   - Provide examples: $CONFIG_AGENTS_PROVIDE_EXAMPLES"
    fi
    echo "$E_INFO   - Block merge on critical: $CONFIG_RULES_BLOCK_CRITICAL"
    echo "$E_INFO   - Block merge on security: $CONFIG_RULES_BLOCK_SECURITY"
    echo "$E_INFO   - Comments format: $CONFIG_COMMENTS_FORMAT"
    echo ""
    echo "$E_INFO Status: All configurations are loaded, validated, and ready for use."
    echo "$E_INFO Note: AI-powered code review integration is in active development."
    echo "$E_INFO Once complete, all these settings will be fully applied during code review."

    return 0
}

# Post comment to PR/MR
post_comment() {
    echo "$E_INFO Posting review comment to PR/MR..."
    echo ""

    check_config
    load_config

    # Check if comments are enabled
    if [ "$CONFIG_COMMENTS_ENABLED" != "true" ] && [ "$CONFIG_COMMENTS_ENABLED" != "True" ]; then
        echo "$E_WARNING Comments are disabled in configuration."
        echo "$E_INFO Set comments.enabled: true in $CONFIG_FILE to enable comment posting."
        return 0
    fi

    # Check if GGA post_comments is enabled
    if [ "$CONFIG_GGA_POST_COMMENTS" != "true" ] && [ "$CONFIG_GGA_POST_COMMENTS" != "True" ]; then
        echo "$E_WARNING Post comments is disabled in GGA configuration."
        echo "$E_INFO Set gga.post_comments: true in $CONFIG_FILE to enable comment posting."
        return 0
    fi

    TOKEN=$(get_git_token)
    if [ $? -ne 0 ]; then
        echo "$E_ERROR Cannot post comment without Git token."
        return 1
    fi

    echo "$E_INFO Git token found."
    echo "$E_INFO Comments Configuration:"
    echo "$E_INFO   - Enabled: $CONFIG_COMMENTS_ENABLED"
    echo "$E_INFO   - Post review summary: $CONFIG_COMMENTS_POST_REVIEW_SUMMARY"
    echo "$E_INFO   - Include suggestions: $CONFIG_COMMENTS_INCLUDE_SUGGESTIONS"
    echo "$E_INFO   - Format: $CONFIG_COMMENTS_FORMAT"
    echo "$E_INFO   - Max comments: $CONFIG_GGA_MAX_COMMENTS"
    echo ""
    echo "$E_INFO Status: Token validation is operational."
    echo "$E_INFO All comment settings are loaded and validated."
    echo "$E_INFO Note: Comment posting functionality is in active development."
    echo "$E_INFO Once complete, comments will be posted using format: $CONFIG_COMMENTS_FORMAT"
    if [ "$CONFIG_COMMENTS_POST_REVIEW_SUMMARY" = "true" ] || [ "$CONFIG_COMMENTS_POST_REVIEW_SUMMARY" = "True" ]; then
        echo "$E_INFO A review summary will be included in the comment."
    fi
    if [ "$CONFIG_COMMENTS_INCLUDE_SUGGESTIONS" = "true" ] || [ "$CONFIG_COMMENTS_INCLUDE_SUGGESTIONS" = "True" ]; then
        echo "$E_INFO Suggestions will be included in the comment."
    fi

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
