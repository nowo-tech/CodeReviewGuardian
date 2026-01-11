#!/bin/sh
# code-review-guardian.sh
# Minimal entry point script that delegates to the actual implementation in vendor
#
# This script is installed in the project root and serves as a lightweight wrapper
# that locates and executes the main script from the vendor directory.

set -e

# Find vendor directory (look for vendor/composer/autoload.php or vendor/autoload.php)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VENDOR_DIR=""

# Try to find vendor directory
if [ -d "$SCRIPT_DIR/vendor" ]; then
    VENDOR_DIR="$SCRIPT_DIR/vendor"
elif [ -d "$SCRIPT_DIR/../vendor" ]; then
    VENDOR_DIR="$SCRIPT_DIR/../vendor"
else
    # Try to locate vendor by finding composer.json and looking for vendor sibling
    if [ -f "$SCRIPT_DIR/composer.json" ]; then
        VENDOR_DIR="$SCRIPT_DIR/vendor"
    elif [ -f "$SCRIPT_DIR/../composer.json" ]; then
        VENDOR_DIR="$SCRIPT_DIR/../vendor"
    fi
fi

# Package directory in vendor
PACKAGE_DIR="$VENDOR_DIR/nowo-tech/code-review-guardian"
MAIN_SCRIPT="$PACKAGE_DIR/bin/main.sh"

# Check if package is installed
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "❌ Code Review Guardian package not found in vendor directory."
    echo "   Please run: composer install"
    exit 1
fi

# Execute the main script from vendor, passing all arguments
exec "$MAIN_SCRIPT" "$@"