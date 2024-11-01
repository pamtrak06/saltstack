# Test de ping depuis le master sur tous les minions
```bash
./docker-compose.sh exec salt_master salt '*' test.ping
    No minions matched the target. No command was sent, no jid was assigned.
    ERROR: No return received
```

# Test des acceptations de clés
```bash
./docker-compose.sh exec salt_master salt-key -L
    Accepted Keys:
    salt_syndic1
    salt_syndic2
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:
```

# Test de ping sur les syndics
```bash
./docker-compose.sh exec salt_master salt 'salt_syndic1' test.ping
    salt_syndic1:
        True
./docker-compose.sh exec salt_master salt 'salt_syndic2' test.ping
    salt_syndic2:
        True
```

# Test de l'ouverture des ports 4505 et 4506
```bash
./docker-compose.sh exec salt_master netstat -tulpn | grep -E '4505|4506'
    tcp        0      0 0.0.0.0:4505            0.0.0.0:*               LISTEN      59/python3          
    tcp        0      0 0.0.0.0:4506            0.0.0.0:*               LISTEN      65/python3  

./docker-compose.sh exec salt_master netstat -a|grep 4505
    tcp        0      0 0.0.0.0:4505            0.0.0.0:*               LISTEN     
    tcp        0      0 b7490fb0b994:4505       salt_syndic1.salt:37762 ESTABLISHED
    tcp        0      0 b7490fb0b994:4505       salt_syndic1.salt:37734 ESTABLISHED
    tcp        0      0 b7490fb0b994:4505       salt_syndic2.salt:47202 ESTABLISHED
    tcp        0      0 b7490fb0b994:4505       salt_syndic2.salt:47184 ESTABLISHED

./docker-compose.sh exec salt_master netstat -a|grep 4506
    tcp        0      0 0.0.0.0:4506            0.0.0.0:*               LISTEN     
    tcp        0      0 b7490fb0b994:4506       salt_syndic1.salt:46854 ESTABLISHED
    tcp        0      0 b7490fb0b994:4506       salt_syndic2.salt:45828 ESTABLISHED
    tcp        0      0 b7490fb0b994:4506       salt_syndic2.salt:44440 ESTABLISHED
    tcp        0      0 b7490fb0b994:4506       salt_syndic1.salt:47704 ESTABLISHED
```

# Logs du master
```bash
./docker-compose.sh logs salt_master salt_syndic1 salt_syndic2|grep ERR
    salt_master     | [ERROR   ] ReqServer clients tcp://0.0.0.0:4506
    salt_master     | [ERROR   ] ReqServer workers ipc:///var/run/salt/master/workers.ipc
    salt_master     | [ERROR   ] An extra return was detected from minion salt_syndic1, please verify the minion, this could be a replay attack
```
# ----------------------------------------------------------
# Contexte de définition de l'incident
## 1. master (salt_master) with following configuration
```bash
    # Enable auto-acceptance of minion keys
    auto_accept: True

    # NetAPI configuration for RESTful API access
    netapi:
    rest_cherrypy:
        port: 8000          # Port on which the API will listen
        host: 0.0.0.0      # Listen on all interfaces
        # Optionally enable authentication
        # auth:
        #   type: basic
        #   username: your_username
        #   password: your_password

    # Other essential configurations (optional)
    interface: 0.0.0.0      # Listen on all interfaces
    publish_port: 4505      # Port for publishing messages
    ret_port: 4506          # Port for minion results
    pki_dir: /etc/salt/pki  # Directory for PKI keys

    file_roots:
    base:
        - /srv/salt         # Directory where state files are located

    log_level: info         # Logging level
```

## 2. 2 syndics (salt_syndic1 & salt_syndic2) with following configurations
# /etc/salt/master
```bash
syndic_master: salt_master
syndic_log_file: /var/log/salt/syndic
syndic_pidfile: /var/run/salt-syndic.pid
order_masters: True
```
# /etc/salt/minion
```bash
master: salt_master
id: salt_syndic1
```

Test de ping depuis le master sur tous les minions
```bash
./docker-compose.sh exec salt_master salt '*' test.ping
No minions matched the target. No command was sent, no jid was assigned.
ERROR: No return received
```

```bash
docker-compose logs salt_master |grep ERR

salt_master     | [ERROR   ] ReqServer clients tcp://0.0.0.0:4506
salt_master     | [ERROR   ] ReqServer workers ipc:///var/run/salt/master/workers.ipc
salt_master     | [ERROR   ] An extra return was detected from minion salt_syndic1, please verify the minion, this could be a replay attack
```
# ----------------------------------------------------------

# Test de ping salt à partir du master en debug
```bash
./docker-compose.sh exec salt_master salt '*' test.ping -l debug
    [DEBUG   ] Reading configuration from /etc/salt/master
    [DEBUG   ] Using cached minion ID from /etc/salt/minion_id: b7490fb0b994
    [DEBUG   ] Missing configuration file: /root/.saltrc
    [WARNING ] Insecure logging configuration detected! Sensitive data may be logged.
    [DEBUG   ] Configuration file path: /etc/salt/master
    [DEBUG   ] Reading configuration from /etc/salt/master
    [DEBUG   ] Using cached minion ID from /etc/salt/minion_id: b7490fb0b994
    [DEBUG   ] Missing configuration file: /root/.saltrc
    [DEBUG   ] MasterEvent PUB socket URI: /var/run/salt/master/master_event_pub.ipc
    [DEBUG   ] MasterEvent PULL socket URI: /var/run/salt/master/master_event_pull.ipc
    [DEBUG   ] Closing AsyncReqChannel instance
    No minions matched the target. No command was sent, no jid was assigned.
    [DEBUG   ] The functions from module 'nested' are being loaded by dir() on the loaded module
    [DEBUG   ] LazyLoaded nested.output
    ERROR: No return received
    [DEBUG   ] Closing IPCMessageSubscriber instance
```

```bash
./docker-compose.sh exec salt_master salt-run cache.clear_all
./docker-compose.sh exec salt_master rm -rf /etc/salt/pki/master/minions/*
./docker-compose.sh exec salt_syndic1 rm -rf /etc/salt/pki/minion/*
./docker-compose.sh exec salt_syndic2 rm -rf /etc/salt/pki/minion/*
```

```bash
./docker-compose.sh logs salt_syndic1 salt_syndic2
Attaching to salt_syndic2, salt_syndic1
    salt_syndic1    | Salt Syndic configuration preprocessing...
    salt_syndic1    | 2024-10-27 20:55:28,502 CRIT Supervisor running as root (no user in config file)
    salt_syndic1    | 2024-10-27 20:55:28,502 INFO Included extra file "/etc/supervisor/conf.d/supervisord.conf" during parsing
    salt_syndic1    | 2024-10-27 20:55:28,510 INFO RPC interface 'supervisor' initialized
    salt_syndic1    | 2024-10-27 20:55:28,519 CRIT Server 'unix_http_server' running without any HTTP authentication checking
    salt_syndic1    | 2024-10-27 20:55:28,520 INFO supervisord started with pid 6
    salt_syndic1    | 2024-10-27 20:55:29,523 INFO spawned: 'salt-minion' with pid 9
    salt_syndic1    | 2024-10-27 20:55:29,526 INFO spawned: 'salt-syndic' with pid 10
    salt_syndic1    | 2024-10-27 20:55:29,528 INFO spawned: 'salt-master' with pid 11
    salt_syndic1    | 2024-10-27 20:55:30,549 INFO success: salt-minion entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
    salt_syndic1    | 2024-10-27 20:55:30,549 INFO success: salt-syndic entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
    salt_syndic1    | 2024-10-27 20:55:30,549 INFO success: salt-master entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
    salt_syndic2    | Salt Syndic configuration preprocessing...
    salt_syndic2    | 2024-10-27 20:55:28,333 CRIT Supervisor running as root (no user in config file)
    salt_syndic2    | 2024-10-27 20:55:28,333 INFO Included extra file "/etc/supervisor/conf.d/supervisord.conf" during parsing
    salt_syndic2    | 2024-10-27 20:55:28,383 INFO RPC interface 'supervisor' initialized
    salt_syndic2    | 2024-10-27 20:55:28,383 CRIT Server 'unix_http_server' running without any HTTP authentication checking
    salt_syndic2    | 2024-10-27 20:55:28,384 INFO supervisord started with pid 6
    salt_syndic2    | 2024-10-27 20:55:29,388 INFO spawned: 'salt-minion' with pid 9
    salt_syndic2    | 2024-10-27 20:55:29,390 INFO spawned: 'salt-syndic' with pid 10
    salt_syndic2    | 2024-10-27 20:55:29,392 INFO spawned: 'salt-master' with pid 11
    salt_syndic2    | 2024-10-27 20:55:30,397 INFO success: salt-minion entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
    salt_syndic2    | 2024-10-27 20:55:30,397 INFO success: salt-syndic entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
    salt_syndic2    | 2024-10-27 20:55:30,401 INFO success: salt-master entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
```

# Option order_masters

## Présentation
L'option order_masters: True dans la configuration du master Salt est importante pour le fonctionnement correct d'une topologie utilisant des syndics. Voici les points clés à comprendre sur cette option :

## Objectif principal :
Cette option indique au master de niveau supérieur qu'il doit envoyer des informations supplémentaires avec ses publications pour contrôler correctement les masters de niveau inférieur via les syndics4.

## Utilisation :
Elle doit être configurée sur le master de niveau supérieur (parfois appelé "Master of Masters") qui contrôle un ou plusieurs syndics3.

## Fonctionnement :
Quand order_masters est défini à True, le master envoie des données supplémentaires avec ses publications. Ces données sont nécessaires pour que les commandes soient correctement transmises à travers les différents niveaux de la hiérarchie des masters4.

## Impact :
Sans cette option activée, le master de niveau supérieur ne pourrait pas contrôler efficacement les minions connectés aux masters de niveau inférieur via les syndics3.

## Configuration :
Elle doit être ajoutée dans le fichier de configuration du master de niveau supérieur (/etc/salt/master)4.

## Exemple de configuration :
text
order_masters: True

## Importance dans une topologie avec syndics :
Cette option est cruciale pour permettre la propagation correcte des commandes et des événements à travers les différents niveaux de la hiérarchie Salt34.
Il est important de noter que cette option ne doit être configurée que sur le master de niveau supérieur dans une topologie utilisant des syndics. Les masters de niveau inférieur et les syndics eux-mêmes n'ont pas besoin de cette configuration.

# Identification de la Root cause

L'option `order_masters: True` était positionnée dans le fichier /etc/salt/master des syndics au lieu du fichier de configuration /etc/salt/master dans le master

```bash
./docker-compose.sh exec salt_master salt '*' test.ping
    [DEBUG   ] Configuration file path: /etc/salt/master
    [DEBUG   ] Reading configuration from /etc/salt/master
    [DEBUG   ] Missing configuration file: /root/.saltrc
    [DEBUG   ] MasterEvent PUB socket URI: /var/run/salt/master/master_event_pub.ipc
    [DEBUG   ] MasterEvent PULL socket URI: /var/run/salt/master/master_event_pull.ipc
    [DEBUG   ] Closing AsyncReqChannel instance
    [DEBUG   ] The functions from module 'local_cache' are being loaded by dir() on the loaded module
    [DEBUG   ] LazyLoaded local_cache.get_load
    [DEBUG   ] Reading minion list from /var/cache/salt/master/jobs/7e/2be29cf1ddc9d451b208fe98aa2e3118c7f33106873f7e2fe29188b85b1a49/.minions.p
    [DEBUG   ] get_iter_returns for jid 20241030220655527560 sent to set() will timeout at 22:07:00.557179
    [DEBUG   ] Checking whether jid 20241030220655527560 is still running
    [DEBUG   ] Closing AsyncReqChannel instance
    [DEBUG   ] retcode missing from client return
    [DEBUG   ] Closing IPCMessageSubscriber instance
```

# Noeud master
## Fichier /etc/salt/master
```
auto_accept: True
order_masters: True
log_level: debug
```

# Noeud syndic1
## Fichier /etc/salt/master
```bash
syndic_master: salt_master
```
## Fichier /etc/salt/minion
```bash
id: salt_syndic1
```

# Noeud syndic2
## Fichier /etc/salt/master
```bash
syndic_master: salt_master
```
## Fichier /etc/salt/minion
```bash
id: salt_syndic2
```

Nouvelle erreur identifiée : `[DEBUG   ] retcode missing from client return`

```bash
./docker-compose.sh exec salt_master salt-run manage.status -l info
[INFO    ] Although 'dmidecode' was found in path, the current user cannot execute it. Grains output might not be accurate.
down:
    - salt_syndic1
    - salt_syndic2
up:
```

```bash
./docker-compose.sh logs salt_master |grep ERR
salt_master     | [ERROR   ] ReqServer clients tcp://0.0.0.0:4506
salt_master     | [ERROR   ] ReqServer workers ipc:///var/run/salt/master/workers.ipc
```

Test de vérification que les services sont bien démarrés
```bash
./docker-compose.sh exec salt_syndic1 service salt-syndic status
 * salt-syndic is running
./docker-compose.sh exec salt_syndic1 service salt-master status
 * salt-master is running
 ```

Vérification des ouvertures de ports
```bash
./docker-compose.sh exec salt_master netstat -tulpn | grep -E '4505|4506'
tcp        0      0 0.0.0.0:4505            0.0.0.0:*               LISTEN      59/python3          
tcp        0      0 0.0.0.0:4506            0.0.0.0:*               LISTEN      65/python3          
./docker-compose.sh exec salt_syndic1 netstat -tulpn | grep -E '4505|4506'
tcp        0      0 0.0.0.0:4505            0.0.0.0:*               LISTEN      121/python3         
tcp        0      0 0.0.0.0:4506            0.0.0.0:*               LISTEN      130/python3         
./docker-compose.sh exec salt_syndic2 netstat -tulpn | grep -E '4505|4506'
tcp        0      0 0.0.0.0:4505            0.0.0.0:*               LISTEN      126/python3         
tcp        0      0 0.0.0.0:4506            0.0.0.0:*               LISTEN      132/python3
```

Essayez d'exécuter une commande directement sur un syndic pour vérifier sa connectivité avec le master :
```bash
./docker-compose.sh exec salt_syndic1 salt-call test.ping
[ERROR   ] DNS lookup or connection check of 'salt' failed.
[ERROR   ] Master hostname: 'salt' not found or not responsive. Retrying in 30 seconds

./docker-compose.sh exec salt_syndic2 salt-call test.ping
[ERROR   ] DNS lookup or connection check of 'salt' failed.
[ERROR   ] Master hostname: 'salt' not found or not responsive. Retrying in 30 seconds
```

# Identification de la Root cause

Dans les fichiers de configuration /etc/salt/minion des syndic, il manquait le noeud master

# Noeud master
## Fichier /etc/salt/master
```
auto_accept: True
order_masters: True
log_level: debug
```

# Noeud syndic1
## Fichier /etc/salt/master
```bash
syndic_master: salt_master
```
## Fichier /etc/salt/minion
```bash
master: salt_master
id: salt_syndic1
```

# Noeud syndic2
## Fichier /etc/salt/master
```bash
syndic_master: salt_master
```
## Fichier /etc/salt/minion
```bash
master: salt_master
id: salt_syndic2
```

Résultat des commandes :
```bash
./docker-compose.sh exec salt_syndic1 salt-call test.ping
    local:
        True
./docker-compose.sh exec salt_syndic2 salt-call test.ping
    local:
        True
```

```bash
./docker-compose.sh logs salt_master |grep ERR
salt_master     | [ERROR   ] ReqServer clients tcp://0.0.0.0:4506
salt_master     | [ERROR   ] ReqServer workers ipc:///var/run/salt/master/workers.ipc
```

```bash
./docker-compose.sh exec salt_master salt-run manage.status -l info
[INFO    ] Although 'dmidecode' was found in path, the current user cannot execute it. Grains output might not be accurate.
down:
up:
    - salt_syndic1
    - salt_syndic2
[INFO    ] Runner completed: 20241030224944088521
```

```bash
./docker-compose.sh exec salt_master salt '*' test.ping
[DEBUG   ] Configuration file path: /etc/salt/master
[DEBUG   ] Reading configuration from /etc/salt/master
[DEBUG   ] Missing configuration file: /root/.saltrc
[DEBUG   ] MasterEvent PUB socket URI: /var/run/salt/master/master_event_pub.ipc
[DEBUG   ] MasterEvent PULL socket URI: /var/run/salt/master/master_event_pull.ipc
[DEBUG   ] Closing AsyncReqChannel instance
[DEBUG   ] The functions from module 'local_cache' are being loaded by dir() on the loaded module
[DEBUG   ] LazyLoaded local_cache.get_load
[DEBUG   ] Reading minion list from /var/cache/salt/master/jobs/d8/6934beb808abfce2ff50953a98b7a58414743eda040d8003a4b0fbe5e7ce35/.minions.p
[DEBUG   ] get_iter_returns for jid 20241030225034111003 sent to set() will timeout at 22:50:39.139553
[DEBUG   ] Checking whether jid 20241030225034111003 is still running
[DEBUG   ] Closing AsyncReqChannel instance
[DEBUG   ] retcode missing from client return
[DEBUG   ] Closing IPCMessageSubscriber instance
```

```bash
./docker-compose.sh exec salt_syndic1 salt salt_master test.ping
No minions matched the target. No command was sent, no jid was assigned.
ERROR: No return received
```

Ajout de `order_masters: True` aussi dans les fichiers /etc/salt/master des noeuds syndic
```bash
./docker-compose.sh exec salt_syndic1 tail -f /var/log/salt/syndic
    [ERROR   ][10] Unable to call _fire_master on salt_master, that syndic is not connected
    [CRITICAL][10] Unable to call _fire_master on any masters!
```