pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight via brightnessctl. Keybinds call `qs -c nothing ipc call brightness increment`.
Singleton {
    id: root

    property real value: 1
    readonly property bool available: max > 0
    property int max: 0

    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        Quickshell.execDetached(["brightnessctl", "-q", "s", Math.round(value * 100) + "%"]);
        Ui.osd("brightness", value);
    }

    Process {
        running: true
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // name,class,current,percent,max
                const f = text.trim().split(",");
                if (f.length >= 5) {
                    root.max = parseInt(f[4]);
                    root.value = parseInt(f[2]) / root.max;
                }
            }
        }
    }

    IpcHandler {
        target: "brightness"
        function increment(): void { root.set(root.value + 0.05); }
        function decrement(): void { root.set(root.value - 0.05); }
    }
}
