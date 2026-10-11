pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool hasUPower: dev?.isLaptopBattery ?? false

    property real sysLevel: 1.0
    property bool sysCharging: false
    property bool sysAvailable: false

    readonly property real level: hasUPower ? (dev?.percentage ?? 0) : sysLevel
    readonly property bool charging: hasUPower ? (dev?.state === UPowerDeviceState.Charging || dev?.state === UPowerDeviceState.FullyCharged) : sysCharging
    readonly property bool available: hasUPower ? true : sysAvailable

    Process {
        id: proc
        command: ["sh", "-c", "if [ -d /sys/class/power_supply/BAT* ]; then cat /sys/class/power_supply/BAT*/capacity; cat /sys/class/power_supply/BAT*/status; else echo 'NONE'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines[0] !== "NONE" && lines.length >= 2) {
                    const cap = parseInt(lines[0]);
                    if (!isNaN(cap)) {
                        root.sysLevel = Math.max(0, Math.min(1, cap / 100.0));
                        root.sysCharging = lines[1].trim() === "Charging";
                        root.sysAvailable = true;
                    }
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: !root.hasUPower
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
