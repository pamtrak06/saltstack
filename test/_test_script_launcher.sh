#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
required_commands=("jq" "timeout" "sed")
missing_commands=()

for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
        missing_commands+=("$cmd")
    fi
done

if [ ${#missing_commands[@]} -ne 0 ]; then
    echo "Error: The following required commands are missing:"
    for cmd in "${missing_commands[@]}"; do
        echo "  - $cmd"
    done
    echo "Please install these commands and try again."
    exit 1
fi

# Load configuration from config.json
if [ ! -f "./config.json" ]; then
    echo "Error: config.json not found in the current directory."
    exit 1
fi

# Extract variables from config.json
TEST_SCRIPTS_PATH=$(jq -r '.TEST_SCRIPTS_PATH' config.json)
LOG_PATH=$(jq -r '.LOG_PATH' config.json)
RESULTS_PATH=$(jq -r '.RESULTS_PATH' config.json)
KEYWORD=$(jq -r '.KEYWORD' config.json)
JSON_PREFIX=$(jq -r '.JSON_PREFIX' config.json)
GENERAL_PATH=$(jq -r '.GENERAL_PATH' config.json)

# Get the name of this script without extension
SCRIPT_NAME=$(basename "$0" .sh)

# Set log file path without timestamp in the name
LOG_FILE="${LOG_PATH}/${SCRIPT_NAME}.log"

# Set aggregated results file path without timestamp in the name
AGGREGATED_RESULTS="${RESULTS_PATH}/${SCRIPT_NAME}_aggregated_results.md"

# Function to write to log file
write_log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $1" >> "$LOG_FILE"
}

# Function to escape special characters for CSV
escape_csv() {
    echo "$1" | sed 's/;/\\;/g' | sed 's/"/"""/g'
}

# Function to escape special characters for Markdown
escape_md() {
    echo "$1" | sed 's/|/\\|/g' | sed 's/"/\\"/g'
}

# Ensure log and results directories exist
mkdir -p "$LOG_PATH"
mkdir -p "$RESULTS_PATH"

# Initialize counters
total_scripts=0
executed_scripts=0

# Initialize aggregated results with header including timestamp column
echo "| Test Name | Command | Rule | Status | Description | Timestamp |" > "$AGGREGATED_RESULTS"
echo "|-----------|---------|------|--------|-------------|-----------|" >> "$AGGREGATED_RESULTS"

# Function to execute tests
execute_tests() {
    for json_file in "$TEST_SCRIPTS_PATH"/${JSON_PREFIX}*${KEYWORD}*.json; do
        if [ -f "$json_file" ]; then
            json_name=$(basename "$json_file" .json)
            ((total_scripts++))
            write_log "Processing JSON file: $json_name"
            echo "Processing JSON file: $json_name"

            # Read JSON content
            json_content=$(cat "$json_file")

            # Extract command, expected return type, expected value, timeout, optional path, and description
            command=$(echo "$json_content" | jq -r '.command')
            expected_return_type=$(echo "$json_content" | jq -r '.expected_return_type')
            expected_value=$(echo "$json_content" | jq -r '.expected_value')
            timeout=$(echo "$json_content" | jq -r '.timeout // "60"')
            path=$(echo "$json_content" | jq -r '.path // "."')
            description=$(echo "$json_content" | jq -r '.description // ""')

            # Use GENERAL_PATH if path is equal to GENERAL_PATH or if it's NA/N/A; otherwise use the path from JSON.
            if [ "$path" = "NA" ] || [ "$path" = "N/A" ] || [ "$path" = "GENERAL_PATH" ]; then
                path="$GENERAL_PATH"
            fi

            # Resolve the absolute path for the command 
            full_command="$(cd "$path"; pwd)/$command"

            # Create CSV file for this execution without timestamp in the name
            csv_file="${RESULTS_PATH}/${SCRIPT_NAME}_results.csv"
            if [[ ! -f $csv_file ]]; then  # Write header only once.
                echo "Command;Rule;Log;Status;Description;Timestamp" > "$csv_file"
            fi

            # Change to the specified directory and execute the command, then return to the original directory.
            (
                cd "$path" || exit 1  # Change to the specified directory; exit if it fails.
                output=$(timeout "$timeout" bash -c "$command")  # Execute the command in the specified directory.
                exit_code=$?
                
                write_log "Command executed: $full_command (with timeout of ${timeout}s)"
                write_log "Command output:"
                write_log "$output"
                write_log "Return code: $exit_code"
                
                # Check if timeout was reached or if the command failed 
                if [ $exit_code -eq 124 ]; then
                    status="UNKNOWN"
                    rule="Timeout after ${timeout}s"
                else 
                    # Check result based on expected return type 
                    case "$expected_return_type" in 
                        "return code") 
                            rule="Exit code should be $expected_value"
                            if [ "$exit_code" -eq "$expected_value" ]; then 
                                status="SUCCESS"
                                ((executed_scripts++))
                            else 
                                status="FAILED"
                            fi 
                            ;; 
                        "grep output") 
                            rule="Output should contain '$expected_value'" 
                            if echo "$output" | grep -q "$expected_value"; then 
                                status="SUCCESS"
                                ((executed_scripts++))
                            else 
                                status="FAILED"
                            fi 
                            ;; 
                        *) 
                            status="UNKNOWN"
                            rule="Unrecognized expected return type"
                            ;; 
                    esac 
                fi 

                # Escape special characters for CSV and Markdown 
                escaped_command_csv=$(escape_csv "./$command") 
                escaped_rule_csv=$(escape_csv "$rule") 
                escaped_output_csv=$(escape_csv "$output") 
                escaped_description_csv=$(escape_csv "$description")

                escaped_command_md=$(escape_md "./$command") 
                escaped_rule_md=$(escape_md "$rule") 

                # Write to CSV file using semicolon as separator, including timestamp 
                echo "\"$escaped_command_csv\";\"$escaped_rule_csv\";\"$escaped_output_csv\";\"$status\";\"$escaped_description_csv\";\"$(date +"%Y-%m-%d %H:%M:%S")\"" >> "$csv_file"

                # Append to aggregated results in Markdown format including timestamp 
                echo "| $json_name | $escaped_command_md | $escaped_rule_md | $status | $description | $(date +"%Y-%m-%d %H:%M:%S") |" >> "$AGGREGATED_RESULTS"

                # Write to log 
                write_log "JSON file $json_name processed with status: $status"

                # Output to console 
                echo "Status: $status"
                echo "CSV file created: $csv_file"
                echo "----------------------------------------"
            )
        fi
    done
}

# Main execution 
write_log "Starting test execution for script: $SCRIPT_NAME"
echo "Starting test execution for script: $SCRIPT_NAME"

execute_tests

summary="All JSON files processed. Total JSON files matching keyword '$KEYWORD': $total_scripts, Successfully executed: $executed_scripts"
write_log "$summary"
echo "$summary"
echo "Aggregated results saved to: $AGGREGATED_RESULTS"