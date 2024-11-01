#!/bin/bash
source config.sh

# Definition of color codes
RESET="\033[0m"
GREEN="\033[32m"
RED="\033[31m"

# Creating the log file name
LOG_FILE="_logs/perform_functional_tests.log"

# Create the logs directory if it doesn't exist
mkdir -p _logs

# Command to perform functional tests
command="./docker-compose.sh exec salt_master salt '*' test.ping"

# Execute command and capture output
output=$(eval "$command 2>&1")

# Check if command was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[INFO] Functional tests executed successfully.${RESET}" | tee -a "$LOG_FILE"
    echo "Output: $output" >> "$LOG_FILE"
    echo "Result: Passed" >> "$LOG_FILE"
else
    echo -e "${RED}[ERROR] Functional tests failed.${RESET}" | tee -a "$LOG_FILE"
    echo "Output: $output" >> "$LOG_FILE"
    echo "Result: Failed" >> "$LOG_FILE"
fi