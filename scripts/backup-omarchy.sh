#!/usr/bin/env bash

# Recaptura el estado vivo de esta máquina hacia el repo.
# Después de ejecutarlo revisa `git status` / `git diff` antes de commitear.
#
#   scripts/backup-omarchy.sh    recapturar
#
# Reglas: los themes y plugins instalados desde git se registran por URL
# (son cientos de MB), no se copian. Los symlinks que crea Omarchy tampoco.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEMES="$HOME/.config/omarchy/themes"

RSYNC_ARGS=(-a --delete --exclude='.git/' --exclude='.github/'
            --exclude='*.bak*' --exclude='*.orig' --exclude='*~'
            --exclude='.DS_Store' --exclude='*.lock'
            --exclude='htop_history'          # historial de comandos, no config
            --exclude='kitty.con'             # resto de una edición truncada: kitty.conf es el que vive
            --exclude='lazygit/config.yml')

sync_dir() {
  local src="$1" dest="$2"
  [[ -d "$src" ]] || { echo "   no existe, omitido: $src"; return 0; }
  mkdir -p "$dest"
  rsync "${RSYNC_ARGS[@]}" --copy-unsafe-links "$src/" "$dest/"
  echo "   ${src#$HOME/} -> ${dest#$REPO/}"
}

sync_file() {
  local src="$1" dest="$2"
  [[ -f "$src" ]] || { echo "   no existe, omitido: $src"; return 0; }
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  echo "   ${src#$HOME/} -> ${dest#$REPO/}"
}

link_target() { [[ -L "$1" ]]; }

# ---------------------------------------------------------------------------
printf '\n== Themes escritos a mano\n'
alive=()
for dir in "$THEMES"/*/; do
  name="$(basename "$dir")"
  [[ -d "$dir/.git" ]] && continue                      # instalado de git -> solo URL
  [[ -z "$(find "$dir" -type f -print -quit)" ]] && continue   # carpeta vacía
  alive+=("$name")
  sync_dir "${dir%/}" "$REPO/omarchy/themes/$name"
done
# themes que ya no existen en esta máquina salen del repo
for dir in "$REPO"/omarchy/themes/*/; do
  name="$(basename "$dir")"
  printf '%s\n' "${alive[@]}" | grep -qx "$name" || { rm -rf "$dir"; echo "   fuera del repo: $name"; }
done

printf '\n== Listas de lo instalado desde git\n'
{
  echo "# Themes instalados con \`omarchy theme install <url>\` (no se commitean)."
  for dir in "$THEMES"/*/; do
    [[ -d "$dir/.git" ]] || continue
    url="$(git -C "$dir" remote get-url origin 2>/dev/null)" || continue
    printf '%s\t%s\n' "$(basename "$dir")" "$url"
  done
} > "$REPO/omarchy/themes-installed.txt"
echo "   themes-installed.txt ($(grep -cv '^#' "$REPO/omarchy/themes-installed.txt") entradas)"

{
  echo "# Plugins instalados con \`omarchy plugin add <url> --enable --yes\` (no se commitean)."
  for dir in "$HOME/.config/omarchy/plugins"/*/; do
    [[ -d "$dir/.git" ]] || continue
    url="$(git -C "$dir" remote get-url origin 2>/dev/null)" || continue
    printf '%s\t%s\n' "$(basename "$dir")" "$url"
  done
  for link in "$HOME/.config/omarchy/plugins"/*; do
    [[ -L "$link" ]] && printf '# %s  (symlink a %s; lo crea su instalador, no se commitea)\n' \
      "$(basename "$link")" "$(readlink "$link")"
  done
} > "$REPO/omarchy/plugins-installed.txt"
echo "   plugins-installed.txt ($(grep -cv '^#' "$REPO/omarchy/plugins-installed.txt") entradas)"

printf '\n== Config de Omarchy\n'
for sub in branding extensions defaults hooks; do
  sync_dir "$HOME/.config/omarchy/$sub" "$REPO/omarchy/config/$sub"
done
for f in shell.json shell.toml language; do
  sync_file "$HOME/.config/omarchy/$f" "$REPO/omarchy/config/$f"
done
if [[ -f "$HOME/.local/state/omarchy/current/theme.name" ]]; then
  cp -a "$HOME/.local/state/omarchy/current/theme.name" "$REPO/omarchy/theme.txt"
  echo "   theme.name -> omarchy/theme.txt"
fi
{
  echo "# Flags de Omarchy (\`omarchy toggle <flag> on\`)."
  ls -1 "$HOME/.local/state/omarchy/toggles" 2>/dev/null || true
} > "$REPO/omarchy/toggles.txt"
{
  echo "# Wallpaper fijado por theme (recuerda el \`omarchy theme bg set\` tras \`theme set\`)."
  for f in "$HOME/.local/state/omarchy/theme-backgrounds"/*; do
    [[ -f "$f" ]] && printf '%s\t%s\n' "$(basename "$f")" "$(basename "$(head -1 "$f")")"
  done
} > "$REPO/omarchy/theme-backgrounds.txt"
echo "   toggles.txt y theme-backgrounds.txt regenerados"

printf '\n== Hyprland\n'
for f in "$HOME/.config/hypr"/*; do
  [[ -f "$f" ]] && sync_file "$f" "$REPO/omarchy/hypr/$(basename "$f")"
done
sync_file "$HOME/.config/default/hypr/qconsole.lua" "$REPO/omarchy/hypr-default/qconsole.lua"
sync_dir "$HOME/.config/hyprmoncfg/profiles" "$REPO/omarchy/hyprmoncfg-profiles"

printf '\n== Apps\n'
for app in ghostty alacritty kitty foot fish btop htop mpv nvim git environment.d; do
  sync_dir "$HOME/.config/$app" "$REPO/apps/$app"
done
sync_file "$HOME/.config/lazydocker/config.yml" "$REPO/apps/lazydocker/config.yml"
sync_file "$HOME/.config/starship.toml" "$REPO/apps/starship.toml"
sync_file "$HOME/.config/mimeapps.list" "$REPO/apps/mimeapps.list"
for f in .bashrc .bash_profile .profile; do
  sync_file "$HOME/$f" "$REPO/apps/bash/${f#.}"
done
sync_file "$HOME/.local/bin/backup-cloud.sh" "$REPO/apps/local-bin/backup-cloud.sh"
for unit in "$HOME/.config/systemd/user"/*.service "$HOME/.config/systemd/user"/*.timer; do
  [[ -f "$unit" ]] || continue
  case "$(basename "$unit")" in
    # Los gestionan Omarchy, XDG o el hook que instala voxtype.
    omarchy-*|app-*|browser-*|xdg-*|voxtype.service) continue ;;
  esac
  sync_file "$unit" "$REPO/apps/systemd/user/$(basename "$unit")"
done

# El credential helper de git apunta a una ruta de mise de esta máquina: fuera.
if [[ -f "$REPO/apps/git/config" ]]; then
  perl -0pi -e 's/\[credential "[^"]*"\]\n(\s+helper[^\n]*\n)+//g' "$REPO/apps/git/config"
  echo "   git/config: bloque [credential] eliminado (restore usa 'gh auth setup-git')"
fi

# Symlinks y carpetas que Omarchy genera: no tienen sitio en el repo.
rm -f "$REPO/apps/nvim/lua/plugins/theme.lua" 2>/dev/null || true
rm -rf "$REPO/apps/btop/themes" 2>/dev/null || true
find "$REPO/apps" "$REPO/omarchy" -mindepth 1 -type d -empty -delete 2>/dev/null || true

printf '\n== Modos\n'
find "$REPO" -path "$REPO/.git" -prune -o -type f \( -name '*.sh' -o -name '*.hook' -o -name 'backup-cloud.sh' \) -exec chmod 755 {} \;
find "$REPO" -path "$REPO/.git" -prune -o -type f \( -name '10-owe-sync' -o -name '*.service' -o -name '*.timer' -o -name '*.conf' -o -name '*.lua' -o -name '*.toml' -o -name '*.json' \) -exec chmod 644 {} \;

printf '\nRecapturado. Revisa con:\n'
printf '   git -C %s status --short\n' "$REPO"
printf '   git -C %s diff --stat\n' "$REPO"
