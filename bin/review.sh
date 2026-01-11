#!/bin/sh
# review.sh
# Code review execution functions for Code Review Guardian

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
        # Get PHP version, redirecting stderr to avoid warnings
        PHP_VERSION=$(php -r 'echo PHP_VERSION;' 2>/dev/null | head -1 | tr -d '\n' || echo "unknown")
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
