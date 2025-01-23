#!/bin/bash

echo "Enter file name or path to target file (.lst or .txt): "
read fichier

if [ ! -f "$fichier" ]; then
    echo "Le fichier $fichier n'existe pas."
    exit 1
fi

echo "| Application | Strict-Transport-Security | Content-Security-Policy | X-Frame-Options | X-Content-Type-Options | X-XSS-Protection |"
echo "| ------- | ------- | ------- | ------- | ------- | ------- |"

while IFS= read -r ligne
do
    resultat=$(./shcheck.py "$ligne" --colours=none -d 2>&1)
    
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

    echo "| $ligne | $strict_transport | $content_security | $x_frame | $x_content_type | $x_xss |"
done < "$fichier"
