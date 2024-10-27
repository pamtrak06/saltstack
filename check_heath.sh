#!/bin/bash

# Définition des codes de couleur
RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
BLUE="\033[34m"

# Vérification des paramètres
if [ $# -ne 2 ]; then
    echo "Usage: $0 <préfixe_minion> <nombre_de_minions>"
    exit 1
fi

# Définition du préfixe pour les minions et du nombre de minions
MINION_PREFIX=$1
NUM_MINIONS=$2

# Définition des composants Salt
MASTER="salt_master"
SYNDICS=("salt_syndic1" "salt_syndic2")

# Génération dynamique des noms de minions avec la nouvelle syntaxe
MINIONS=()
for i in $(seq 1 $NUM_MINIONS); do
    MINIONS+=("${MINION_PREFIX}_salt_minion_$i")
done

# Création du nom du fichier de log
SCRIPT_NAME=$(basename "$0")
LOG_FILE="${SCRIPT_NAME%.sh}.log"

# Fonction pour afficher des logs colorés et les écrire dans le fichier
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

    echo -e "$log_message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $message" >> "$LOG_FILE"
}

# Fonction pour vérifier l'état d'un conteneur
check_container() {
    local container=$1
    if docker inspect -f '{{.State.Running}}' $container 2>/dev/null | grep -q "true"; then
        log "INFO" "[$container] Conteneur en cours d'exécution"
    else
        log "ERROR" "[$container] Conteneur arrêté ou inexistant"
        log "DEBUG" "Tentative de démarrage du conteneur $container..."
        docker start $container
        sleep 5  # Attendre que le conteneur démarre
        if docker inspect -f '{{.State.Running}}' $container 2>/dev/null | grep -q "true"; then
            log "INFO" "[$container] Conteneur démarré avec succès"
        else
            log "ERROR" "[$container] Échec du démarrage du conteneur"
        fi
    fi
}

# Fonction pour vérifier la connectivité des syndics/minions
check_connectivity() {
    local node=$1
    local node_type=$2
    if docker exec $MASTER salt "$node" test.ping --out=txt 2>/dev/null | grep -q "True"; then
        log "INFO" "[$node] Connecté"
    else
        log "WARNING" "[$node] Non connecté"
        log "DEBUG" "Vérification des clés pour $node..."
        docker exec $MASTER salt-key -L | grep "$node"
        
        log "DEBUG" "Vérification de la configuration de $node..."
        docker exec $node cat /etc/salt/minion | grep "^master:"
        
        log "DEBUG" "Vérification des logs de $node..."
        docker exec $node tail -n 20 /var/log/salt/$node_type
        
        log "DEBUG" "Tentative de redémarrage des services Salt sur $node..."
        docker exec $node salt-call service.restart salt-$node_type
        docker exec $node salt-call service.restart salt-minion
        
        sleep 10  # Attendre que les services redémarrent
        
        log "DEBUG" "Nouvelle tentative de connexion pour $node..."
        if docker exec $MASTER salt "$node" test.ping --out=txt 2>/dev/null | grep -q "True"; then
            log "INFO" "[$node] Connecté après redémarrage des services"
        else
            log "ERROR" "[$node] Toujours non connecté après redémarrage des services"
            log "DEBUG" "Vérification des versions de Salt..."
            docker exec $MASTER salt --versions-report
            docker exec $node salt --versions-report
        fi
    fi
}

log "INFO" "=== Début du test de santé ==="

# Vérification du master
log "DEBUG" "=== Vérification du Master ==="
check_container $MASTER

# Vérification des syndics
log "DEBUG" "=== Vérification des Syndics ==="
for syndic in "${SYNDICS[@]}"; do
    check_container $syndic
    check_connectivity "$syndic" "syndic"
done

# Vérification des minions
log "DEBUG" "=== Vérification des Minions ==="
for minion in "${MINIONS[@]}"; do
    check_container $minion
    check_connectivity "$minion" "minion"
done

# Vérification des versions
log "DEBUG" "=== Versions de Salt ==="
docker exec $MASTER salt '*' test.version --out=txt 2>/dev/null || {
    log "ERROR" "Impossible d'obtenir les versions de Salt"
    log "DEBUG" "Vérification des versions sur le master..."
    docker exec $MASTER salt --versions-report
}

# Vérification de l'utilisation des ressources sur le master
log "DEBUG" "=== Utilisation des ressources sur le Master ==="
docker stats $MASTER --no-stream --format "CPU: {{.CPUPerc}}\nMémoire: {{.MemPerc}}\nDisque: {{.BlockIO}}" 2>/dev/null || {
    log "ERROR" "Impossible d'obtenir les statistiques du conteneur master"
}

# Vérification des clés
log "DEBUG" "=== État des clés Salt ==="
docker exec $MASTER salt-key -L 2>/dev/null || {
    log "ERROR" "Impossible d'obtenir l'état des clés Salt"
    log "DEBUG" "Vérification des permissions du répertoire des clés..."
    docker exec $MASTER ls -l /etc/salt/pki/master/
}

log "INFO" "=== Test de santé terminé ==="
log "INFO" "Les logs ont été enregistrés dans $LOG_FILE"