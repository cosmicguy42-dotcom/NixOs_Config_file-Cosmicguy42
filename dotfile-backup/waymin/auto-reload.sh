#!/usr/bin/env bash
# ==============================================================================
# Auto-reload Waybar dès qu'un fichier de configuration ou CSS est modifié
# Compatible NixOS
# ==============================================================================

CONFIG_DIR="$HOME/.config/waybar"

start_waybar() {
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch exec waybar >/dev/null 2>&1
    else
        nohup waybar >/dev/null 2>&1 &
    fi
}

# Démarrer Waybar s'il ne tourne pas encore
if ! pgrep -x waybar >/dev/null 2>&1 && ! pgrep -x .waybar-wrapped >/dev/null 2>&1; then
    start_waybar
fi

# Surveillance en continu des modifications
while inotifywait -q -e close_write,moved_to "$CONFIG_DIR"; do
    if pgrep -x waybar >/dev/null 2>&1 || pgrep -x .waybar-wrapped >/dev/null 2>&1; then
        pkill -SIGUSR2 -x waybar 2>/dev/null || pkill -SIGUSR2 -x .waybar-wrapped 2>/dev/null
    else
        start_waybar
    fi
done
