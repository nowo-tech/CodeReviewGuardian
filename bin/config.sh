#!/bin/sh
# config.sh
# Configuration loading and parsing functions for Code Review Guardian

# Configuration file
CONFIG_FILE="code-review-guardian.yaml"

# Check if configuration file exists
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$E_ERROR Configuration file not found: $CONFIG_FILE"
        echo "$E_INFO Run 'composer install' to generate the configuration file."
        exit 1
    fi
}

# Parse YAML value (simple parser for key: value format)
parse_yaml_value() {
    local key="$1"
    local section="${2:-}"
    local default="${3:-}"

    if [ -n "$section" ]; then
        grep -A 20 "^${section}:" "$CONFIG_FILE" 2>/dev/null | grep "^\s*${key}:" | head -1 | awk -F: '{print $2}' | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//" || echo "$default"
    else
        grep "^${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | awk -F: '{print $2}' | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//" || echo "$default"
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
    debug "Config file path: $CONFIG_FILE"

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
