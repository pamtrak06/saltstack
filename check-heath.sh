#!/bin/bash
source config.sh
# Definition of color codes
RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
BLUE="\033[34m"

# Creating the log file name
SCRIPT_NAME=$(basename "$0")
LOG_FILE="_logs/${SCRIPT_NAME%.sh}.log"

# Function to display usage information
usage() {
    echo "Usage: $0 [<minion_prefix>] [<number_of_minions>]"
    echo ""
    echo "This script performs a health check on a SaltStack architecture."
    echo "It checks the status of the master, syndics, and minions."
    echo "It takes two optional arguments:"
    echo "  <minion_prefix>      The prefix to use for naming minions (default: 'test')."
    echo "  <number_of_minions>  The total number of minions to check (default: 3)."
    echo ""
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Setting default values
MINION_PREFIX=${1:-$CONFIG_MINION_PREFIX}
NUM_MINIONS=${2:-$CONFIG_NUM_MINIONS}

# Defining Salt components
MASTER="salt_master"
SYNDICS=("salt_syndic1" "salt_syndic2")

# Dynamically generating minion names with the new syntax
MINIONS=()
for i in $(seq 1 $NUM_MINIONS); do
    MINIONS+=("${MINION_PREFIX}_salt_minion_$i")
done

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

# Function to check the status of a container
check_container() {
    local container=$1
    if docker inspect -f '{{.State.Running}}' $container 2>/dev/null | grep -q "true"; then
        log "INFO" "[$container] Container is running"
    else
        log "ERROR" "[$container] Container is stopped or nonexistent"
        log "DEBUG" "Attempting to start container $container..."
        docker start $container
        sleep 5  # Wait for the container to start
        if docker inspect -f '{{.State.Running}}' $container 2>/dev/null | grep -q "true"; then
            log "INFO" "[$container] Container started successfully"
        else
            log "ERROR" "[$container] Failed to start container"
        fi
    fi
}

# Function to check connectivity of syndics/minions
check_connectivity() {
    local node=$1
    local node_type=$2
    if docker exec $MASTER salt "$node" test.ping --out=txt 2>/dev/null | grep -q "True"; then
        log "INFO" "[$node] Connected"
    else
        log "WARNING" "[$node] Not connected"
        log "DEBUG" "Checking keys for $node..."
        docker exec $MASTER salt-key -L | grep "$node"

        log "DEBUG" "Checking configuration of $node..."
        docker exec $node cat /etc/salt/minion | grep "^master:"

        log "DEBUG" "Checking logs of $node..."
        docker exec $node tail -n 20 /var/log/salt/$node_type

        log "DEBUG" "Attempting to restart Salt services on $node..."
        docker exec $node salt-call service.restart salt-$node_type
        docker exec $node salt-call service.restart salt-minion

        sleep 10  # Wait for services to restart

        log "DEBUG" "New connection attempt for $node..."
        if docker exec $MASTER salt "$node" test.ping --out=txt 2>/dev/null | grep -q "True"; then
            log "INFO" "[$node] Connected after restarting services"
        else
            log "ERROR" "[$node] Still not connected after restarting services"
            log "DEBUG" "Checking Salt versions..."
            docker exec $MASTER salt --versions-report
            docker exec $node salt --versions-report
        fi
    fi
}

log "INFO" "=== Starting health check ==="

# Checking the master
log "DEBUG" "=== Checking the Master ==="
check_container $MASTER

# Checking the syndics
log "DEBUG" "=== Checking the Syndics ==="
for syndic in "${SYNDICS[@]}"; do
    check_container $syndic
    check_connectivity "$syndic" "syndic"
done

# Checking the minions
log "DEBUG" "=== Checking the Minions ==="
for minion in "${MINIONS[@]}"; do
    check_container $minion
    check_connectivity "$minion" "minion"
done

# Checking versions
log "DEBUG" "=== Salt Versions ==="
docker exec $MASTER salt '*' test.version --out=txt 2>/dev/null || {
    log "ERROR" "Unable to obtain Salt versions"
    log "DEBUG" "Checking versions on the master..."
    docker exec $MASTER salt --versions-report
}

# Checking resource usage on the master
log "DEBUG" "=== Resource Usage on the Master ==="
docker stats $MASTER --no-stream --format "CPU: {{.CPUPerc}}\nMemory: {{.MemPerc}}\nDisk: {{.BlockIO}}" 2>/dev/null || {
    log "ERROR" "Unable to obtain statistics for master container"
}

# Checking keys
log "DEBUG" "=== Salt Key Status ==="
docker exec $MASTER salt-key -L 2>/dev/null || {
    log "ERROR" "Unable to obtain Salt key status"
    log "DEBUG" "Checking permissions for key directory..."
    docker exec $MASTER ls -l /etc/salt/pki/master/
}

log "INFO" "=== Health check completed ==="
log "INFO" "Logs have been recorded in $LOG_FILE"