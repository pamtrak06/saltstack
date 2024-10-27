#!/bin/bash
set -e

# RunExécution en fonction du type de serveur Salt
if [ "$SALT_TYPE" = "MASTER" ]; then
    echo "Starting Salt Master..."
    exec salt-master -l debug
elif [ "$SALT_TYPE" = "SYNDIC" ]; then
    echo "id: $SALT_HOSTNAME" >> /etc/salt/minion
    echo "Starting Salt Syndic..."
    exec salt-syndic -l debug
elif [ "$SALT_TYPE" = "MINION" ]; then
    echo "id: $(hostname)" >> /etc/salt/minion
    echo "Starting Salt Minion..."
    exec salt-minion -l debug
else
    echo "Runtime Error: Invalid SALT_TYPE. Must be either MASTER, SYNDIC or MINION."
    exit 1
fi