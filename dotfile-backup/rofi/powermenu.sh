#!/usr/bin/env bash

# Define the options
LOCK="  Lock"
LOGOUT="󰍃  Logout"
SUSPEND="󰒲  Suspend"
REBOOT="󰑓  Reboot"
SHUTDOWN="󰐥  Shutdown"

options="$LOCK\n$LOGOUT\n$SUSPEND\n$REBOOT\n$SHUTDOWN"

# Launch rofi
chosen=$(echo -e "$options" | rofi -dmenu -i -theme ~/.config/rofi/power-theme.rasi -p "Session")

# Execute the chosen command
case $chosen in
    $LOCK)
        swaylock ;;
    $LOGOUT)
        niri msg action quit ;;
    $SUSPEND)
        systemctl suspend ;;
    $REBOOT)
        systemctl reboot ;;
    $SHUTDOWN)
        systemctl poweroff ;;
esac

