pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth

// Wi-Fi (NetworkManager) and Bluetooth (BlueZ) state for the pill.
Singleton {
    id: root

    // --- Wi-Fi
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property var networks: (wifiDevice?.networks.values ?? []).slice()
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
    readonly property var active: networks.find(n => n.connected) ?? null
    readonly property string wifiIcon: !wifiOn ? "wifi_off"
        : !active ? "signal_wifi_statusbar_not_connected"
        : strengthIcon(active.signalStrength)

    function strengthIcon(s) {
        return s > 0.75 ? "network_wifi" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }
    function setWifi(on) { Networking.wifiEnabled = on; }
    function setScanning(on) {
        if (wifiDevice)
            wifiDevice.scannerEnabled = on;
    }
    // Known/open networks connect directly; new secured ones need a password.
    function connect(network, password) {
        if (password)
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", network.name, "password", password]);
        else
            network.connect();
    }

    // --- Bluetooth
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property var devices: (adapter?.devices.values ?? []).slice()
        .filter(d => d.name !== "" || d.paired)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    readonly property var btConnected: devices.filter(d => d.connected)

    function setBt(on) {
        if (adapter)
            adapter.enabled = on;
    }
    function setDiscovering(on) {
        if (adapter && adapter.enabled)
            adapter.discovering = on;
    }
    function deviceIcon(icon) {
        icon = icon ?? "";
        if (icon.includes("headset") || icon.includes("headphone")) return "headphones";
        if (icon.includes("audio")) return "speaker";
        if (icon.includes("mouse")) return "mouse";
        if (icon.includes("keyboard")) return "keyboard";
        if (icon.includes("phone")) return "smartphone";
        if (icon.includes("gaming")) return "sports_esports";
        if (icon.includes("computer")) return "computer";
        return "bluetooth";
    }
}
