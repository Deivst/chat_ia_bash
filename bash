#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Author: Northem Group LLC
# GitHub Repository: https://github.com/your-username/vim-ai-helper
# License: MIT License
# ------------------------
# Este script:
# 1. Se asegura de tener permisos de ejecución. La primera vez ejecútalo con:
#    bash chat_hf.sh
#    y luego con ./chat_hf.sh
#
# 2. Si la variable HF_TOKEN no está establecida, pide al usuario que la ingrese.
# 3. Utiliza el token y el modelo especificado para chatear con la IA de HuggingFace.
#
# Requisitos previos:
# - Tener instalados 'curl' y 'jq'.
# - Obtener un Hugging Face API Token desde https://huggingface.co/

# Comprobamos si el script tiene permisos de ejecución
if [ ! -x "$0" ]; then
    echo "Otorgando permisos de ejecución al script..."
    chmod +x "$0"
    echo "Permisos otorgados. Ahora puedes ejecutar el script con ./chat_hf.sh"
    echo "Saliendo para que puedas re-ejecutar el script."
    exit 0
fi

# Si no está establecido HF_TOKEN, lo pedimos al usuario
if [ -z "$HF_TOKEN" ]; then
    read -p "Por favor, introduce tu Hugging Face API Token: " USER_TOKEN
    export HF_TOKEN="$USER_TOKEN"
fi

# Verificamos nuevamente que HF_TOKEN esté listo
if [ -z "$HF_TOKEN" ]; then
    echo "Error: No se proporcionó un token. Saliendo..."
    exit 1
fi

# Modelo a utilizar (ejemplo: bigscience/bloom-560m)
MODEL="mistralai/Mistral-Nemo-Instruct-2407"
API_URL="https://api-inference.huggingface.co/models/${MODEL}"

echo
echo "Chat con el modelo: $MODEL"
echo "Escribe 'salir' para terminar la conversación."
echo

while true; do
    # Lee entrada del usuario
    read -p "Tú: " USER_PROMPT

    # Si el usuario escribe "salir", terminamos
    if [ "$USER_PROMPT" = "salir" ]; then
        echo "Terminando la conversación..."
        break
    fi

    # Construcción del payload JSON sin usar jq
    JSON_PAYLOAD=$(cat <<EOF
{
    "inputs": "$USER_PROMPT",
    "parameters": {
        "max_new_tokens": 500
    }
}
EOF
)

    # Imprimimos el payload JSON para depuración
    #echo "Payload JSON enviado:"
    #echo "$JSON_PAYLOAD"

    # Realizamos la petición a la API
    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json" \
        --data "$JSON_PAYLOAD")

    # Imprimimos la respuesta completa para depuración


    # Extraemos el texto generado con jq
    RESPONSE_TEXT=$(echo "$RESPONSE" | jq -r '.[0].generated_text')

    if [ -z "$RESPONSE_TEXT" ] || [ "$RESPONSE_TEXT" = "null" ]; then
        echo "IA: [No se obtuvo respuesta válida. Intenta de nuevo.]"
    else
        echo "IA: $RESPONSE_TEXT"
    fi
done
