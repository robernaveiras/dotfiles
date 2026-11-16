#!/usr/bin/env bash
# Restore this repo's Omarchy + Hyprland personalization on a fresh Omarchy install.
# Idempotent: re-run after any Omarchy update to re-apply your overrides.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OM="$HOME/.config/omarchy"
HYPR="$HOME/.config/hypr"
ACTIVE_THEME="${ACTIVE_THEME:-emberglade}"
ACTIVE_BG="$OM/themes/$ACTIVE_THEME/backgrounds/0-redqueen.webp"
FONT="${FONT:-JetBrainsMono Nerd Font}"

require_omarchy() {
  if ! command -v omarchy >/dev/null 2>&1; then
    echo "omarchy no está instalado: instala Omarchy primero (https://omarchy.org)" >&2
    exit 1
  fi
}
require_omarchy

# --- 1. Themes (own themes; git-sourced ones are reinstalled by URL) ---
mkdir -p "$OM/themes"
for d in "$REPO"/omarchy/themes/*/; do
  cp -a "$d" "$OM/themes/"
done

# --- 2. Bar layout, shell config, language, branding, hooks, defaults ---
mkdir -p "$OM/bar" "$OM/hooks" "$OM/branding" "$OM/extensions" "$OM/defaults"
cp "$REPO/omarchy/bar/shell.json"  "$OM/shell.json"
cp "$REPO/omarchy/shell.toml"      "$OM/shell.toml"
cp "$REPO/omarchy/language"        "$OM/language"
cp -a "$REPO/omarchy/branding/."   "$OM/branding/"
cp -a "$REPO/omarchy/extensions/." "$OM/extensions/"
cp -a "$REPO/omarchy/defaults/."   "$OM/defaults/"
cp -a "$REPO/omarchy/hooks/."      "$OM/hooks/"
chmod +x "$OM"/hooks/*/*.hook "$OM"/hooks/*/* 2>/dev/null || true

# --- 3. Hyprland overrides ---
mkdir -p "$HYPR" "$HOME/.config/default/hypr"
cp "$REPO/omarchy/hypr/hyprland.lua"      "$HYPR/hyprland.lua"
cp "$REPO/omarchy/hypr/bindings.lua"      "$HYPR/bindings.lua"
cp "$REPO/omarchy/hypr/input.lua"         "$HYPR/input.lua"
cp "$REPO/omarchy/hypr/looknfeel.lua"     "$HYPR/looknfeel.lua"
cp "$REPO/omarchy/hypr/autostart.lua"     "$HYPR/autostart.lua"
cp "$REPO/omarchy/hypr/qconsole-size.lua" "$HYPR/qconsole-size.lua"
cp "$REPO/omarchy/hypr/hyprsunset.conf"   "$HYPR/hyprsunset.conf"
cp "$REPO/omarchy/hypr/xdph.conf"         "$HYPR/xdph.conf"
cp "$REPO/omarchy/hypr-default/qconsole.lua" "$HOME/.config/default/hypr/qconsole.lua"

# Monitor config is hardware specific: only copy it when the panel is confirmed.
if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors all 2>/dev/null | grep -q "3440x1440"; then
  cp "$REPO/omarchy/hypr/monitors.lua" "$HYPR/monitors.lua"
  echo "monitors.lua copiado (monitor 3440x1440 detectado)."
else
  cp "$REPO/omarchy/hypr/monitors.lua" "$HYPR/monitors.lua.disabled"
  echo "AVISO: no se detecto el monitor 3440x1440. Ajusta omarchy/hypr/monitors.lua"
  echo "       (guardado como $HYPR/monitors.lua.disabled) y renombralo tras revisarlo."
fi

# --- 4. Plugins and extra themes ---
while read -r url; do
  if [ -z "$url" ] || [[ "$url" == \#* ]]; then continue; fi
  echo "omarchy plugin add $url"
  omarchy plugin add "$url" --enable --yes || echo "  (falló: $url)"
done < "$REPO/omarchy/plugins.txt"

while read -r url; do
  [ -z "$url" ] && continue
  echo "omarchy theme install $url"
  omarchy theme install "$url" || echo "  (falló: $url)"
done < "$REPO/omarchy/themes-extra.txt"

# --- 5. Fonts, theme, wallpaper ---
omarchy font set "$FONT"
omarchy theme set "$ACTIVE_THEME"
# theme set resets the wallpaper to the theme's first background: re-pin ours.
if [ -f "$ACTIVE_BG" ]; then
  omarchy theme bg set "$ACTIVE_BG"
fi

# --- 6. App configs ---
mkdir -p "$HOME/.config/ghostty" "$HOME/.config/alacritty" "$HOME/.config/kitty" \
         "$HOME/.config/fish" "$HOME/.config/nvim" "$HOME/.config/btop" \
         "$HOME/.config/mpv" "$HOME/.config/htop" "$HOME/.config/git" \
         "$HOME/.config/lazydocker"
cp "$REPO/ghostty/config"     "$HOME/.config/ghostty/config"
cp "$REPO/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
cp "$REPO/kitty/kitty.conf"   "$HOME/.config/kitty/kitty.conf"
cp "$REPO/fish/config.fish"   "$HOME/.config/fish/config.fish"
cp "$REPO/starship.toml"      "$HOME/.config/starship.toml"
cp "$REPO/btop/btop.conf"     "$HOME/.config/btop/btop.conf"
cp "$REPO/mpv/mpv.conf"       "$HOME/.config/mpv/mpv.conf"
cp "$REPO/htop/htoprc"        "$HOME/.config/htop/htoprc"
cp -a "$REPO/nvim/."          "$HOME/.config/nvim/"
cp "$REPO/lazydocker/config.yml" "$HOME/.config/lazydocker/config.yml"
# git identity + aliases, without the machine-specific gh credential helper.
awk '/^\[credential/{skip=1} skip{next} {print}' "$REPO/git/config" > "$HOME/.config/git/config"
echo "Después de 'gh auth login' ejecuta: gh auth setup-git"

echo "Personalización restaurada. Reinicia Hyprland (Super+R r) o la sesión."
