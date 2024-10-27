#!/bin/bash
set -e

# Exécution en fonction du type de serveur Salt
if [ "$SALT_TYPE" = "MASTER" ]; then
    echo "Salt Master configuration preprocessing..."
elif [ "$SALT_TYPE" = "SYNDIC" ]; then
    echo "Salt Syndic configuration preprocessing..."
    echo "id: $SALT_HOSTNAME" >> /etc/salt/minion
elif [ "$SALT_TYPE" = "MINION" ]; then
    echo "Salt Minion configuration preprocessing..."
    echo "id: $(hostname)" >> /etc/salt/minion
else
    echo "Runtime Error: Invalid SALT_TYPE. Must be either MASTER, SYNDIC or MINION."
    exit 1
fi

supervisord -n -c /etc/supervisor/supervisord.conf
sleep 5
supervisorctl start all
supervisorctl status
exec tail -f /dev/null