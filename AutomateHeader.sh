#!/bin/bash

# This script uses the shcheck project on GitHub : https://github.com/santoru/shcheck

usage() {
    echo "Usage: $0 [-f <input_file>] [-o <output_file>] [-D]"
    echo "Options:"
    echo "  -f, --file <file>       Specifies the file containing the list of applications to check"
    echo "  -o, --output <file>     Specifies the output file for the result in Markdown format (optional)"
    echo "  -D, --Download          Downloads the shcheck project from GitHub"
    echo "  -h, --help              Displays this help message"
    exit 1
}

inputfile=""
outputfile=""
download_project=false

download_shcheck() {
    echo "Downloading shcheck projet."
    if ! command -v git &> /dev/null; then
        echo "Error: git is not installed. Please install it to download the project."
        exit 1
    fi
    git clone https://github.com/santoru/shcheck.git
    if [ $? -eq 0 ]; then
        echo "The shcheck project has been successfully downloaded."
    else
        echo "Error downloading shcheck project."
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            inputfile="$2"
            shift 2
            ;;
        -o|--output)
            outputfile="$2"
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
            echo "Unrecognized option: $1"
            usage
            ;;
    esac
done

if $download_project; then
    download_shcheck
    exit 0
fi

if [ -z "$inputfile" ]; then
    echo "Error: You must specify an input file with the -f or --file option"
    usage
fi

if [ ! -f "$inputfile" ]; then
    echo "The $inputfile file does not exist."
    exit 1
fi

output() {
    if [ -n "$outputfile" ]; then
        echo "$1" >> "$outputfile"
    else
        echo "$1"
    fi
}

if [ -n "$outputfile" ]; then
    sortie_dir=$(dirname "$outputfile")
    if [ ! -d "$sortie_dir" ]; then
        mkdir -p "$sortie_dir"
        if [ $? -ne 0 ]; then
            echo "Error: Unable to create directory $sortie_dir"
            exit 1
        fi
    fi
    > "$outputfile"
fi


if [ ! -f "shcheck/shcheck.py" ]; then
    echo "Error: shcheck.py not found. Use the -D or --Download option to download the project."
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
done < "$inputfile"

if [ -n "$outputfile" ]; then
    echo "The result was written in $outputfile"
fi
