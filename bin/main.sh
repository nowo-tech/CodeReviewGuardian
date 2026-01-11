#!/bin/sh
# main.sh
# Main script orchestrator for Code Review Guardian
# This is the actual implementation that runs from vendor directory

set -eu

# Get script directory (vendor/nowo-tech/code-review-guardian/bin)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PACKAGE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Source all sub-scripts in correct order
# 1. functions.sh - Common utilities (emojis, show_help, debug)
. "$SCRIPT_DIR/functions.sh"

# 2. config.sh - Configuration loading and parsing
. "$SCRIPT_DIR/config.sh"

# 3. review.sh - Code review execution functions
. "$SCRIPT_DIR/review.sh"

# 4. comments.sh - Comment posting and environment loading
. "$SCRIPT_DIR/comments.sh"

# Parse command line arguments
POST_COMMENT=false
DRY_RUN=false
DEBUG=false

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
        --debug)
            DEBUG=true
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
