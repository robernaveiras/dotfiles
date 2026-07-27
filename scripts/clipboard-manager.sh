#!/bin/bash

# Configuración
TERMINAL="ghostty"
WINDOW_TITLE="ClipManager"

# --- MODO SELECCIÓN ---
# Mostramos el historial, pero añadimos una opción especial al principio para "Limpiar Todo"
# Usamos un carácter especial (separator) para que cliphist no se confunda
OPCION_LIMPIAR="  BORRAR TODO EL HISTORIAL"

# Obtenemos la lista
LISTA=$(cliphist list)

# Mostramos menú en Walker
SELECCION=$(echo -e "$OPCION_LIMPIAR\n$LISTA" | walker --dmenu --placeholder "Gestor de Portapapeles (Modo Borrado)")

[ -z "$SELECCION" ] && exit 0

# --- LÓGICA ---

# Caso 1: El usuario quiere borrar todo
if [ "$SELECCION" = "$OPCION_LIMPIAR" ]; then
  SCRIPT_CMD="
    gum style --foreground 196 --border double --align center '¡PELIGRO!'
    if gum confirm '¿Estás seguro de vaciar todo el historial?'; then
        cliphist wipe
        gum style --foreground 46 'Historial vaciado.'
        sleep 1
    fi
    "
# Caso 2: El usuario seleccionó un ítem específico
else
  # Cliphist necesita la línea original completa para borrarla
  SCRIPT_CMD="
    gum style --foreground 212 --border double --align center 'GESTIONAR ENTRADA'
    echo 'Selección: $SELECCION'
    echo ''
    
    # Menú de acciones
    ACCION=\$(gum choose 'Copiar al Portapapeles' 'Borrar esta entrada' 'Cancelar')
    
    case \"\$ACCION\" in
        'Copiar'*)
            echo '$SELECCION' | cliphist decode | wl-copy
            ;;
        'Borrar'*)
            echo '$SELECCION' | cliphist delete
            gum style --foreground 196 'Entrada eliminada.'
            sleep 1
            ;;
    esac
    "
fi

# --- EJECUTAR EN GHOSTTY ---
# Usamos un script temporal como aprendimos antes para evitar problemas de comillas
TMP_SCRIPT=$(mktemp)
echo "#!/bin/bash" >"$TMP_SCRIPT"
echo "$SCRIPT_CMD" >>"$TMP_SCRIPT"
echo "rm -- \"\$0\"" >>"$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

$TERMINAL --title="$WINDOW_TITLE" -e "$TMP_SCRIPT"
