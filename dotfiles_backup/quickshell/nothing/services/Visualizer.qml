pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live audio levels from cava (pipewire), 24 bands in 0..1. Only runs while
// media is playing; bands fall back to 0 otherwise.
Singleton {
    id: root

    readonly property int bands: 24
    property var levels: Array(bands).fill(0)
    readonly property bool active: Player.playing

    onActiveChanged: if (!active) levels = Array(bands).fill(0)

    Process {
        running: root.active
        command: ["cava", "-p", Quickshell.shellPath("apps/cava/config")]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(x => x !== "").map(x => Math.min(1, parseInt(x) / 100));
                if (v.length >= root.bands)
                    root.levels = v.slice(0, root.bands);
            }
        }
    }
}
