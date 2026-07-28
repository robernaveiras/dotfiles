# Guía de Configuración de Sway para Ubuntu

Este repositorio contiene una configuración personal para el gestor de ventanas [Sway](https://swaywm.org/) y un conjunto de herramientas complementarias para tener un entorno de escritorio completo y funcional en Ubuntu 26.04 o superior.

## Paso 1: Clonar el Repositorio

Primero, clona este repositorio en tu máquina local.

```bash
git clone https://github.com/tu-usuario/tu-repositorio.git
cd tu-repositorio
```
**Nota:** Reemplaza `https://github.com/tu-usuario/tu-repositorio.git` con la URL real de este repositorio.

## Paso 2: Instalación de Paquetes

Abre una terminal e instala todas las dependencias y programas necesarios.

### Paquetes Principales desde APT

```bash
sudo apt update
sudo apt install -y sway swaybg waybar dunst nautilus wget grim slurp btop cliphist unzip wlogout wl-clipboard bluetui pavucontrol polkit-kde-agent-1 neovim fish
```

### Terminal Ghostty

Esta configuración usa [Ghostty](https://github.com/ghostty-org/ghostty) como emulador de terminal por defecto.

```bash
sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu
sudo apt update
sudo apt install ghostty
```

### Navegador Google Chrome

```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb
```

### Lazydocker (Opcional)

Se incluye un atajo de teclado para [Lazydocker](https://github.com/jesseduffield/lazydocker) para gestionar contenedores Docker.

```bash
go install github.com/jesseduffield/lazydocker@latest
```

## Paso 3: Instalación de la Tipografía

La configuración utiliza la fuente `SourceCodePro Nerd Font` para asegurar que todos los iconos se muestren correctamente.

1.  Descarga y extrae la fuente:
    ```bash
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/SourceCodePro.zip
    mkdir -p ~/.local/share/fonts
    unzip SourceCodePro.zip -d ~/.local/share/fonts/
    rm SourceCodePro.zip
    ```
2.  Actualiza la caché de fuentes del sistema:
    ```bash
    fc-cache -fv
    ```

## Paso 4: Copia de Archivos de Configuración

Ahora, copia los archivos y directorios de configuración a las ubicaciones correctas.

1.  **Crea los directorios necesarios:**
    ```bash
    mkdir -p ~/.config/sway/themes
    mkdir -p ~/.scripts
    ```

2.  **Copia las configuraciones:**
    ```bash
    cp -r ./waybar/ ~/.config/
    cp -r ./dunst/ ~/.config/
    cp -r ./kitty/ ~/.config/
    cp -r ./ghostty/ ~/.config/
    cp -r ./wlogout/ ~/.config/
    cp -r ./walker/ ~/.config/
    cp -r ./btop/ ~/.config/
    cp -r ./lazydocker/ ~/.config/
    cp -r ./pavucontrol/ ~/.config/
    cp -r ./nvim/ ~/.config/
    cp -r ./fish/ ~/.config/
    cp ./config ~/.config/sway/config
    cp ./themes/tokyonight.conf ~/.config/sway/themes/
    cp ./scripts/*.sh ~/.scripts/
    ```

3.  **Da permisos de ejecución a los scripts:**
    ```bash
    chmod +x ~/.scripts/*.sh
    ```

## Paso 5: Configuración Final

### Cambiar el Wallpaper

El archivo de configuración de Sway ha sido modificado para usar una ruta genérica para el wallpaper. Necesitas editarlo para apuntar a tu imagen preferida.

1.  Abre el archivo `~/.config/sway/config`.
2.  Busca la siguiente línea:
    ```
    exec swaybg -i $HOME/Pictures/wallpaper.png # ATENCIÓN: Debes cambiar esta ruta a tu wallpaper.
    ```
3.  Reemplaza `$HOME/Pictures/wallpaper.png` con la ruta real de tu wallpaper.

### Cambiar la Shell por Defecto a Fish

Para una mejor experiencia en la terminal, cambia tu shell por defecto a `fish`.
```bash
chsh -s $(which fish)
```
Necesitarás cerrar sesión y volver a iniciarla para que el cambio surta efecto.

## Paso 6: Iniciar Sway

Para iniciar Sway, simplemente escribe `sway` en una terminal TTY (puedes acceder a una con `Ctrl+Alt+F3`). Si usas un gestor de sesiones como GDM o LightDM, deberías ver una opción para iniciar la sesión "Sway" en la pantalla de login.

¡Disfruta de tu nuevo entorno Sway!
