#!/usr/bin/env bash
# Toggle Bluetooth power state with notification

if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    bluetoothctl power off
    notify-send -i bluetooth-disabled "Bluetooth" "Bluetooth désactivé"
else
    bluetoothctl power on
    notify-send -i bluetooth-active "Bluetooth" "Bluetooth activé"
fi
