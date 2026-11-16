#!/bin/bash

# --- 1. SELECCIONAR ---
# Obtenemos la selección de cliphist a través de Walker
SELECCION=$(cliphist list | walker --dmenu --placeholder "Portapapeles (Enter para pegar)")

# Si no seleccionas nada (ESC), salimos
[ -z "$SELECCION" ] && exit 0

# --- 2. PROCESAR Y COPIAR ---
# Decodificamos la selección y la metemos en el portapapeles del sistema
echo "$SELECCION" | cliphist decode | wl-copy

# --- 3. PEGAR AUTOMÁTICAMENTE ---
# IMPORTANTE: Esperamos un momento (0.2s) para asegurarnos de que Walker se ha cerrado
# y el foco ha vuelto a la ventana donde quieres escribir.
sleep 0.2

# Simulamos Ctrl (modificador -M) + tecla v (-k) + soltar Ctrl (modificador -m)
wtype -M ctrl -k v -m ctrl
