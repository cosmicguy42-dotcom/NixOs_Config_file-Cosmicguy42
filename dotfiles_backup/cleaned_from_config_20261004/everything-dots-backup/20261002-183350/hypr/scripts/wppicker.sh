#!/usr/bin/env bash

# === CONFIG ===
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"

mkdir -p "$WALLPAPER_DIR"
cd "$WALLPAPER_DIR" || exit 1

# === handle spaces name
IFS=$'\n'

# === ICON-PREVIEW SELECTION WITH ROFI, SORTED BY NEWEST ===
SELECTED_WALL=$(for a in $(ls -1t *.jpg *.png *.gif *.jpeg 2>/dev/null); do echo -en "$a\0icon\x1f$a\n"; done | rofi -dmenu -p "Wallpaper")
[ -z "$SELECTED_WALL" ] && exit 1
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# === SET WALLPAPER (MATUGEN + SWWW/SWAYBG) ===
matugen image "$SELECTED_PATH" --source-color-index 0 >/dev/null 2>&1 || true

if pgrep -x swww-daemon >/dev/null 2>&1 || pgrep -x awww-daemon >/dev/null 2>&1; then
    swww img "$SELECTED_PATH" --transition-type any --transition-fps 60 2>/dev/null || true
else
    swaybg -i "$SELECTED_PATH" -m fill >/dev/null 2>&1 &
fi

# === CREATE SYMLINK ===
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"
ln -sf "$SELECTED_PATH" "$HOME/Pictures/current_wallpaper"
cp -f "$SELECTED_PATH" "$HOME/.config/hypr/assets/wallpaper.png" 2>/dev/null || true

pkill -SIGUSR2 waybar 2>/dev/null || true
hyprctl reload 2>/dev/null || true
