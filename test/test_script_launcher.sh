#!/bin/bash

# Nom de l'environnement virtuel
VENV_DIR="venv"
REQUIREMENTS_FILE="requirements.txt"

# Détecter l'interpréteur Python
if command -v python3 &>/dev/null; then
    PYTHON_EXEC=python3
elif command -v python &>/dev/null; then
    PYTHON_EXEC=python
else
    echo "Aucun interpréteur Python trouvé. Veuillez installer Python."
    exit 1
fi

# Vérifier si l'environnement virtuel existe, sinon le créer
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Création de l'environnement virtuel..."
    $PYTHON_EXEC -m venv "$VENV_DIR"
fi

# Activer l'environnement virtuel
source "$VENV_DIR/bin/activate"

# Mettre à jour pip si nécessaire
echo "Mise à jour de pip..."
pip install --upgrade pip

# Vérifier si les dépendances sont installées, sinon les installer
if [[ -f "$REQUIREMENTS_FILE" ]]; then
    echo "Vérification des dépendances..."
    if ! pip show $(awk '{print $1}' "$REQUIREMENTS_FILE") &>/dev/null; then
        echo "Installation des dépendances manquantes..."
        pip install -r "$REQUIREMENTS_FILE"
    else
        echo "Toutes les dépendances sont déjà installées."
    fi
else
    echo "Le fichier $REQUIREMENTS_FILE n'existe pas."
fi

# Obtenir le nom du script sans extension
SCRIPT_NAME=$(basename "$0" .sh)

# Vérifier si le script Python existe dans le même répertoire
if [[ ! -f "${SCRIPT_NAME}.py" ]]; then
    echo "Le script Python ${SCRIPT_NAME}.py n'existe pas dans le répertoire actuel."
    exit 1
fi

# Exécuter le script Python avec tous les arguments passés au wrapper
exec "$PYTHON_EXEC" "${SCRIPT_NAME}.py" "$@"