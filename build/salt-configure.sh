#!/bin/bash
set -e

# Configuration du fichier /etc/salt/master
configure_master() {
    mv /etc/salt/master /etc/salt/master.template
    cp salt_master_master /etc/salt/master
    
    # echo "auto_accept: True" >> /etc/salt/master
    # echo "interface: 0.0.0.0" >> /etc/salt/master
    # echo "publish_port: 4505" >> /etc/salt/master
    # echo "ret_port: 4506" >> /etc/salt/master
    
    # # configuration relative to salt-api (needed to use salt-api)
    # echo "netapi:">> /etc/salt/master
    # echo "  rest_cherrypy:">> /etc/salt/master
    # echo "    port: 8000">> /etc/salt/master
    # echo "    host: 0.0.0.0">> /etc/salt/master
}

# Configuration du fichier /etc/salt/minion pour le minion
configure_minion() {
    mv /etc/salt/minion /etc/salt/minion.template

    # spécifier plusieurs syndics comme masters dans le fichier /etc/salt/minion
    # répartition de la charge entre les deux syndics (options random_master, master_type)
    echo "master:" >> /etc/salt/minion
    echo "  - salt_syndic1" >> /etc/salt/minion
    echo "  - salt_syndic2" >> /etc/salt/minion
    echo "random_master: True" >> /etc/salt/minion
    echo "master_type: failover" >> /etc/salt/minion

    #echo "id: minionname" >> /etc/salt/minion
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
    #echo "master: localhost" >> /etc/salt/master
    echo "syndic_master: $SALT_MASTER_NAME" >> /etc/salt/master
    echo "syndic_master_port: 4506" >> /etc/salt/master
    # echo "syndic_log_file: /var/log/salt/syndic" >> /etc/salt/master
    # echo "syndic_pidfile: /var/run/salt-syndic.pid" >> /etc/salt/master
    echo "order_masters: True" >> /etc/salt/master
    echo "syndic_wait: 30" >> /etc/salt/master
    echo "file_roots:" >> /etc/salt/master
    echo "  base:" >> /etc/salt/master
    echo "    - /srv/salt" >> /etc/salt/master
    
    mv /etc/salt/minion /etc/salt/minion.template
    echo "master: $SALT_MASTER_NAME" >> /etc/salt/minion
    echo "file_client: remote" >> /etc/salt/minion
    echo "pki_dir: /etc/salt/pki/minion" >> /etc/salt/minion
    # echo "id: $SALT_HOSTNAME" > /etc/salt/minion
}

# Configuration en fonction du type de serveur Salt
if [ "$SALT_NODE_TYPE" = "MASTER" ]; then
    echo "Configuring Salt Master..."
    cp docker-entrypoint-shell.sh ./docker-entrypoint.sh
    rm -f supervisord-syndic.conf
    configure_master
elif [ "$SALT_NODE_TYPE" = "SYNDIC" ]; then
    if [ -z "$SALT_MASTER_NAME" ]; then
        echo "Build Error: SALT_MASTER_NAME environment variable is required for SYNDIC configuration."
        exit 1
    fi
    echo "Configuring Salt Syndic..."
    cp docker-entrypoint-supervisor.sh ./docker-entrypoint.sh
    rm -f docker-entrypoint-shell.sh
    cp supervisord-syndic.conf /etc/supervisor/conf.d/supervisord.conf
    configure_syndic
elif [ "$SALT_NODE_TYPE" = "MINION" ]; then
    if [ -z "$SALT_MASTER_NAME" ]; then
        echo "Build Error: SALT_MASTER_NAME environment variable is required for MINION configuration."
        exit 1
    fi
    echo "Configuring Salt Minion..."
    cp docker-entrypoint-shell.sh ./docker-entrypoint.sh
    rm -f supervisord-syndic.conf
    configure_minion
else
    echo "Build Error: Invalid SALT_NODE_TYPE. Must be either MASTER, SYNDIC or MINION."
    exit 1
fi