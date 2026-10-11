pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU / memory / disk / temperature for the system widget. Only polls while
// something shows it (`active`).
Singleton {
    id: root

    property bool active: false
    property real cpu: 0
    property real mem: 0
    property real disk: 0
    property real temp: 0
    property string memText: ""
    property string diskText: ""

    property var prev: null

    function parse(text) {
        const lines = text.trim().split("\n");
        const c = lines[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = c[3] + (c[4] || 0);
        const total = c.reduce((a, b) => a + b, 0);
        if (prev)
            cpu = Math.max(0, Math.min(1, 1 - (idle - prev.idle) / Math.max(1, total - prev.total)));
        prev = { idle: idle, total: total };

        const kv = {};
        for (const l of lines.slice(1, 3)) {
            const m = /^(\w+):\s+(\d+)/.exec(l);
            if (m) kv[m[1]] = parseInt(m[2]);
        }
        if (kv.MemTotal) {
            mem = 1 - kv.MemAvailable / kv.MemTotal;
            memText = ((kv.MemTotal - kv.MemAvailable) / 1048576).toFixed(1) + " / " + (kv.MemTotal / 1048576).toFixed(1) + " GB";
        }
        const df = (lines[3] ?? "").trim().split(/\s+/);
        if (df.length >= 5) {
            disk = parseInt(df[4]) / 100;
            diskText = (parseInt(df[2]) / 1048576).toFixed(0) + " / " + (parseInt(df[1]) / 1048576).toFixed(0) + " GB";
        }
        const t = parseInt(lines[4] ?? "");
        if (!isNaN(t))
            temp = t / 1000;
    }

    Process {
        id: proc
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; df -Pk / | tail -1; cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
    Timer {
        interval: 2500
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
