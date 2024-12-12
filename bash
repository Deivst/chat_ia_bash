#!/bin/bash
# -----------------------------------------------------------------------------
# Author: Northem Group LLC
# GitHub Repository: https://github.com/your-username/vim-ai-helper
# Description: This script sets up the Vim AI Helper plugin using CodeT5 model.
# License: MIT License
# -----------------------------------------------------------------------------

install_messages_en=(
    "The assistance IA Vim plugin was successfully installed."
    "Open Vim, select a block of code, and use the :AIFix command to debug it and :AIH for help."
    "Error installing the plugin. Check permissions or review the script."
    "Permissions granted to the path"
    "The file or directory does not exist"
    "Skipping"
    "Enter huggingface's token: "
    " Instructions:\nYou are an expert assistant at debugging Bash code. You will be given a snippet of code with potential errors or areas for improvement. Your task is:\n1. Analyze the code.\n2. Fix errors or bad practices.\n3. Provide an improved version of the code.\n\nPlease respond with only the improved code, without any additional explanation.\n\n### Original Code:\n"
)

install_messages_es=(
    "El plugin de asistencia IA para Vim se instaló correctamente."
    "Abre Vim, selecciona un bloque de código y usa el comando :AIFix para depurarlo o :AIH para pedir ayuda."
    "Error al instalar el plugin. Verifica los permisos o revisa el script."
    "Otorgaste los permisos al path"
    "El archivo o directorio no existe"
    "Saltando"
    "Ingresa tu token de huggingface: "
    " Instrucciones:\nEres un asistente experto en depuración de código Bash. Se te proporcionará un fragmento de código con posibles errores o puntos a mejorar. Tu tarea es:\n1. Analizar el código.\n2. Corregir errores o malas prácticas.\n3. Ofrecer una versión mejorada del código.\n\nPor favor, responde con el código corregido sin explicaciones adicionales, únicamente el código final mejorado.\n\n### Código original:\n"
)

install_messages_pt=(
    "O plugin de assistência IA para Vim foi instalado com sucesso."
    "Abra o Vim, selecione um bloco de código e use o comando :AIFix para depurá-lo ou :AIH para pedir ajuda."
    "Erro ao instalar o plugin. Verifique as permissões ou revise o script."
    "Você concedeu permissões para o caminho"
    "O arquivo ou diretório não existe"
    "Pulando"
    "Insira o token huggingface: "
    " Instruções:\nVocê é um assistente especialista em depuração de código Bash. Você receberá um trecho de código que pode conter erros ou pontos a melhorar. Sua tarefa é:\n1. Analisar o código.\n2. Corrigir erros ou más práticas.\n3. Fornecer uma versão aprimorada do código.\n\nPor favor, responda apenas com o código melhorado, sem explicações adicionais.\n\n### Código Original:\n"
)

select_language() {
    echo "Select installation language / Selecciona el idioma de instalación / Selecione o idioma de instalação:"
    echo "1. English"
    echo "2. Español"
    echo "3. Português"
    read -p "Enter your choice [1-3]: " lang_choice

    case $lang_choice in
        1) install_messages=("${install_messages_en[@]}") ;;
        2) install_messages=("${install_messages_es[@]}") ;;
        3) install_messages=("${install_messages_pt[@]}") ;;
        *) echo "Invalid choice. Defaulting to English."; install_messages=("${install_messages_en[@]}") ;;
    esac
}

get_permissions() {
    local path=$1
    if [[ -e $path ]]; then
        echo "${install_messages[3]} $path"
        chmod -R u+rwx "$path"
    else
        echo "${install_messages[4]} $path. ${install_messages[5]}"
    fi
}

# Seleccionar idioma
select_language

# Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$HOME/.vim/pack/plugins/start/ia_assistance"
SCRIPTS_DIR="$PLUGIN_DIR/scripts"

echo "Creating plugin structure at $PLUGIN_DIR..."
mkdir -p "$PLUGIN_DIR/plugin"
mkdir -p "$SCRIPTS_DIR"
get_permissions "$PLUGIN_DIR"

read -p "${install_messages[6]}" TOKENHF
HF_API_TOKEN="$TOKENHF"
MODEL="mistralai/Mistral-Nemo-Instruct-2407/v1/chat/completions"
API_URL="https://api-inference.huggingface.co/models/$MODEL"

# Guardar token y URL en archivo de configuración
CONFIG_FILE="$SCRIPTS_DIR/config.env"
echo "HF_API_TOKEN=$HF_API_TOKEN" > "$CONFIG_FILE"
echo "API_URL=$API_URL" >> "$CONFIG_FILE"

# Asegurarse de que instructions no esté vacía
if [[ -z "${install_messages[7]}" ]]; then
    echo "Error: The instructions message is empty. Check your install_messages arrays."
    exit 1
fi
instructions="${install_messages[7]}"

# Crear el script fix_code.sh con expansiones habilitadas
FIX_SCRIPT="$SCRIPTS_DIR/fix_code.sh"
cat > "$FIX_SCRIPT" <<EOF
#!/usr/bin/env bash

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
source "\$SCRIPT_DIR/config.env"

input_code=\$(cat)

# Si input_code está vacío, mostrar advertencia (puede indicar que no se seleccionó texto en Vim)
if [ -z "\$input_code" ]; then
  >&2 echo "Warning: No code was provided as input. Make sure you selected text before running :AIFix."
fi

escaped_code=\$(echo "\$input_code" | sed 's/"/\\\\"/g')

input_text="\${instructions}\${escaped_code}"
json_data="{\"inputs\": \"$input_text\"}"

# Mostrar json_data para depuración
>&2 echo "DEBUG: json_data: \$json_data"

response=\$(curl -s \
  -X POST \
  -H "Authorization: Bearer \$HF_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "\$json_data" \
  "\$API_URL")

# Mostrar la respuesta de la API para depuración
>&2 echo "DEBUG: API response: \$response"

echo "\$response"
EOF

chmod +x "$FIX_SCRIPT"

# Crear el archivo Vimscript del plugin
VIM_PLUGIN_FILE="$PLUGIN_DIR/plugin/ia_fixer.vim"
cat > "$VIM_PLUGIN_FILE" <<EOF
" Plugin: IA Assistance for Vim

function! AIFixFunction() range
  let l:start_line = a:firstline
  let l:end_line = a:lastline
  let l:lines = getline(l:start_line, l:end_line)
  let l:code = join(l:lines, "\n")

  let l:plugin_dir = expand("~/.vim/pack/plugins/start/ia_assistance")
  let l:fix_script = l:plugin_dir . "/scripts/fix_code.sh"
  if filereadable(l:fix_script)
    let l:response = system(l:fix_script, l:code)
    new
    call setline(1, split(l:response, "\n"))
  else
    echoerr "fix_code.sh script not found."
  endif
endfunction

command! -range AIFix call AIFixFunction()

function! AIFixHelp()
  echo "AI Assistance Plugin:"
  echo ":AIFix  - Selecciona líneas visualmente y luego ejecuta :AIFix para enviar el código a la IA"
  echo ":AIH    - Muestra este mensaje de ayuda."
endfunction

command! AIH call AIFixHelp()
EOF

echo "${install_messages[0]}"
echo "${install_messages[1]}"

