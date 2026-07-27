#!/bin/bash

# --- CONFIGURACIÓN ---
CONF_DIR="$HOME/.config/hypr"
TERMINAL="ghostty"
WINDOW_TITLE="HyprManager"
# Definimos el icono (asegúrate de tener una Nerd Font instalada)
ICONO=""

# --- PASO 1: SELECCIÓN CON WALKER (ORDENADO + ICONOS) ---
# 1. find: busca archivos
# 2. sort: ordena alfabéticamente
# 3. sed: añade el icono al principio de cada línea
# 4. walker: muestra el menú
SELECCION=$(find "$CONF_DIR" -maxdepth 1 -type f -printf "%f\n" | sort | sed "s/^/$ICONO /" | walker --dmenu --placeholder "Configuración de Hyprland")

# Si se cancela, salir
[ -z "$SELECCION" ] && exit 0

# --- LIMPIEZA DEL NOMBRE ---
# Como añadimos "  " (icono + espacio) al principio, el nombre del archivo ya no es válido.
# Usamos 'cut' para quedarnos con todo lo que hay después del primer espacio.
# (El campo 1 es el icono, el campo 2 en adelante es el nombre del archivo)
ARCHIVO=$(echo "$SELECCION" | cut -d ' ' -f2-)

FULL_PATH="$CONF_DIR/$ARCHIVO"

# --- PASO 2: SCRIPT TEMPORAL ---
TMP_SCRIPT=$(mktemp)

cat <<EOF >"$TMP_SCRIPT"
#!/bin/bash

# Lógica de Gum (Mantenemos la misma que funcionaba)
gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" "GESTIONAR: $ARCHIVO"

ACCION=\$(gum choose --cursor.foreground 212 --header "¿Qué quieres hacer?" "󰏫  Editar (Neovim)" "󰁯  Crear Backup" "󰈸  Ver Contenido" "󰦪  Restaurar Backup" "Cancelar")

case "\$ACCION" in
    *Editar*)
        nvim '$FULL_PATH'
        ;;
    *Crear*)
        if [ -f '$FULL_PATH.bak' ]; then
            if gum confirm '¿Sobreescribir backup existente?'; then
                cp '$FULL_PATH' '$FULL_PATH.bak'
                gum style --foreground 46 'Backup actualizado.'
            fi
        else
            gum spin --spinner dot --title 'Creando copia...' -- sleep 1
            cp '$FULL_PATH' '$FULL_PATH.bak'
            gum style --foreground 46 'Backup creado.'
        fi
        sleep 1
        ;;
    *Ver*)
        if command -v bat &> /dev/null; then
            bat --style=plain --paging=always '$FULL_PATH'
        else
            less '$FULL_PATH'
        fi
        ;;
    *Restaurar*)
         if [ -f '$FULL_PATH.bak' ]; then
            if gum confirm '¿Restaurar y sobreescribir?'; then
                cp '$FULL_PATH.bak' '$FULL_PATH'
                gum style --foreground 46 'Restaurado.'
                sleep 1
            fi
         else
            gum style --foreground 196 'No existe backup.'
            sleep 2
         fi
         ;;
esac
rm -- "\$0"
EOF

chmod +x "$TMP_SCRIPT"

# --- PASO 3: EJECUCIÓN ---
$TERMINAL --title="$WINDOW_TITLE" -e "$TMP_SCRIPT"
