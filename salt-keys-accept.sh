#!/bin/bash

# Get the short name of the script (without the path)
SCRIPT_NAME=$(basename "$0")
LOG_FILE="_logs/${SCRIPT_NAME%.*}.log"

# Function to log messages
log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Redirect stderr to stdout
exec 2>&1

# Function to execute commands on a syndic and log the results
run_on_syndic() {
    local syndic=$1
    local command=$2
    log "Executing on $syndic: $command"
    docker exec $syndic $command 2>&1 | tee -a "$LOG_FILE"
    log ""
}

# Start of the script
log "Operations on syndic keys - $(date)"

for syndic in salt_syndic1 salt_syndic2
do
    log "=== Operations on $syndic ==="
    
    # Initial key list
    run_on_syndic $syndic "salt-key -L"
    
    # Accept all keys
    log "Accepting all keys on $syndic"
    run_on_syndic $syndic "salt-key -A -y"
    
    # New key list after acceptance
    log "New key list on $syndic after acceptance:"
    run_on_syndic $syndic "salt-key -L"
    
    log ""
done

log "Operations completed. Check $LOG_FILE for details."