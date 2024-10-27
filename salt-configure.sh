#!/bin/bash
set -e

# Configuration du fichier /etc/salt/master
configure_master() {
    mv /etc/salt/master /etc/salt/master.template
    echo "interface: 0.0.0.0" >> /etc/salt/master
    echo "port: 4505" >> /etc/salt/master
    echo "publish_port: 4505" >> /etc/salt/master
    echo "ret_port: 4506" >> /etc/salt/master
}

# Configuration du fichier /etc/salt/minion pour le minion
configure_minion() {
    mv /etc/salt/minion /etc/salt/minion.template
    # sed -i "s|#master: salt|master: salt_master|g" /etc/salt/minion
    echo "master: salt_master" >> /etc/salt/minion
    # echo "master_port: 4506" >> /etc/salt/minion
    # echo "user: root" >> /etc/salt/minion
    # echo "pki_dir: /etc/salt/pki/minion" >> /etc/salt/minion
    # echo "cachedir: /var/cache/salt/minion" >> /etc/salt/minion
    # echo "log_level: error" >> /etc/salt/minion
    # echo "verify_env: True" >> /etc/salt/minion
    # echo "sudo_user: root" >> /etc/salt/minion
}

# Configuration des fichiers /etc/salt/master pour le syndic
configure_syndic() {
    mv /etc/salt/master /etc/salt/master.template
    echo "syndic_master: $SALT_MASTER" >> /etc/salt/master
    echo "syndic_log_file: /var/log/salt/syndic" >> /etc/salt/master
    echo "syndic_pidfile: /var/run/salt-syndic.pid" >> /etc/salt/master
    echo "master: localhost" >> /etc/salt/minion
}

# Configuration en fonction du type de serveur Salt
if [ "$SALT_TYPE" = "MASTER" ]; then
    echo "Configuring Salt Master..."
    configure_master
elif [ "$SALT_TYPE" = "SYNDIC" ]; then
    if [ -z "$SALT_MASTER" ]; then
        echo "Build Error: SALT_MASTER environment variable is required for SYNDIC configuration."
        exit 1
    fi
    echo "Configuring Salt Syndic..."
    configure_syndic
elif [ "$SALT_TYPE" = "MINION" ]; then
    if [ -z "$SALT_MASTER" ]; then
        echo "Build Error: SALT_MASTER environment variable is required for MINION configuration."
        exit 1
    fi
    echo "Configuring Salt Minion..."
    configure_minion
else
    echo "Build Error: Invalid SALT_TYPE. Must be either MASTER, SYNDIC or MINION."
    exit 1
fi