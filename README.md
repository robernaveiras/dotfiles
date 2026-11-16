# Dotfiles — Omarchy + Hyprland

Configuración personal de un equipo con [Omarchy](https://omarchy.org) (Arch) e
Hyprland, pensada para restaurar el mismo escritorio en otra máquina.

Incluye la personalización de Omarchy (themes escritos a mano, bar, hooks,
branding), los overrides de Hyprland y las configs de las apps que uso.
La configuración anterior de Sway/Ubuntu está en `archive/sway-ubuntu/`.

```
omarchy/                 personalización de Omarchy
  themes/                themes escritos a mano (colores, iconos, wallpapers)
  themes-installed.txt   themes instalados desde git: solo la URL
  plugins-installed.txt  plugins del bar instalados desde git: solo la URL
  hypr/                  overrides de Hyprland (~/.config/hypr)
  hypr-default/          override del módulo privado de Omarchy (Quake console)
  hyprmoncfg-profiles/   perfiles de monitores de hyprmoncfg
  config/                shell.json, shell.toml, language, branding, hooks, defaults
  theme.txt              theme activo
  theme-backgrounds.txt  wallpaper fijado por theme
  toggles.txt            flags de Omarchy
apps/                    ghostty, alacritty, kitty, foot, fish, nvim, btop, htop,
                         mpv, starship, git, lazydocker, bash, systemd,
                         environment.d, local-bin
scripts/restore-omarchy.sh   restaurar en otra máquina
scripts/backup-omarchy.sh    recapturar el estado vivo a este repo
archive/sway-ubuntu/     config antigua (Sway, waybar, walker, dunst, wlogout)
```

## Restaurar en otra máquina

1. Instala Omarchy y arranca una sesión (el tema por defecto es Tokyo Night).
2. `git clone https://github.com/robernaveiras/dotfiles.git && cd dotfiles`
3. `scripts/restore-omarchy.sh --dry-run` para ver qué va a tocar.
4. `scripts/restore-omarchy.sh`

Es idempotente: se puede repetir. `--no-remote` deja fuera los `theme install` y
`plugin add` de red si no quieres clonar los 16 themes (~600 MB).

El orden importa y el script lo respeta:

1. themes propios y config de Omarchy (los hooks quedan ejecutables).
2. `omarchy plugin add <url> --enable --yes` y `omarchy theme install <url>`.
3. overrides de Hyprland: `~/.config/hypr` y `~/.config/default/hypr`.
4. apps, bash, systemd user (`daemon-reload` + timer de backup).
5. `omarchy font set`, toggles, `omarchy theme set` y **re-fijar el wallpaper**.

Lo último no es un detalle: `omarchy theme set` pone el primer fondo del theme,
así que el wallpaper se fija después con `omarchy theme bg set` usando
`theme-backgrounds.txt`. Si te saltas ese paso el escritorio amanece con otro
fondo.

## Qué NO está en el repo (y por qué)

- **Themes y plugins instalados desde git**: ~600 MB de wallpapers. Se guardan
  como URL en `themes-installed.txt` / `plugins-installed.txt` y el restore los
  clona. `superwhisper-panel` es un symlink que crea el instalador de
  Superwhisper: hoy apunta a `/opt/superwhisper/assets/omarchy-plugin/…`, que ya
  no existe en esta máquina, así que la entrada del bar necesita un Superwhisper
  que vuelva a traer el plugin.
- **`~/.local/state/omarchy/current/`**: salida generada por `omarchy theme set`.
  Se regenera; los symlinks `~/.config/btop/themes/current.theme` y
  `~/.config/nvim/lua/plugins/theme.lua` los crea Omarchy (el restore los
  recrea por si acaso).
- **El bloque `[credential]` de `git/config`**: apuntaba a una ruta de `mise` de
  esta máquina. El restore lo sustituye con `gh auth setup-git`.
- **Tokens, claves y keyring**: nunca se commitean. `secret-tool`/Keyring y
  `rclone` se configuran a mano en la máquina nueva.

## Piezas que necesitan una decisión

- **Monitores**: `omarchy/hypr/monitors.lua` y `hyprmoncfg-monitors.lua` llevan
  el ROG PG348Q (3440×1440). El restore solo los activa si `hyprctl monitors all`
  ve 3440×1440; si no, los deja como `.disabled` para que los ajustes a mano.
- **Quake console**: Omarchy tiene `share`/`box` privados en su módulo
  `default/hypr/qconsole.lua`, así que un fichero de usuario en la ruta de
  `require` no lo pisa. El patrón que funciona es `omarchy/hypr/qconsole-size.lua`,
  que hace `package.preload["default.hypr.qconsole"]` **antes** de
  `require("default.hypr.omarchy")` en `hyprland.lua`, apuntando a
  `~/.config/default/hypr/qconsole.lua` (`share 0.65`, `box 1.8`). Si copias
  estos ficheros fuera de orden, la consola vuelve al tamaño de Omarchy.
- **Terminales**: las configs de `ghostty`, `alacritty`, `kitty` y `foot`
  importan el theme generado (`~/.local/state/omarchy/current/theme/…`); solo
  llevan tus líneas propias, los colores los pone el theme.
- **Atajos**: `omarchy/hypr/bindings.lua` reasigna `Super+Shift+S` a suspender y
  `Super+Shift+O` a la captura de pantalla, y quita `Super+Shift+M`.

## Actualizar el repo desde la máquina

```bash
scripts/backup-omarchy.sh
git status --short && git diff
```

Recaptura el estado vivo, regenera las listas de URLs, quita el bloque
`[credential]` y normaliza permisos. Revisa el diff antes de commitear:
`btop.conf` y `htoprc` cambian solos cuando tocas la UI.

## Verificación

- `bash -n` en ambos scripts y `luac -p` en todos los `.lua` del repo.
- `scripts/restore-omarchy.sh --dry-run` con `HOME` en un directorio vacío y
  `omarchy`/`gh`/`hyprctl`/`systemctl` stubbeados, para ejercitar todas las
  rutas sin tocar el escritorio.
