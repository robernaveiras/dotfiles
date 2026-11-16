#!/usr/bin/env bash

# Almacenamiento local montado con rclone
DEST="file:///home/mephysto/Cloud/GoogleDrive/Backup_mephysto"
# Origen a respaldar
SRC="/home/mephysto"
MOUNT_DIR="/home/mephysto/Cloud/GoogleDrive/"

# Bus para notificaciones de escritorio
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

if ! mountpoint -q "$MOUNT_DIR"; then
  notify-send "Backup Secundario Fallido" "El volumen no está montado en $MOUNT_DIR." \
    --urgency=critical --icon=drive-harddisk-error
  exit 1
fi

# Exporta paquetes (asumiendo que también es Omarchy/Arch)
pacman -Qqe > "$SRC/paquetes_arch.txt"

# El flag --no-encryption es la clave aquí
if duplicity incr --full-if-older-than 1M \
  --no-encryption \
  --exclude "$SRC/Cloud" \
  --exclude "$SRC/.cache" \
  --exclude "$SRC/Downloads" \
  --exclude "$SRC/Documents/Strata" \
  --exclude "$SRC/.local/share" \
  --exclude "$SRC/.laya" \
  --exclude "$SRC/.lmstudio" \
  --exclude "$SRC/.hermes" \
  --exclude "$SRC/Work" \
  --exclude "$SRC/.config/google-chrome" \
  "$SRC" "$DEST"; then
  
  # Limpieza de backups viejos (también sin cifrar)
  duplicity remove-older-than 3M --force --no-encryption "$DEST"
  
  # Limpia la base de datos local de Duplicity para ahorrar espacio
  duplicity cleanup --force --no-encryption "$DEST"
  
  notify-send "Backup Completado" "Copia secundaria subida sin cifrar." \
    --urgency=normal --icon=emblem-synchronizing
else
  notify-send "Error de Backup" "Fallo en Duplicity secundario." \
    --urgency=critical --icon=dialog-error
  exit 1
fi
