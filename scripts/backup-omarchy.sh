#!/usr/bin/env bash
# Capture current Omarchy + Hyprland + app personalization into the repo.
set -euo pipefail

REPO="${REPO:-/home/mephysto/.hermes/cache/scratch/gh-dotfiles}"
CFG="$HOME/.config"
STATE="$HOME/.local/state/omarchy"

mkdir -p "$REPO/omarchy/themes" "$REPO/omarchy/hypr" "$REPO/omarchy/hypr-default" \
         "$REPO/omarchy/hooks" "$REPO/omarchy/branding" "$REPO/omarchy/extensions" \
         "$REPO/omarchy/defaults" "$REPO/omarchy/bar" "$REPO/omarchy/toggles" \
         "$REPO/apps" "$REPO/scripts"

# 1. Hand-written themes only (git-sourced themes are reinstalled by URL).
for d in "$CFG"/omarchy/themes/*/; do
  name=$(basename "$d")
  [ -e "$d/.git" ] && continue
  [ -z "$(find "$d" -type f)" ] && continue
  cp -a "$d" "$REPO/omarchy/themes/"
done

# 2. Installed-from-git theme + plugin URLs (restore re-installs them).
: > "$REPO/omarchy/themes-extra.txt"
for d in "$CFG"/omarchy/themes/*/; do
  [ -d "$d/.git" ] && git -C "$d" remote get-url origin 2>/dev/null >> "$REPO/omarchy/themes-extra.txt"
done
: > "$REPO/omarchy/plugins.txt"
for d in "$CFG"/omarchy/plugins/*/; do
  url=$(git -C "$d" remote get-url origin 2>/dev/null)
  if [ -n "$url" ]; then echo "$url" >> "$REPO/omarchy/plugins.txt"; else echo "# local plugin: $(basename "$d")" >> "$REPO/omarchy/plugins.txt"; fi
done

# 3. Omarchy user config.
cp "$CFG/omarchy/shell.json" "$REPO/omarchy/bar/shell.json"
cp "$CFG/omarchy/shell.toml" "$REPO/omarchy/shell.toml"
cp "$CFG/omarchy/language"  "$REPO/omarchy/language"
cp -a "$CFG/omarchy/branding/."   "$REPO/omarchy/branding/"
cp -a "$CFG/omarchy/extensions/." "$REPO/omarchy/extensions/"
cp -a "$CFG/omarchy/defaults/."   "$REPO/omarchy/defaults/"
cp -a "$CFG/omarchy/hooks/."      "$REPO/omarchy/hooks/"

# 4. Hyprland user overrides.
cp "$CFG/hypr/hyprland.lua" "$REPO/omarchy/hypr/hyprland.lua"
cp "$CFG/hypr/bindings.lua" "$REPO/omarchy/hypr/bindings.lua"
cp "$CFG/hypr/input.lua" "$REPO/omarchy/hypr/input.lua"
cp "$CFG/hypr/looknfeel.lua" "$REPO/omarchy/hypr/looknfeel.lua"
cp "$CFG/hypr/monitors.lua" "$REPO/omarchy/hypr/monitors.lua"
cp "$CFG/hypr/autostart.lua" "$REPO/omarchy/hypr/autostart.lua"
cp "$CFG/hypr/qconsole-size.lua" "$REPO/omarchy/hypr/qconsole-size.lua"
cp "$CFG/hypr/hyprsunset.conf" "$REPO/omarchy/hypr/hyprsunset.conf"
cp "$CFG/hypr/xdph.conf" "$REPO/omarchy/hypr/xdph.conf"
cp "$CFG/hypr/hyprmoncfg-monitors.lua" "$REPO/omarchy/hypr/hyprmoncfg-monitors.lua.example"
cp "$CFG/default/hypr/qconsole.lua" "$REPO/omarchy/hypr-default/qconsole.lua"

# 5. Toggles (feature flags the user switched).
find "$STATE/toggles" -maxdepth 2 -printf '%p\n' | sed "s|$STATE/toggles/||" > "$REPO/omarchy/toggles/list.txt"

# 6. App configs the user edited by hand.
mkdir -p "$REPO/ghostty" "$REPO/alacritty" "$REPO/kitty" "$REPO/fish" "$REPO/nvim" \
         "$REPO/btop" "$REPO/mpv" "$REPO/htop" "$REPO/git" "$REPO/lazydocker"
cp "$CFG/ghostty/config" "$REPO/ghostty/config"
cp "$CFG/alacritty/alacritty.toml" "$REPO/alacritty/alacritty.toml"
cp "$CFG/kitty/kitty.conf" "$REPO/kitty/kitty.conf"
cp "$CFG/fish/config.fish" "$REPO/fish/config.fish"
cp "$CFG/starship.toml" "$REPO/starship.toml"
cp "$CFG/htop/htoprc" "$REPO/htop/htoprc"
cp "$CFG/mpv/mpv.conf" "$REPO/mpv/mpv.conf"
cp "$CFG/btop/btop.conf" "$REPO/btop/btop.conf"
cp "$CFG/git/config" "$REPO/git/config"
cp "$CFG/lazydocker/config.yml" "$REPO/lazydocker/config.yml" 2>/dev/null || true
cp "$CFG/nvim/init.lua" "$CFG/nvim/lazy-lock.json" "$CFG/nvim/lazyvim.json" "$CFG/nvim/stylua.toml" "$REPO/nvim/" 2>/dev/null || true

echo "captured into $REPO"
