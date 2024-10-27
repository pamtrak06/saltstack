#!/bin/bash

# Check if the syndic number is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <syndic_number>"
    exit 1
fi

# Get the syndic number from the argument
SYNDIC_NUMBER=$1

# Construct the syndic service name based on the provided number
SYNDIC_SERVICE="salt_syndic${SYNDIC_NUMBER}"

# Execute a bash shell in the specified syndic container
docker-compose -p test exec "$SYNDIC_SERVICE" bash