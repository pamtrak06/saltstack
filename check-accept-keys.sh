#!/bin/bash

# Récupère le nom court du script (sans le chemin)
SCRIPT_NAME=$(basename "$0")
LOG_FILE="${SCRIPT_NAME%.*}.log"

# Fonction pour logger les messages
log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Redirige stderr vers stdout
exec 2>&1

# Fonction pour exécuter les commandes sur un syndic et enregistrer les résultats
run_on_syndic() {
    local syndic=$1
    local command=$2
    log "Exécution sur $syndic : $command"
    docker exec $syndic $command 2>&1 | tee -a "$LOG_FILE"
    log ""
}

# Début du script
log "Opérations sur les clés des syndics - $(date)"

for syndic in salt_syndic1 salt_syndic2
do
    log "=== Opérations sur $syndic ==="
    
    # Liste initiale des clés
    run_on_syndic $syndic "salt-key -L"
    
    # Acceptation de toutes les clés
    log "Acceptation de toutes les clés sur $syndic"
    run_on_syndic $syndic "salt-key -A -y"
    
    # Nouvelle liste des clés après acceptation
    log "Nouvelle liste des clés sur $syndic après acceptation :"
    run_on_syndic $syndic "salt-key -L"
    
    log ""
done

log "Opérations terminées. Consultez $LOG_FILE pour les détails."