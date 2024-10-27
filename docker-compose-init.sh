#!/bin/bash

# Source the configuration file
source config.sh

# Default options
EXPORT_CONFIG=false
CHECK_HEALTH=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --export-config|-x) EXPORT_CONFIG=true ;;  # Short option -x for export config
        --check-health|-c) CHECK_HEALTH=true ;;      # Short option -c for check health
        -h|--help) 
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --export-config, -x   Execute config-export.sh after starting containers"
            echo "  --check-health, -c     Execute check-health.sh after starting containers"
            echo "  -h, --help             Show this help message"
            exit 0
            ;;
        *) 
            echo "Unknown option: $1"
            exit 1 
            ;;
    esac
    shift
done

# Start the Docker containers with docker-compose
docker-compose -p $CONFIG_MINION_PREFIX up -d --build --scale salt_minion=$CONFIG_NUM_MINIONS

# Wait for a few seconds to ensure containers are up
sleep 10

# Execute config-export.sh if the flag is set
if [ "$EXPORT_CONFIG" = true ]; then
    ./config-export.sh
fi

sleep 10

# Execute check-health.sh if the flag is set
if [ "$CHECK_HEALTH" = true ]; then
    ./check-health.sh
fi