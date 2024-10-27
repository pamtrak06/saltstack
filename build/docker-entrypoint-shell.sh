#!/bin/bash
set -e

# Exécution en fonction du type de serveur Salt
if [ "$SALT_TYPE" = "MASTER" ]; then
    echo "Starting Salt Master..."
    exec salt-master -l debug
elif [ "$SALT_TYPE" = "SYNDIC" ]; then
    #sed -i "s/id: .*/id: $SALT_HOSTNAME/g" >> /etc/salt/minion
    echo "id: $SALT_HOSTNAME" >> /etc/salt/minion
    echo "Starting Salt Syndic..."
    exec salt-master -l debug
    exec salt-syndic -l debug
    exec salt-minion -l debug
elif [ "$SALT_TYPE" = "MINION" ]; then
    #sed -i "s/id: .*/id: $(hostname)/g" >> /etc/salt/minion
    echo "id: $(hostname)" >> /etc/salt/minion
    echo "Starting Salt Minion..."
    exec salt-minion -l debug
else
    echo "Runtime Error: Invalid SALT_TYPE. Must be either MASTER, SYNDIC or MINION."
    exit 1
fi