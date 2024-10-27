#!/bin/bash

export_path=_exports

# Création du nom du fichier de log
SCRIPT_NAME=$(basename "$0")
LOG_FILE="_logs/${SCRIPT_NAME%.sh}.log"

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

# Fonction d'export de fichier de configuration Salt
export() {
    local node=$1
    local node_type=$2
    log "INFO" "[$node] export de la configuration ${node_type}..."
    docker cp ${node}:/etc/salt/${node_type} ${export_path}/${node}_${node_type}
}

export salt_master master
export salt_syndic1 master
export salt_syndic1 minion
export salt_syndic2 master
export salt_syndic2 minion

for i in $(seq 1 $NUM_MINIONS); do
    export "${MINION_PREFIX}_salt_minion_$i" minion
done
