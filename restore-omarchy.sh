#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$CONFIG_DIR/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
INSTALL_PLUGINS=true
INSTALL_THEMES=true

for arg in "$@"; do
  case "$arg" in
    --no-plugins) INSTALL_PLUGINS=false ;;
    --no-themes) INSTALL_THEMES=false ;;
    -h|--help)
      echo "Uso: $0 [--no-plugins] [--no-themes]"
      echo "Restaura la configuración de Omarchy y dotfiles en $CONFIG_DIR."
      exit 0
      ;;
    *)
      echo "Opción desconocida: $arg" >&2
      exit 1
      ;;
  esac
done

backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local rel="${target#"$CONFIG_DIR"/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -a "$target" "$BACKUP_DIR/$rel"
  fi
}

echo "Respaldando configuraciones existentes en $BACKUP_DIR (si existen)..."

for dir in alacritty fish ghostty hypr kitty nvim voxtype; do
  backup_path "$CONFIG_DIR/$dir"
  mkdir -p "$CONFIG_DIR/$dir"
  cp -a "$REPO_DIR/$dir/." "$CONFIG_DIR/$dir/"
done

# btop: preservar themes/current.theme gestionado por Omarchy
backup_path "$CONFIG_DIR/btop/btop.conf"
mkdir -p "$CONFIG_DIR/btop"
cp -a "$REPO_DIR/btop/btop.conf" "$CONFIG_DIR/btop/btop.conf"

# default/hypr/qconsole.lua
backup_path "$CONFIG_DIR/default/hypr/qconsole.lua"
mkdir -p "$CONFIG_DIR/default/hypr"
cp -a "$REPO_DIR/default/hypr/qconsole.lua" "$CONFIG_DIR/default/hypr/qconsole.lua"

# Omarchy config
mkdir -p "$CONFIG_DIR/omarchy/defaults" \
         "$CONFIG_DIR/omarchy/extensions" \
         "$CONFIG_DIR/omarchy/hooks/theme-set.d" \
         "$CONFIG_DIR/omarchy/themes" \
         "$CONFIG_DIR/omarchy/plugins"

for f in shell.json shell.toml language; do
  backup_path "$CONFIG_DIR/omarchy/$f"
  cp -a "$REPO_DIR/omarchy/$f" "$CONFIG_DIR/omarchy/$f"
done

backup_path "$CONFIG_DIR/omarchy/defaults"
cp -a "$REPO_DIR/omarchy/defaults/." "$CONFIG_DIR/omarchy/defaults/"

backup_path "$CONFIG_DIR/omarchy/extensions"
cp -a "$REPO_DIR/omarchy/extensions/." "$CONFIG_DIR/omarchy/extensions/"

backup_path "$CONFIG_DIR/omarchy/hooks/theme-set.d"
cp -a "$REPO_DIR/omarchy/hooks/theme-set.d/." "$CONFIG_DIR/omarchy/hooks/theme-set.d/"
chmod +x "$CONFIG_DIR/omarchy/hooks/theme-set.d/"* 2>/dev/null || true

# Temas locales personalizados
cp -a "$REPO_DIR/omarchy/themes/." "$CONFIG_DIR/omarchy/themes/"

# Plugins de Omarchy
if [[ "$INSTALL_PLUGINS" == true && -f "$REPO_DIR/omarchy/plugins.txt" ]]; then
  echo "Instalando plugins de Omarchy..."
  while read -r name url; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    dest="$CONFIG_DIR/omarchy/plugins/$name"
    if [[ ! -d "$dest" ]]; then
      git clone "$url" "$dest" || echo "Aviso: no se pudo clonar plugin $name" >&2
    fi
  done < "$REPO_DIR/omarchy/plugins.txt"

  if [[ -d /opt/superwhisper/assets/omarchy-plugin/superwhisper-panel && ! -e "$CONFIG_DIR/omarchy/plugins/superwhisper-panel" ]]; then
    ln -s /opt/superwhisper/assets/omarchy-plugin/superwhisper-panel "$CONFIG_DIR/omarchy/plugins/superwhisper-panel"
  fi
fi

# Temas externos de Omarchy
if [[ "$INSTALL_THEMES" == true && -f "$REPO_DIR/omarchy/themes.txt" ]]; then
  echo "Instalando temas externos de Omarchy..."
  while read -r name url; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    dest="$CONFIG_DIR/omarchy/themes/$name"
    if [[ ! -d "$dest" ]]; then
      git clone "$url" "$dest" || echo "Aviso: no se pudo clonar tema $name" >&2
    fi
  done < "$REPO_DIR/omarchy/themes.txt"
fi

echo "Restauración completada."
if [[ -d "$BACKUP_DIR" ]]; then
  echo "Backup guardado en: $BACKUP_DIR"
else
  echo "No había archivos previos que respaldar."
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi
if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell >/dev/null 2>&1 || true
fi
