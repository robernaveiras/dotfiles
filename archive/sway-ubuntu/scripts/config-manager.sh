#!/bin/bash

# --- CONFIGURACIÓN ---
CURRENT_DIR="$HOME/.config"
TERMINAL="ghostty"
WINDOW_TITLE="ConfigNavigator"

# --- FUNCIÓN GENERADORA DE LISTA ---
# Esta función imprime las opciones directamente, evitando problemas con variables vacías
generar_lista() {
  # 1. Opción para subir de nivel (si no estamos en la raíz)
  if [ "$CURRENT_DIR" != "/" ]; then
    echo " .."
  fi

  # 2. Listar Directorios (Icono  )
  # -mindepth 1 evita que aparezca la carpeta actual '.'
  find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort | sed 's/^/ /'

  # 3. Listar Archivos (Icono  )
  find "$CURRENT_DIR" -maxdepth 1 -type f -printf "%f\n" | sort | sed 's/^/ /'
}

# --- BUCLE DE NAVEGACIÓN ---
while true; do
  # Ejecutamos la función y pasamos la salida DIRECTAMENTE a Walker
  # Esto es mucho más rápido y seguro que usar variables
  SELECCION=$(generar_lista | walker --dmenu --placeholder "Explorando: $CURRENT_DIR")

  # Si se cancela (ESC), salir
  if [ -z "$SELECCION" ]; then
    exit 0
  fi

  # --- LÓGICA DE SELECCIÓN ---

  # 1. Caso: Subir de nivel ".."
  if [[ "$SELECCION" == *".."* ]]; then
    CURRENT_DIR=$(dirname "$CURRENT_DIR")
    continue
  fi

  # 2. Limpiar el nombre (quitar el icono y el espacio inicial)
  # Usamos 'cut' desde el segundo campo, asumiendo que el icono y espacio son el campo 1
  NOMBRE_REAL=$(echo "$SELECCION" | cut -d ' ' -f2-)
  RUTA_COMPLETA="$CURRENT_DIR/$NOMBRE_REAL"

  # 3. Caso: Es Directorio -> Entrar
  if [ -d "$RUTA_COMPLETA" ]; then
    CURRENT_DIR="$RUTA_COMPLETA"
    continue
  fi

  # 4. Caso: Es Archivo -> Salir del bucle y Editar
  if [ -f "$RUTA_COMPLETA" ]; then
    TARGET_FILE="$RUTA_COMPLETA"
    break
  fi
done

# --- MENÚ DE ACCIONES (GHOSTTY + GUM) ---
TMP_SCRIPT=$(mktemp)

cat <<EOF >"$TMP_SCRIPT"
#!/bin/bash
gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" "ARCHIVO: $(basename "$TARGET_FILE")"

ACCION=\$(gum choose --cursor.foreground 212 --header "Ubicación: $(dirname "$TARGET_FILE")" "󰏫  Editar (Neovim)" "󰁯  Crear Backup" "󰈸  Ver Contenido" "󰦪  Restaurar Backup" "Cancelar")

case "\$ACCION" in
    *Editar*)
        nvim '$TARGET_FILE'
        ;;
    *Crear*)
        if [ -f '$TARGET_FILE.bak' ]; then
            if gum confirm '¿Sobreescribir backup?'; then
                cp '$TARGET_FILE' '$TARGET_FILE.bak'
                gum style --foreground 46 'Backup actualizado.'
            fi
        else
            gum spin --spinner dot --title 'Creando copia...' -- sleep 1
            cp '$TARGET_FILE' '$TARGET_FILE.bak'
            gum style --foreground 46 'Backup creado.'
        fi
        sleep 1
        ;;
    *Ver*)
        if command -v bat &> /dev/null; then
            bat --style=plain --paging=always '$TARGET_FILE'
        else
            less '$TARGET_FILE'
        fi
        ;;
    *Restaurar*)
         if [ -f '$TARGET_FILE.bak' ]; then
            if gum confirm '¿Restaurar archivo?'; then
                cp '$TARGET_FILE.bak' '$TARGET_FILE'
                gum style --foreground 46 'Restaurado.'
                sleep 1
            fi
         else
            gum style --foreground 196 'No hay backup.'
            sleep 2
         fi
         ;;
esac
rm -- "\$0"
EOF

chmod +x "$TMP_SCRIPT"
$TERMINAL --title="$WINDOW_TITLE" -e "$TMP_SCRIPT"
