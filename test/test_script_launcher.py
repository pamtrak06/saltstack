import os
import json
import re
import logging
import argparse
import subprocess
import pandas as pd
from datetime import datetime

# Configuration du logging
def setup_logging(log_path, log_level, log_output):
    log_filename = os.path.join(log_path, f"{os.path.basename(__file__).split('.')[0]}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
    
    # Configuration de base du logging
    if not logging.getLogger().hasHandlers():  # Vérifier si des gestionnaires existent déjà
        logging.basicConfig(level=log_level, format='%(asctime)s - %(levelname)s - %(message)s')
    
    # Gestion de la sortie des logs selon la configuration
    outputs = [output.strip() for output in log_output.split(',')]
    
    if 'file' in outputs:
        file_handler = logging.FileHandler(log_filename)
        file_handler.setLevel(log_level)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        logging.getLogger().addHandler(file_handler)

    if 'console' in outputs:
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        console_handler.setFormatter(formatter)
        if not any(isinstance(h, logging.StreamHandler) for h in logging.getLogger().handlers):
            logging.getLogger().addHandler(console_handler)

# Chargement de la configuration
def load_config(config_path):
    with open(config_path, 'r') as config_file:
        return json.load(config_file)

# Exécution d'une commande avec gestion des erreurs
def execute_command(command, run_path, timeout):
    try:
        result = subprocess.run(command, cwd=run_path, shell=True, capture_output=True, text=True, timeout=timeout / 1000)
        return result.returncode, result.stdout.strip(), result.stderr.strip()
    except subprocess.TimeoutExpired:
        logging.error(f"Timeout expired for command: {command}")
        return None, "", "Timeout expired"
    except Exception as e:
        logging.error(f"Error executing command '{command}': {e}")
        return None, "", str(e)

# Filtrage des fichiers JSON selon le filtre regex
def filter_json_files(json_files, filter_regex):
    return [f for f in json_files if re.search(filter_regex, f)]

# Création des répertoires si nécessaire
def create_directories(paths):
    for path in paths:
        if not os.path.exists(path):
            os.makedirs(path)

# Échappement du caractère '|' pour le format Markdown
def escape_markdown(value):
    """Remplace le caractère '|' par '[PIPE]' pour le format Markdown."""
    return str(value).replace('|', '[PIPE]')

# Nettoyage et contraction de l'output
def clean_output(output):
    """Nettoie l'output en supprimant les caractères spéciaux et en limitant à 40 caractères."""
    cleaned_output = re.sub(r'\s+', ' ', output)  # Remplace les espaces multiples par un seul espace
    cleaned_output = re.sub(r'[^\w\s,.!]', '', cleaned_output)  # Supprime les caractères spéciaux sauf ceux spécifiés
    return cleaned_output[:40]  # Limiter à 40 caractères

# Vérification de l'output message contre une expression régulière sur plusieurs lignes
def check_output_against_regex(output_message, expected_value):
    # Vérifie si l'expression régulière correspond à l'ensemble de la sortie multi-lignes.
    return re.search(expected_value, output_message) is not None

# Extraction du message après "ERROR" ou "CRITICAL"
def extract_error_message(output):
    match = re.search(r'(ERROR|CRITICAL):?\s*(.*)', output)
    return match.group(2).strip() if match else output

# Enregistrement des résultats dans un fichier CSV et Markdown avec pandas
def save_results(results, results_path):
    df = pd.DataFrame(results, columns=["Timestamp", "Description", "Command", "Expected Return", "Timeout", "Rule", "Output", "Status"])
    
    # Sauvegarde en CSV
    csv_file = os.path.join(results_path, 'results.csv')
    df.to_csv(csv_file, index=False)

    # Sauvegarde en Markdown
    md_file = os.path.join(results_path, 'results.md')
    with open(md_file, 'w') as file:
        file.write("# Résultats des Tests\n\n")
        file.write("| Timestamp | Description | Command | Expected Return | Timeout | Rule | Output | Status |\n")
        file.write("|-----------|-------------|---------|------------------|---------|------|--------|--------|\n")
        
        for result in results:
            escaped_result = [escape_markdown(item) for item in result]  # Échapper chaque élément
            file.write(f"| {' | '.join(escaped_result)} |\n")

# Fonction principale pour exécuter les tests
def main():
    parser = argparse.ArgumentParser(description='Exécute des tests définis dans des fichiers JSON.')
    parser.add_argument('--filter-tests', type=str, help='Filtre pour sélectionner les tests à exécuter.')
    parser.add_argument('--run-path', type=str, help='Chemin de travail pour l\'exécution des commandes.')

    args = parser.parse_args()

    # Chargement de la configuration
    config = load_config('config.json')
    
    TEST_SCRIPTS_PATH = config['TEST_SCRIPTS_PATH']
    LOG_PATH = config['LOG_PATH']
    RESULTS_PATH = config['RESULTS_PATH']
    FILTER_TESTS = args.filter_tests if args.filter_tests else config['FILTER_TESTS']
    RUN_PATH = args.run_path if args.run_path else config['RUN_WORKDIR']
    
    # Configuration du niveau de log et sortie des logs
    log_level = getattr(logging, config.get('LOG_LEVEL', 'INFO').upper(), logging.INFO)
    log_output = config.get('LOG_OUTPUT', 'file,console')  # Valeurs par défaut

    # Création des répertoires pour logs et résultats
    create_directories([LOG_PATH, RESULTS_PATH])
    
    # Configuration du logging avec sortie personnalisée
    setup_logging(LOG_PATH, log_level, log_output)
    
    # Vérification de l'existence des chemins nécessaires
    if not os.path.exists(TEST_SCRIPTS_PATH):
        logging.error(f"Le chemin TEST_SCRIPTS_PATH n'existe pas: {TEST_SCRIPTS_PATH}")
        return

    if not os.path.exists(RUN_PATH) and RUN_PATH != "":
        logging.error(f"Le chemin RUN_PATH n'existe pas: {RUN_PATH}")
        return

    json_files = [f for f in os.listdir(TEST_SCRIPTS_PATH) if f.endswith('.json')]
    filtered_files = filter_json_files(json_files, FILTER_TESTS)

    results = []
    
    for json_file in filtered_files:
        with open(os.path.join(TEST_SCRIPTS_PATH, json_file), 'r') as file:
            test_definition = json.load(file)
        
        command = test_definition['command']
        
        run_path = test_definition.get('run_path', RUN_PATH)
        
        if run_path == "{RUN_PATH}":
            run_path = RUN_PATH or ""
        
        if run_path in ["", "NA", "N/A"]:
            run_path = ""
        
        expected_return_type = test_definition['expected_return_type']
        expected_value = test_definition['expected_value']
        timeout = test_definition.get('timeout', 1000)  # Timeout par défaut en millisecondes
        
        # Exécution de la commande avec gestion des erreurs
        return_code, output_message, error_message = execute_command(command, run_path or ".", timeout)
        
        status = "UNKNOWN"
        
        if expected_return_type == 'return_code':
            if return_code == expected_value:
                status = "SUCCESS"
            else:
                status = "FAILED"
        
        elif expected_return_type == 'output_message':
            if check_output_against_regex(output_message, expected_value):  # Vérifier toute la sortie contre l'expression régulière.
                status = "SUCCESS"
            else:
                status = "FAILED"

        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        # Nettoyage et contraction de l'output avant l'enregistrement
        output_contracted = clean_output(extract_error_message(output_message or error_message or ""))

        # Récupération du nom court pour Rule avec un hyperlien vers le fichier JSON dans ../${TEST_SCRIPTS_PATH}
        rule_name_shortened = f"[{json_file}]({os.path.join('..', TEST_SCRIPTS_PATH,json_file)})"
        
        results.append([timestamp,
                        test_definition['description'],
                        command,
                        expected_value,
                        timeout,
                        rule_name_shortened,
                        output_contracted,
                        status])
        
        logging.info(f"Test exécuté: {test_definition['description']} - Statut: {status}")

        # Écriture d'un fichier de log spécifique pour chaque test exécuté
        test_log_filename = os.path.join(LOG_PATH, f"{os.path.splitext(json_file)[0]}_log.txt")
        
        with open(test_log_filename, 'w') as test_log_file:
            test_log_file.write(f"Commande exécutée: {command}\n")
            test_log_file.write(f"Sortie standard:\n{output_message}\n")
            test_log_file.write(f"Erreur standard:\n{error_message}\n")
            test_log_file.write(f"\nStatut final: {status}\n")

            # Ajouter un hyperlien vers ce fichier dans le statut du markdown.
            results[-1][-1] += f" [Log]({os.path.relpath(test_log_filename, RESULTS_PATH)})"

    # Écriture des résultats dans CSV et Markdown avec pandas
    save_results(results, RESULTS_PATH)

if __name__ == "__main__":
    main()