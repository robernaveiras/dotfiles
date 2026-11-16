#!/usr/bin/env bash

# Restaura la personalización de Omarchy (themes, Hyprland, bar, apps) desde
# este repo en una máquina con Omarchy instalado.
#
#   scripts/restore-omarchy.sh              restaurar de verdad
#   scripts/restore-omarchy.sh --dry-run    mostrar qué se haría, sin tocar nada
#   scripts/restore-omarchy.sh --no-remote  saltar `theme install` / `plugin add`
#
# Es idempotente: se puede repetir sin duplicar nada.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY=0
SKIP_REMOTE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY=1 ;;
    --no-remote) SKIP_REMOTE=1 ;;
    -h|--help)   sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           echo "uso: $0 [--dry-run] [--no-remote]" >&2; exit 1 ;;
  esac
done

step()  { printf '\n== %s\n' "$1"; }
note()  { printf '   %s\n' "$1"; }
warn()  { printf '   AVISO: %s\n' "$1" >&2; }
run()   { if ((DRY)); then printf '   [dry] %s\n' "$*"; else "$@"; fi; }

copy_dir() {
  local src="$1" dest="$2"
  [[ -d "$src" ]] || { note "no existe, omitido: ${src#$REPO/}"; return 0; }
  run mkdir -p "$dest"
  run cp -a "$src/." "$dest/"
  note "${src#$REPO/} -> ${dest#$HOME/}"
}

copy_file() {
  local src="$1" dest="$2"
  [[ -f "$src" ]] || { note "no existe, omitido: ${src#$REPO/}"; return 0; }
  run mkdir -p "$(dirname "$dest")"
  run cp -a "$src" "$dest"
  note "${src#$REPO/} -> ${dest#$HOME/}"
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# 0. Prerrequisitos
# ---------------------------------------------------------------------------
if ! have omarchy; then
  warn "omarchy no está en el PATH: instala Omarchy primero (https://omarchy.org)."
  warn "El resto del script funciona igual para copiar ficheros; instala Omarchy y repite."
fi

# ---------------------------------------------------------------------------
# 1. Themes escritos a mano + config de Omarchy
# ---------------------------------------------------------------------------
step "Themes propios -> ~/.config/omarchy/themes"
for theme_dir in "$REPO"/omarchy/themes/*/; do
  copy_dir "${theme_dir%/}" "$HOME/.config/omarchy/themes/$(basename "$theme_dir")"
done

step "Config de Omarchy -> ~/.config/omarchy"
for sub in branding extensions defaults hooks; do
  copy_dir "$REPO/omarchy/config/$sub" "$HOME/.config/omarchy/$sub"
done
for f in shell.json shell.toml language; do
  copy_file "$REPO/omarchy/config/$f" "$HOME/.config/omarchy/$f"
done

# Los hooks se ejecutan: todo lo que no sea .sample ha de ser ejecutable.
if [[ -d "$REPO/omarchy/config/hooks" ]]; then
  while IFS= read -r hook; do
    run chmod +x "$HOME/.config/omarchy/hooks/${hook#$REPO/omarchy/config/hooks/}"
  done < <(find "$REPO/omarchy/config/hooks" -type f ! -name '*.sample')
fi

# ---------------------------------------------------------------------------
# 2. Themes y plugins instalados desde git (se clonan, no se commitean)
# ---------------------------------------------------------------------------
if ((SKIP_REMOTE)); then
  step "Plugins y themes de git: saltados (--no-remote)"
else
  step "Plugins de git -> omarchy plugin add"
  while IFS=$'\t' read -r name url; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    if [[ -d "$HOME/.config/omarchy/plugins/$name" ]]; then
      note "ya instalado: $name"
      continue
    fi
    run omarchy plugin add "$url" --enable --yes
  done < "$REPO/omarchy/plugins-installed.txt"

  step "Themes de git -> omarchy theme install"
  while IFS=$'\t' read -r name url; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    if [[ -d "$HOME/.config/omarchy/themes/$name" ]]; then
      note "ya instalado: $name"
      continue
    fi
    run omarchy theme install "$url"
  done < "$REPO/omarchy/themes-installed.txt"
fi

# ---------------------------------------------------------------------------
# 3. Hyprland (el orden importa: el preload de qconsole va en hyprland.lua)
# ---------------------------------------------------------------------------
step "Hyprland -> ~/.config/hypr y ~/.config/default/hypr"
for f in "$REPO"/omarchy/hypr/*; do
  base="$(basename "$f")"
  case "$base" in
    # Config de monitor ligada a este hardware: solo si el panel coincide.
    monitors.lua|hyprmoncfg-monitors.lua)
      if have hyprctl && hyprctl monitors all 2>/dev/null | grep -q "3440x1440"; then
        copy_file "$f" "$HOME/.config/hypr/$base"
      else
        copy_file "$f" "$HOME/.config/hypr/$base.disabled"
        warn "$base no se activa: no se ve 3440x1440 en esta máquina. Queda como $base.disabled; revisa 'hyprctl monitors all'."
      fi
      ;;
    *) copy_file "$f" "$HOME/.config/hypr/$base" ;;
  esac
done
copy_file "$REPO/omarchy/hypr-default/qconsole.lua" "$HOME/.config/default/hypr/qconsole.lua"
copy_dir "$REPO/omarchy/hyprmoncfg-profiles" "$HOME/.config/hyprmoncfg/profiles"

# ---------------------------------------------------------------------------
# 4. Apps
# ---------------------------------------------------------------------------
step "Apps -> ~/.config"
for app in ghostty alacritty kitty foot fish btop htop mpv nvim lazydocker git environment.d; do
  copy_dir "$REPO/apps/$app" "$HOME/.config/$app"
done
copy_file "$REPO/apps/starship.toml" "$HOME/.config/starship.toml"
copy_file "$REPO/apps/mimeapps.list" "$HOME/.config/mimeapps.list"
for f in bashrc bash_profile profile; do
  copy_file "$REPO/apps/bash/$f" "$HOME/.$f"
done

# gh se encarga del credential helper de git; el repo no lleva rutas hardcodeadas.
if have gh && gh auth status >/dev/null 2>&1; then
  run gh auth setup-git
  note "gh auth setup-git (credential helper de git)"
fi

# ---------------------------------------------------------------------------
# 5. Enlaces que crea Omarchy y el script de backup personal
# ---------------------------------------------------------------------------
step "Symlinks del theme y binarios personales"
run mkdir -p "$HOME/.config/btop/themes" "$HOME/.config/nvim/lua/plugins"
run ln -snf "$HOME/.local/state/omarchy/current/theme/btop.theme" "$HOME/.config/btop/themes/current.theme"
run ln -snf "$HOME/.local/state/omarchy/current/theme/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"
note "btop/themes/current.theme y nvim/lua/plugins/theme.lua apuntan al theme generado"
copy_file "$REPO/apps/local-bin/backup-cloud.sh" "$HOME/.local/bin/backup-cloud.sh"
run chmod +x "$HOME/.local/bin/backup-cloud.sh"

# ---------------------------------------------------------------------------
# 6. systemd user
# ---------------------------------------------------------------------------
step "systemd --user"
copy_dir "$REPO/apps/systemd/user" "$HOME/.config/systemd/user"
if have systemctl; then
  run systemctl --user daemon-reload
  for unit in backup-cloud.timer; do
    [[ -f "$HOME/.config/systemd/user/$unit" ]] && run systemctl --user enable --now "$unit"
  done
else
  note "systemctl no disponible: unidades copiadas, pendientes de activar"
fi

# ---------------------------------------------------------------------------
# 7. Font, toggles, theme y wallpaper
# ---------------------------------------------------------------------------
step "Font y toggles"
if have omarchy; then
  run omarchy font set "JetBrainsMono Nerd Font"
  while IFS= read -r flag; do
    [[ -z "$flag" || "$flag" == \#* ]] && continue
    run omarchy toggle "$flag" on
  done < "$REPO/omarchy/toggles.txt"
fi

step "Theme activo y wallpaper"
if have omarchy; then
  theme="$(head -1 "$REPO/omarchy/theme.txt")"
  run omarchy theme set "$theme"
  # `theme set` pone el primer fondo del theme: hay que re-fijar el tuyo.
  bg="$(awk -F'\t' -v t="$theme" '$1==t {print $2}' "$REPO/omarchy/theme-backgrounds.txt")"
  if [[ -n "$bg" ]]; then
    bg_path="$HOME/.config/omarchy/themes/$theme/backgrounds/$bg"
    if [[ -f "$bg_path" ]] || ((DRY)); then
      run omarchy theme bg set "$bg_path"
      note "wallpaper fijado: $bg"
    else
      warn "no se encuentra el fondo $bg de $theme"
    fi
  fi
else
  note "sin omarchy: ejecuta a mano 'omarchy theme set <theme>' y luego 'omarchy theme bg set'"
fi

# ---------------------------------------------------------------------------
# 8. Recargar el compositor si hay sesión
# ---------------------------------------------------------------------------
step "Recarga"
if have hyprctl && hyprctl instantiator_class >/dev/null 2>&1; then
  run hyprctl reload
  note "hyprctl reload"
else
  note "no hay sesión Hyprland: la config se aplicará al iniciar la sesión"
fi

printf '\nListo. %s\n' "$([[ $DRY -eq 1 ]] && echo '(dry-run: no se cambió nada)' || echo 'Revisa el theme, el bar y los atajos antes de dar el trabajo por bueno.')"
