# Dotfiles — Omarchy + Hyprland

Personalización real de mi equipo (Omarchy, Hyprland, monitor 3440×1440 21:9).
No es una guía de instalación de cero: Omarchy ya instalado, aquí van **mis
overrides** para reconstruir el mismo escritorio en otra máquina.

## Estructura

```
omarchy/
  themes/             emberglade (activo), emberwood, amberpine  ← themes escritos a mano
  themes-extra.txt    16 themes instalados desde git (se reinstalan por URL)
  plugins.txt         widgets de barra: cloud-drives, system-monitor, omapods
  bar/shell.json      layout de la barra Omarchy (reloj, tiempo, sysmon, AirPods…)
  shell.toml          [font] base-size = 17
  language            en
  hooks/              post-update.d/*.hook, theme-set.d/10-owe-sync
  branding/           about.txt, screensaver.txt
  extensions/         omarchy-menu.jsonc
  defaults/           agent = hermes, dictation = voxtype
  toggles/list.txt    flags activas (screensaver-off, quake-console)
  hypr/               hyprland.lua, bindings.lua, input.lua, looknfeel.lua,
                      monitors.lua, autostart.lua, hyprsunset.conf, xdph.conf,
                      qconsole-size.lua, hyprmoncfg-monitors.lua.example
  hypr-default/       qconsole.lua  → ~/.config/default/hypr/qconsole.lua

ghostty/  alacritty/  kitty/  fish/  nvim/  btop/  htop/  mpv/  git/  lazydocker/  starship.toml
scripts/restore-omarchy.sh    aplica todo en un equipo nuevo
scripts/backup-omarchy.sh     captura el estado actual de esta máquina al repo
archive/sway-ubuntu/          configs antiguas (Sway + Ubuntu: waybar, wlogout, dunst, walker)
```

## Restaurar en otro equipo

```bash
git clone https://github.com/robernaveiras/dotfiles.git
cd dotfiles
./scripts/restore-omarchy.sh
```

Es idempotente: relánzalo después de cada `omarchy update` para re-aplicar los
overrides que Omarchy pueda haber sobrescrito.

```bash
ACTIVE_THEME=emberwood ./scripts/restore-omarchy.sh
FONT="JetBrainsMono Nerd Font" ./scripts/restore-omarchy.sh
```

Qué hace, en orden: copia themes propios y hooks; reinstala plugins y themes de
git con `omarchy plugin add` / `omarchy theme install`; copia los overrides de
Hyprland; fija la fuente monoespace; aplica `emberglade` y **vuelve a fijar**
`0-redqueen.webp` (porque `omarchy theme set` resetea el wallpaper al primer
fondo del theme); copia las configs de apps y la identidad git.

## Detalles que no son obvios

- **Quake console**: Omarchy deja `share` y `box` como locales privados dentro de
  su `default/hypr/qconsole.lua`, así que un archivo de usuario no puede
  sustituirlo. El truco está en `omarchy/hypr/qconsole-size.lua`, que hace
  `package.preload["default.hypr.qconsole"]` **antes** de
  `require("default.hypr.omarchy")` en `hyprland.lua`. Sin ese orden, no funciona.
- **Monitores**: `monitors.lua` y `hyprmoncfg-monitors.lua.example` llevan el ROG
  PG348Q (3440×1440). El restore copia `monitors.lua` solo si `hyprctl` confirma
  ese panel; si no, lo deja como `monitors.lua.disabled` para que lo revises
  (ajustable con `hyprctl monitors all`).
- **Wallpapers**: los propios están autorados en 16:9 (3840×2160) o nativo
  3440×1440; Omarchy recorta por relleno, así que materiales de otra proporción
  se zooman y cortan.
- **git**: se copia identidad y alias, pero **no** el bloque `[credential ...]`
  (apunta a una ruta concreta de `mise`). Tras `gh auth login`, ejecuta
  `gh auth setup-git`.
- **Themes con `.git`**: no se commitean (son repos ajenos, unos 600 MB en local).
  Se reinstalan desde `themes-extra.txt`.
- Los `.sample` dentro de `hooks/` son los ejemplos que trae Omarchy; los hooks
  activos son `install-voxtype.hook`, `setup-fingerprint.hook`,
  `setup-agent.hook` y `10-owe-sync`.

## Actualizar el backup

```bash
cd dotfiles
REPO=$PWD ./scripts/backup-omarchy.sh
git diff && git commit -m "Refresh omarchy personalization"
```
