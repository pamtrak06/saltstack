#!/bin/bash

export_path=_exports

# Creating the log file name
SCRIPT_NAME=$(basename "$0")
LOG_FILE="_logs/${SCRIPT_NAME%.sh}.log"

# Definition of color codes
RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
BLUE="\033[34m"

# Function to display usage information
usage() {
    echo "Usage: $0 <minion_prefix> <number_of_minions>"
    echo ""
    echo "This script exports Salt configuration files for a specified number of minions."
    echo "It takes two arguments:"
    echo "  <minion_prefix>   The prefix to use for naming minions."
    echo "  <number_of_minions> The total number of minions to export configurations for."
    echo ""
    echo "The exported configuration files will be saved in the directory: $export_path"
}

# Checking parameters
if [ $# -ne 2 ]; then
    usage
    exit 1
fi

# Defining the prefix for minions and the number of minions
MINION_PREFIX=$1
NUM_MINIONS=$2

# Function to display colored logs and write to the log file
log() {
    local level="$1"
    shift
    local message="$@"
    local log_message

    case "$level" in
        "INFO")
            log_message="${GREEN}[INFO] ${message}${RESET}"
            ;;
        "WARNING")
            log_message="${YELLOW}[WARNING] ${message}${RESET}"
            ;;
        "ERROR")
            log_message="${RED}[ERROR] ${message}${RESET}"
            ;;
        "DEBUG")
            log_message="${BLUE}[DEBUG] ${message}${RESET}"
            ;;
        *)
            log_message="[UNKNOWN] $message"
            ;;
    esac

    echo -e "$log_message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $message" >> "$LOG_FILE"
}

# Function to export Salt configuration files
export() {
    local node=$1
    local node_type=$2
    log "INFO" "[$node] Exporting ${node_type} configuration..."
    docker cp ${node}:/etc/salt/${node_type} ${export_path}/${node}_${node_type}
}

export salt_master master
export salt_syndic1 master
export salt_syndic1 minion
export salt_syndic2 master
export salt_syndic2 minion

for i in $(seq 1 $NUM_MINIONS); do
    export "${MINION_PREFIX}_salt_minion_$i" minion
done