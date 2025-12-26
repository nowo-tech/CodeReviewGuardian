#!/bin/sh
# code-review-guardian.sh
# Provider-agnostic code review guardian for PHP projects.
# Works with any PHP project (Symfony, Laravel, Yii, CodeIgniter, etc.)
# and any Git provider (GitHub, GitLab, Bitbucket, etc.)
#
# Usage:
#   ./code-review-guardian.sh                    # Run all checks
#   ./code-review-guardian.sh --check-style      # Only code style check
#   ./code-review-guardian.sh --check-static     # Only static analysis
#   ./code-review-guardian.sh --check-tests      # Only tests
#   ./code-review-guardian.sh --check-all        # Run all checks (default)
#   ./code-review-guardian.sh --post-comment     # Post review comment to PR/MR
#   ./code-review-guardian.sh --help             # Show help

set -eu

# Emoji variables
E_OK="✅"
E_ERROR="❌"
E_WARNING="⚠️"
E_INFO="ℹ️"
E_GUARDIAN="🛡️"
E_STYLE="💅"
E_TEST="🧪"
E_ANALYZE="🔍"

# Configuration file
CONFIG_FILE=".code-review-guardian.yml"

# Show help function
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Provider-agnostic code review guardian for PHP projects.
Works with any PHP project (Symfony, Laravel, Yii, CodeIgniter, etc.)
and any Git provider (GitHub, GitLab, Bitbucket, etc.)

OPTIONS:
    --check-style         Run only code style checks (PHP-CS-Fixer)
    --check-static        Run only static analysis (PHPStan)
    --check-tests         Run only tests (PHPUnit)
    --check-security      Run only security checks
    --check-all           Run all checks (default)
    --post-comment        Post review comment to PR/MR (requires Git provider token)
    --dry-run             Show what would be executed without running
    -h, --help            Show this help message

EXAMPLES:
    $0                              # Run all checks
    $0 --check-style                # Only code style
    $0 --check-tests                # Only tests
    $0 --post-comment               # Post comment to PR/MR
    $0 --check-style --check-tests  # Run specific checks

CONFIGURATION:
    Configuration file: $CONFIG_FILE
    The configuration file is automatically generated based on your framework.

GIT PROVIDER SUPPORT:
    Automatically detects and works with:
    - GitHub (GitHub Actions, pull requests)
    - GitLab (GitLab CI, merge requests)
    - Bitbucket (Bitbucket Pipelines, pull requests)

    Set GIT_TOKEN environment variable for API access.

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

# Run code style check
check_style() {
    echo "$E_STYLE Running code style check..."
    
    if [ ! -f ".php-cs-fixer.dist.php" ] && [ ! -f "php-cs-fixer.php" ]; then
        echo "$E_WARNING PHP-CS-Fixer configuration not found. Skipping style check."
        return 0
    fi

    if command -v php-cs-fixer >/dev/null 2>&1; then
        php-cs-fixer fix --dry-run --diff || {
            echo "$E_ERROR Code style check failed!"
            return 1
        }
    elif [ -f "vendor/bin/php-cs-fixer" ]; then
        vendor/bin/php-cs-fixer fix --dry-run --diff || {
            echo "$E_ERROR Code style check failed!"
            return 1
        }
    else
        echo "$E_WARNING PHP-CS-Fixer not found. Install it with: composer require --dev friendsofphp/php-cs-fixer"
        return 0
    fi

    echo "$E_OK Code style check passed!"
    return 0
}

# Run static analysis
check_static() {
    echo "$E_ANALYZE Running static analysis..."
    
    if [ ! -f "phpstan.neon.dist" ] && [ ! -f "phpstan.neon" ]; then
        echo "$E_WARNING PHPStan configuration not found. Skipping static analysis."
        return 0
    fi

    if command -v phpstan >/dev/null 2>&1; then
        phpstan analyse || {
            echo "$E_ERROR Static analysis failed!"
            return 1
        }
    elif [ -f "vendor/bin/phpstan" ]; then
        vendor/bin/phpstan analyse || {
            echo "$E_ERROR Static analysis failed!"
            return 1
        }
    else
        echo "$E_WARNING PHPStan not found. Install it with: composer require --dev phpstan/phpstan"
        return 0
    fi

    echo "$E_OK Static analysis passed!"
    return 0
}

# Run tests
check_tests() {
    echo "$E_TEST Running tests..."
    
    if [ ! -f "phpunit.xml.dist" ] && [ ! -f "phpunit.xml" ]; then
        echo "$E_WARNING PHPUnit configuration not found. Skipping tests."
        return 0
    fi

    if command -v phpunit >/dev/null 2>&1; then
        phpunit || {
            echo "$E_ERROR Tests failed!"
            return 1
        }
    elif [ -f "vendor/bin/phpunit" ]; then
        vendor/bin/phpunit || {
            echo "$E_ERROR Tests failed!"
            return 1
        }
    else
        echo "$E_WARNING PHPUnit not found. Install it with: composer require --dev phpunit/phpunit"
        return 0
    fi

    echo "$E_OK Tests passed!"
    return 0
}

# Run security check
check_security() {
    echo "$E_GUARDIAN Running security check..."
    
    # Check for Symfony Security Checker
    if [ -f "vendor/bin/security-checker" ]; then
        vendor/bin/security-checker security:check || {
            echo "$E_ERROR Security check failed!"
            return 1
        }
    elif command -v security-checker >/dev/null 2>&1; then
        security-checker security:check || {
            echo "$E_ERROR Security check failed!"
            return 1
        }
    else
        echo "$E_INFO Security checker not found. Consider installing: composer require --dev symfony/security-checker"
        return 0
    fi

    echo "$E_OK Security check passed!"
    return 0
}

# Post comment to PR/MR (placeholder for now)
post_comment() {
    echo "$E_INFO Posting review comment..."
    echo "$E_WARNING Comment posting feature is coming soon!"
    echo "$E_INFO This will automatically post review comments to your PR/MR."
    return 0
}

# Parse command line arguments
CHECK_STYLE=false
CHECK_STATIC=false
CHECK_TESTS=false
CHECK_SECURITY=false
CHECK_ALL=true
POST_COMMENT=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            exit 0
            ;;
        --check-style)
            CHECK_STYLE=true
            CHECK_ALL=false
            ;;
        --check-static)
            CHECK_STATIC=true
            CHECK_ALL=false
            ;;
        --check-tests)
            CHECK_TESTS=true
            CHECK_ALL=false
            ;;
        --check-security)
            CHECK_SECURITY=true
            CHECK_ALL=false
            ;;
        --check-all)
            CHECK_ALL=true
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

    check_config

    EXIT_CODE=0

    if [ "$CHECK_ALL" = true ]; then
        check_style || EXIT_CODE=1
        check_static || EXIT_CODE=1
        check_tests || EXIT_CODE=1
        check_security || EXIT_CODE=1
    else
        [ "$CHECK_STYLE" = true ] && check_style || EXIT_CODE=1
        [ "$CHECK_STATIC" = true ] && check_static || EXIT_CODE=1
        [ "$CHECK_TESTS" = true ] && check_tests || EXIT_CODE=1
        [ "$CHECK_SECURITY" = true ] && check_security || EXIT_CODE=1
    fi

    if [ "$POST_COMMENT" = true ]; then
        post_comment
    fi

    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        echo "$E_OK All checks passed!"
    else
        echo "$E_ERROR Some checks failed!"
    fi

    exit $EXIT_CODE
}

main

