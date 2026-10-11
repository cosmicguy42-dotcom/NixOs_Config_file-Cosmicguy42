pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Quick toggles that aren't tied to a specific service.
// Night light + silent mode persist in ~/.local/state/nothing/toggles.json.
Singleton {
    id: root

    property bool dnd: false        // hides notification popups (they're still kept)
    property bool caffeine: false   // idle inhibitor lives in Wallpaper.qml
    property bool nightLight: false // hyprsunset, driven over its IPC
    property bool recording: false  // wf-recorder running (scripts/capture.sh)
    property int recStart: 0        // unix time the recording began
    property int now: 0
    readonly property string recElapsed: {
        const s = Math.max(0, now - recStart);
        return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
    }

    function setNightLight(on) {
        nightLight = on;
        applyNightLight();
        save();
    }
    function applyNightLight() {
        // hyprsunset has no "is identity" query, so we own the state.
        Quickshell.execDetached(["sh", "-c", root.nightLight
            ? "pgrep -x hyprsunset >/dev/null || { hyprsunset & sleep 0.5; }; hyprctl hyprsunset temperature " + Config.nightTemp
            : "hyprctl hyprsunset identity"]);
    }
    function stopRecording() {
        Quickshell.execDetached([Quickshell.shellPath("scripts/capture.sh"), "stop"]);
    }
    FileView {
        path: Theme.stateDir + "/recording"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.recStart = parseInt(text().trim()) || Math.floor(Date.now() / 1000)
    }
    Timer {
        interval: 1000
        running: root.recording
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Math.floor(Date.now() / 1000)
    }

    onDndChanged: save()
    function save() {
        if (store.loaded)
            store.setText(JSON.stringify({ dnd: root.dnd, nightLight: root.nightLight }));
    }

    FileView {
        id: store
        property bool loaded: false
        path: Theme.stateDir + "/toggles.json"
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.dnd = s.dnd ?? false;
                root.nightLight = s.nightLight ?? false;
            } catch (e) {}
            loaded = true;
            root.applyNightLight();
        }
        // First run: a running hyprsunset means night light is on.
        onLoadFailed: firstRun.running = true
    }
    Process {
        id: firstRun
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => {
            root.nightLight = code === 0;
            store.loaded = true;
            root.save();
        }
    }

    Process {
        id: recCheck
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => root.recording = code === 0
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: recCheck.running = true
    }
}
