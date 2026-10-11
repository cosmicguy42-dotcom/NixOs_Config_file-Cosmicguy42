#!/usr/bin/env bash

# Restart swaync and waybar cleanly without duplicating processes
pkill -9 swaync 2>/dev/null || true
pkill -9 waybar 2>/dev/null || true
sleep 0.3

swaync >/dev/null 2>&1 &
if systemctl --user is-enabled waybar >/dev/null 2>&1; then
    systemctl --user restart waybar
else
    waybar >/dev/null 2>&1 &
fi
