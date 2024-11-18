#!/bin/bash
source config.sh
# Check if the minion number is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <minion_number>"
    exit 1
fi

# Get the minion number from the argument
MINION_NUMBER=$1

# Construct the minion service name based on the provided number
MINION_SERVICE="salt-minion"

# Execute a bash shell in the specified minion container
docker-compose -p $CONFIG_COMPOSE_PREFIX exec --index="$MINION_NUMBER" "$MINION_SERVICE" bash
