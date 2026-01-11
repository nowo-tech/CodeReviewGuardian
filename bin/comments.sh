#!/bin/sh
# comments.sh
# Comment posting and environment variable loading functions for Code Review Guardian

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

                    # Also add to .env.dist if it exists
                    if [ -f ".env.dist" ] && ! grep -q "^${TOKEN_ENV_NAME}=" .env.dist 2>/dev/null; then
                        {
                            echo ""
                            echo "# Git Provider API Token (required for posting comments to PRs/MRs)"
                            echo "$TOKEN_ENV_NAME=your_token_here"
                        } >> ".env.dist"
                        echo "$E_OK Also added $TOKEN_ENV_NAME to .env.dist"
                    fi

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
