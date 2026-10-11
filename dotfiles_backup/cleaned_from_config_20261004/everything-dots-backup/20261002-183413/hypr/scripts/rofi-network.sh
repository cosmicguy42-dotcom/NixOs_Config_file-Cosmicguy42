#!/usr/bin/env bash
# Quick Network & Connectivity Manager for Waybar & Rofi

THEME="$HOME/.config/rofi/minimal.rasi"

# --- FAST TOGGLE MODE ---
if [ "$1" = "--toggle" ]; then
    if [ "$(nmcli radio wifi)" = "enabled" ]; then
        nmcli radio wifi off
        notify-send -i network-wireless-offline "Connectivité" "Wi-Fi désactivé"
    else
        nmcli radio wifi on
        notify-send -i network-wireless-signal-excellent "Connectivité" "Wi-Fi activé"
    fi
    exit 0
fi

# Prevent multiple instances
if pidof rofi >/dev/null 2>&1; then
    pkill -x rofi
    exit 0
fi

# --- STATUS DETECTION ---
WIFI_STATE=$(nmcli radio wifi)
BT_STATE=$(bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo "enabled" || echo "disabled")

# Get active Wi-Fi SSID or Ethernet
ACTIVE_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^oui:\|^yes:' | head -1 | cut -d: -f2)
ACTIVE_ETH=$(nmcli -t -f TYPE,STATE,CONNECTION dev | grep '^ethernet:connected:' | head -1 | cut -d: -f3)

OPTIONS=""

# 1. Wi-Fi Toggle
if [ "$WIFI_STATE" = "enabled" ]; then
    OPTIONS+="󰖩  Wi-Fi : Activé (Désactiver)\n"
else
    OPTIONS+="󰤮  Wi-Fi : Désactivé (Activer)\n"
fi

# 2. Bluetooth Toggle
if [ "$BT_STATE" = "enabled" ]; then
    OPTIONS+="󰂯  Bluetooth : Activé (Désactiver)\n"
else
    OPTIONS+="󰂲  Bluetooth : Désactivé (Activer)\n"
fi

# 3. Active Connection Info
if [ -n "$ACTIVE_SSID" ]; then
    OPTIONS+="󱚽  Connecté à : $ACTIVE_SSID (Déconnecter)\n"
elif [ -n "$ACTIVE_ETH" ]; then
    OPTIONS+="󰌘  Connecté (Ethernet) : $ACTIVE_ETH\n"
fi

# 4. Scan Wi-Fi
if [ "$WIFI_STATE" = "enabled" ]; then
    OPTIONS+="󰤨  Rejoindre un réseau Wi-Fi...\n"
fi

# 5. Advanced GUI Managers
OPTIONS+="󰛳  Paramètres réseau avancés (GUI)\n"
OPTIONS+="󰂱  Gestionnaire Bluetooth (Blueman)"

CHOSEN=$(echo -e "$OPTIONS" | rofi -dmenu -p "󰈀 Connectivité" \
    -theme-str 'window { width: 500px; } entry { placeholder: "Choisir une action..."; }' \
    -theme "$THEME")

[ -z "$CHOSEN" ] && exit 0

case "$CHOSEN" in
    *"Wi-Fi : Activé"*)
        nmcli radio wifi off
        notify-send -i network-wireless-offline "Connectivité" "Wi-Fi désactivé"
        ;;
    *"Wi-Fi : Désactivé"*)
        nmcli radio wifi on
        notify-send -i network-wireless-signal-excellent "Connectivité" "Wi-Fi activé"
        ;;
    *"Bluetooth : Activé"*)
        bluetoothctl power off
        notify-send -i bluetooth-disabled "Bluetooth" "Bluetooth désactivé"
        ;;
    *"Bluetooth : Désactivé"*)
        bluetoothctl power on
        notify-send -i bluetooth-active "Bluetooth" "Bluetooth activé"
        ;;
    *"Connecté à : $ACTIVE_SSID (Déconnecter)"*)
        WIFI_IFACE=$(nmcli -t -f DEVICE,TYPE dev | grep ':wifi' | head -1 | cut -d: -f1)
        if [ -n "$WIFI_IFACE" ]; then
            nmcli dev disconnect iface "$WIFI_IFACE"
            notify-send -i network-wireless-offline "Connectivité" "Déconnecté de $ACTIVE_SSID"
        fi
        ;;
    *"Rejoindre un réseau Wi-Fi..."*)
        notify-send -i network-wireless "Wi-Fi" "Recherche des réseaux..."
        NETWORKS=$(nmcli -t -f SSID,SECURITY,BARS dev wifi list | awk -F: '$1 != "" { printf "%-22s  %-10s  %s\n", $1, $2, $3 }' | sort -u)
        
        SELECTED_NET=$(echo -e "$NETWORKS" | rofi -dmenu -p "󰤨 Réseaux Wi-Fi" \
            -theme-str 'window { width: 500px; } entry { placeholder: "Sélectionner un réseau Wi-Fi..."; }' \
            -theme "$THEME")
        
        [ -z "$SELECTED_NET" ] && exit 0
        SSID=$(echo "$SELECTED_NET" | awk '{print $1}')
        
        # Check if connection is already known
        if nmcli -t -f NAME connection show | grep -Fxq "$SSID"; then
            notify-send -i network-wireless "Wi-Fi" "Connexion à $SSID..."
            if nmcli connection up id "$SSID"; then
                notify-send -i network-wireless-signal-excellent "Wi-Fi" "Connecté avec succès à $SSID"
            else
                notify-send -u critical -i network-wireless-offline "Wi-Fi" "Échec de connexion à $SSID"
            fi
        else
            # Ask password
            PASS=$(rofi -dmenu -password -p "Clé Wi-Fi ($SSID)" \
                -theme-str 'window { width: 450px; } entry { placeholder: "Entrez le mot de passe..."; }' \
                -theme "$THEME")
            
            [ -z "$PASS" ] && exit 0
            notify-send -i network-wireless "Wi-Fi" "Connexion à $SSID..."
            if nmcli dev wifi connect "$SSID" password "$PASS"; then
                notify-send -i network-wireless-signal-excellent "Wi-Fi" "Connecté avec succès à $SSID"
            else
                notify-send -u critical -i network-wireless-offline "Wi-Fi" "Échec de connexion à $SSID"
            fi
        fi
        ;;
    *"Paramètres réseau avancés"*)
        nm-connection-editor &
        ;;
    *"Gestionnaire Bluetooth"*)
        blueman-manager &
        ;;
esac
