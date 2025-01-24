#!/bin/bash

# Ce script utilise le projet shcheck sur GitHub : https://github.com/santoru/shcheck

usage() {
    echo "Usage: $0 [-f <fichier_entree>] [-o <fichier_sortie>] [-D]"
    echo "Options:"
    echo "  -f, --file <fichier>    Spécifie le fichier contenant la liste des applications à vérifier"
    echo "  -o, --output <fichier>  Spécifie le fichier de sortie pour le résultat en Markdown (optionnel)"
    echo "  -D, --Download          Télécharge le projet shcheck depuis GitHub"
    echo "  -h, --help              Affiche ce message d'aide"
    exit 1
}

fichier_entree=""
fichier_sortie=""
download_project=false

download_shcheck() {
    echo "Téléchargement du projet shcheck..."
    if ! command -v git &> /dev/null; then
        echo "Erreur : git n'est pas installé. Veuillez l'installer pour télécharger le projet."
        exit 1
    fi
    git clone https://github.com/santoru/shcheck.git
    if [ $? -eq 0 ]; then
        echo "Le projet shcheck a été téléchargé avec succès."
    else
        echo "Erreur lors du téléchargement du projet shcheck."
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            fichier_entree="$2"
            shift 2
            ;;
        -o|--output)
            fichier_sortie="$2"
            shift 2
            ;;
        -D|--Download)
            download_project=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Option non reconnue: $1"
            usage
            ;;
    esac
done

if $download_project; then
    download_shcheck
    exit 0
fi

if [ -z "$fichier_entree" ]; then
    echo "Erreur : Vous devez spécifier un fichier d'entrée avec l'option -f ou --file"
    usage
fi

if [ ! -f "$fichier_entree" ]; then
    echo "Le fichier $fichier_entree n'existe pas."
    exit 1
fi

output() {
    if [ -n "$fichier_sortie" ]; then
        echo "$1" >> "$fichier_sortie"
    else
        echo "$1"
    fi
}

if [ -n "$fichier_sortie" ]; then
    sortie_dir=$(dirname "$fichier_sortie")
    if [ ! -d "$sortie_dir" ]; then
        mkdir -p "$sortie_dir"
        if [ $? -ne 0 ]; then
            echo "Erreur : Impossible de créer le répertoire $sortie_dir"
            exit 1
        fi
    fi
    > "$fichier_sortie"
fi


if [ ! -f "shcheck/shcheck.py" ]; then
    echo "Erreur : shcheck.py n'a pas été trouvé. Utilisez l'option -D ou --Download pour télécharger le projet."
    exit 1
fi

output "| Application | Strict-Transport-Security | Content-Security-Policy | X-Frame-Options | X-Content-Type-Options | X-XSS-Protection |"
output "| ------- | ------- | ------- | ------- | ------- | ------- |"

while IFS= read -r ligne
do
    resultat=$(./shcheck/./shcheck.py "$ligne" --colours=none -d 2>&1)
    
    strict_transport='[component="icon" type="close"]'
    content_security='[component="icon" type="close"]'
    x_frame='[component="icon" type="close"]'
    x_content_type='[component="icon" type="close"]'
    x_xss='[component="icon" type="close"]'

    if echo "$resultat" | grep -q "Header Strict-Transport-Security is present!"; then
        strict_transport='[component="icon" type="check"]'
    fi
    if echo "$resultat" | grep -q "Header Content-Security-Policy is present!"; then
        content_security='[component="icon" type="check"]'
    fi
    if echo "$resultat" | grep -q "Header X-Frame-Options is present!"; then
        x_frame='[component="icon" type="check"]'
    fi
    if echo "$resultat" | grep -q "Header X-Content-Type-Options is present!"; then
        x_content_type='[component="icon" type="check"]'
    fi
    if echo "$resultat" | grep -q "Header X-XSS-Protection is present!"; then
        x_xss='[component="icon" type="check"]'
    fi

    output "| $ligne | $strict_transport | $content_security | $x_frame | $x_content_type | $x_xss |"
done < "$fichier_entree"

if [ -n "$fichier_sortie" ]; then
    echo "Le résultat a été écrit dans $fichier_sortie"
fi
