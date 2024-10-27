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

# Create the reports directory if it doesn't exist
mkdir -p _reports

# Create a timestamp for the report filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="_reports/health_check_report_$TIMESTAMP.md"

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

# Function to handle cleanup
cleanup() {
    echo "Cleaning up..."
    # Finalize writing or any necessary cleanup actions here
    echo -e "$REPORT_CONTENT" > "$REPORT_FILE"
    echo "Report generated at: $REPORT_FILE"
}

# Set up the trap to call cleanup on SIGINT (Ctrl-C)
trap cleanup SIGINT

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

# Initialize report content
REPORT_CONTENT="| Test | Command | Output | Result |\n|------|---------|--------|--------|\n"

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

    # Output to console and log file
    echo -e "$log_message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $message" >> "$LOG_FILE"
}

# Function to escape pipes in strings for Markdown formatting
escape_pipes() {
    echo "$1" | sed 's/|/\\|/g'
}

# Function to log results in report format
log_report() {
    local test="$1"
    local command="$2"  # Keep command as a string without executing it
    local output="$3"
    local result="$4"

    REPORT_CONTENT+="| $test | \`$(escape_pipes "$command")\` | $(escape_pipes "$output") | $result |\n"  # Escape pipes in command and output for Markdown
}

# Function to check the status of a container
check_container() {
    local container=$1
    local command="docker inspect -f '{{.State.Running}}' $container"

    if eval "$command 2>/dev/null | grep -q 'true'"; then
        local output="Container is running."
        log "INFO" "[$container] Container is running"
        log_report "Check Container for $container" "$command" "$output" "Passed"
    else
        local output="Container is stopped or nonexistent."
        log "ERROR" "[$container] Container is stopped or nonexistent"
        log_report "Check Container for $container" "$command" "$output" "Failed"

        log "DEBUG" "Attempting to start container $container..."
        command="docker start $container"
        
        # Capture output from starting the container.
        output=$(eval "$command 2>&1")  # Capture output and errors
        
        sleep 5  # Wait for the container to start
        
        if eval "$command; docker inspect -f '{{.State.Running}}' $container 2>/dev/null | grep -q 'true'; then"; then
            output="Container started successfully."
            log "INFO" "[$container] Container started successfully"
            log_report "Check Container for $container" "$command" "$output" "Passed"
        else
            output="Failed to start container. Output: $output"
            log "ERROR" "[$container] Failed to start container: $output"
            log_report "Check Container for $container" "$command" "$output" "Failed"
        fi
    fi
}

# Function to check connectivity of syndics/minions
check_connectivity() {
    local node=$1
    local node_type=$2
    
    # Command for checking connectivity.
    local command="docker exec $MASTER salt \"$node\" test.ping --out=txt"

    if eval "$command 2>/dev/null | tee -a \"$LOG_FILE\" | grep -q \"True\""; then
        local output="[INFO] Connected to $node."
        log "INFO" "[$node] Connected"
        log_report "Connectivity Check for $node ($node_type)" "$command" "$output" "Passed"
    else
        local output="[WARNING] Not connected for $node."
        log "WARNING" "[$node] Not connected"
        log_report "Connectivity Check for $node ($node_type)" "$command" "$output" "Failed"

        # Log key status and configuration details, redirecting output to the log file.
        {
            log "DEBUG" "Checking keys for $node..."
            docker exec $MASTER salt-key -L | tee -a "$LOG_FILE"

            # Log key checking as well.
            log_report "Key Check for $node ($node_type)" "$command" "[DEBUG] Checking keys for $node on master." ""

            log "DEBUG" "Checking configuration of $node..."
            command="docker exec $node cat /etc/salt/minion | grep '^master:'"
            eval "$command | tee -a \"$LOG_FILE\""

            log_report "Configuration Check for $node ($node_type)" "$command" "[DEBUG] Configuration checked for $node." ""

            log "DEBUG" "Checking logs of $node..."
            command="docker exec $node tail -n 20 /var/log/salt/$node_type"
            eval "$command | tee -a \"$LOG_FILE\""

            log_report "Log Check for $node ($node_type)" "$command" "[DEBUG] Logs checked for $node." ""

            log "DEBUG" "Attempting to restart Salt services on $node..."
            command="docker exec $node salt-call service.restart salt-$node_type >> \"$LOG_FILE\" 2>&1 && docker exec $node salt-call service.restart salt-minion >> \"$LOG_FILE\" 2>&1"
            
            eval "$command"

            # Log restart attempt result.
            if [[ $? -eq 0 ]]; then
                log_report "Service Restart Check for $node ($node_type)" "$command" "[DEBUG] Services restarted successfully on $node." ""
            else 
                log_report "Service Restart Check for $node ($node_type)" "$command" "[ERROR] Failed to restart services on $node." ""
            fi 
        } 

        sleep 10  # Wait for services to restart

        # New connection attempt after restart, redirecting output.
        if eval "$command 2>/dev/null | tee -a \"$LOG_FILE\" | grep -q \"True\""; then
            local output="[INFO] Connected after restarting services."
            log "INFO" "[$node] Connected after restarting services"
            log_report "Connectivity Check After Restart for $node ($node_type)" "$command" "$output" "Passed"
        else
            local output="[ERROR] Still not connected after restarting services."
            log "ERROR" "[$node] Still not connected after restarting services"
            log_report "Connectivity Check After Restart for $node ($node_type)" "$command" "$output" "Failed"

            {
                log DEBUG "--- Checking Salt versions ---"
                docker exec $MASTER salt --versions-report | tee -a "$LOG_FILE"
                docker exec $node salt --versions-report | tee -a "$LOG_FILE"

                # Log version checks as well.
                log_report "--- Version Check ---" "--- Checking Salt versions on master and node --- "" Logged "
                
                }
        fi
    fi
}

log INFO "--- Starting health check ---"

# Checking communication between syndics and master

for syndic in "${SYNDICS[@]}"; do

    # Test if syndic can reach master through ping command.
    command="./docker-compose.sh exec ${syndic} ping -c 4 ${MASTER}"
    
    if eval "${command}"; then 
        output="[INFO] ${syndic} can reach ${MASTER} via ping."
        result="Passed"
    else 
        output="[ERROR] ${syndic} cannot reach ${MASTER} via ping."
        result="Failed"
    fi
    
   # Log result of ping test.
   log_report "Ping Test from ${syndic} to ${MASTER}" "${command}" "${output}" "${result}"

   # Test if syndic can reach master through Salt command.
   command="./docker-compose.sh exec ${syndic} salt ${MASTER} test.ping"

   if eval "${command}"; then 
       output="[INFO] ${syndic} can reach ${MASTER} via Salt command."
       result="Passed"
   else 
       output="[ERROR] ${syndic} cannot reach ${MASTER} via Salt command."
       result="Failed"
   fi
   
   # Log result of Salt command test.
   log_report "Salt Command Test from ${syndic} to ${MASTER}" "${command}" "${output}" "${result}"

done

# Check if syndic keys are accepted from master.
for syndic in "${SYNDICS[@]}"; do 
   command="./docker-compose.sh exec ${MASTER} salt-key -L"

   if eval "${command}"; then 
       output="[INFO] Keys are accepted from master."
       result="Passed"
   else 
       output="[ERROR] Keys are not accepted from master."
       result="Failed"
   fi
   
   # Log result of key acceptance test.
   log_report "Key Acceptance Test from Master to ${syndic}" "${command}" "${output}" "${result}"
done

# Accept syndic keys from master.
for syndic in "${SYNDICS[@]}"; do 
   command="./docker-compose.sh exec ${MASTER} salt-key -A"

   if eval "${command}"; then 
       output="[INFO] Syndic keys accepted by master."
       result="Passed"
   else 
       output="[ERROR] Syndic keys not accepted by master."
       result="Failed"
   fi
   
   # Log result of accepting keys test.
   log_report "Accept Syndic Keys from Master to ${syndic}" "${command}" "${output}" "${result}"
done

# Ensure that the Salt services are running correctly on both the master and syndic.
for syndic in "${SYNDICS[@]}"; do 
   command="docker exec ${syndic} service salt-minion status"

   if eval "${command}"; then 
       output="[INFO] Salt Minion service is running on ${syndic}."
       result="Passed"
   else 
       output="[ERROR] Salt Minion service is NOT running on ${syndic}."
       result="Failed"
   fi
   
   # Log result of service status check.
   log_report "Salt Minion Service Status on ${syndic}" "${command}" "${output}" "${result}"

done

for syndic in "${SYNDICS[@]}"; do 
   command="docker exec ${syndic} service salt-master status"

   if eval "${command}"; then 
       output="[INFO] Salt Master service is running on ${syndic}."
       result="Passed"
   else 
       output="[ERROR] Salt Master service is NOT running on ${syndic}."
       result="Failed"
   fi
   
   # Log result of service status check.
   log_report "Salt Master Service Status on ${syndic}" "${command}" "${output}" "${result}"

done

for syndic in "${SYNDICS[@]}"; do 
   command="docker exec ${syndic} service salt-syndic status"

   if eval "${command}"; then 
       output="[INFO] Salt Syndic service is running on ${syndic}."
       result="Passed"
   else 
       output="[ERROR] Salt Syndic service is NOT running on ${syndic}."
       result="Failed"
   fi
   
   # Log result of service status check.
   log_report "Salt Syndic Service Status on ${syndic}" "${command}" "${output}" "${result}"

done

# Check logs for any errors or warnings that may indicate what is wrong. 
for syndic in "${SYNDICS[@]}"; do 
   command="docker exec ${syndic} tail -n 100 /var/log/salt/minion"

   if eval "${command}"; then 
       output="[INFO] Logs checked successfully on ${syndic}. No errors found."
       result="Passed!"
   else 
       output="[WARNING] Errors found in logs on ${syndic}. Please check manually."
       result="Warning: Review logs!"
   fi
   
   # Log result of logs check.
   log_report "Log Check on ${syndic}" "${command}" "${output}" "${result}"

done

# Ensure that there are no firewall rules blocking communication between the syndic and master, especially on ports 4505 and 4506.
for syndic in "${SYNDICS[@]}"; do 

     command="docker exec ${syndic} netstat -tuln | grep 4505"

     if eval "${command}"; then 
         output="[INFO] Port 4505 is open on ${syndic}. No firewall issues detected."
         result="Passed!"
     else 
         output="[ERROR] Port 4505 is NOT open on ${syndic}. Firewall issues detected!"
         result="Failed!"
         
     fi
   
     # Log result of firewall check.
     log_report "Firewall Check Port 4505 on ${syndic}" "${command}" "${output}" "${result}"

done 

for syndic in "${SYNDICS[@]}"; do 

     command="docker exec ${syndic} netstat -tuln | grep 4506"

     if eval "${command}"; then  
         output="[INFO] Port 4506 is open on ${syndic}. No firewall issues detected."
         result="Passed!"
     else  
         output="[ERROR] Port 4506 is NOT open on ${syndic}. Firewall issues detected!"
         result="Failed!"
         
     fi
  
     # Log result of firewall check.
     log_report "Firewall Check Port 4506 on ${syndic}" "${command}" "${output}" "${result}"

done 

# Verify that the minion configuration file (/etc/salt/minion) has the correct master address set.
for syndic in "${SYNDICS[@]}"; do 

     command="docker exec -it salt_syndic1 cat /etc/salt/minion | grep master:"

     if eval "${command}"; then  
         output="[INFO] Master address correctly set in minion config file on ${syndic}. "
         result="Passed!"
     else  
         output="[ERROR] Master address NOT correctly set in minion config file on ${syndic}. "
         result="Failed!"
         
     fi
  
     # Log result of configuration check.
     log_report "Minion Config Check on ${syndics[i]}" "${command}" "${output}" "${result}"

done 

log INFO "--- Health check completed ---"

# Write report content to Markdown file.
echo -e "$REPORT_CONTENT" > "$REPORT_FILE"

log INFO "--- Report generated at: $REPORT_FILE ---"
