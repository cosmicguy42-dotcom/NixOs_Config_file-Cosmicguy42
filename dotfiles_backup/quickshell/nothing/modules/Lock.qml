import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pam
import qs.services

// Session lock (ext-session-lock) with PAM. Triggered by hypridle's
// lock_cmd / `loginctl lock-session` via `qs -c nothing ipc call lock lock`.
// If the shell ever dies while locked, Hyprland keeps the session locked
// (misc:allow_session_lock_restore lets a restarted shell take over).
Scope {
    id: root

    // Persisted so a restart, crash or hot reload of the shell can never drop
    // the lock: the new instance reads this synchronously and re-locks.
    FileView {
        id: lockState
        path: Theme.stateDir + "/locked"
        blockLoading: true
        printErrors: false
    }
    property bool locked: lockState.text().trim() === "1"
    onLockedChanged: lockState.setText(locked ? "1\n" : "0\n")
    property bool unlocking: false
    property bool busy: false
    property bool failed: false
    property bool previewing: false
    property string pending: ""

    function lock() {
        if (Config.get("lock.engine") === "hyprlock") {
            Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock"]);
            return;
        }
        Ui.close();
        failed = false;
        unlocking = false;
        locked = true;
    }
    function tryUnlock(password) {
        if (busy)
            return;
        pending = password;
        busy = true;
        failed = false;
        pam.start();
    }
    function closePreview() { previewing = false; }

    PamContext {
        id: pam
        onPamMessage: {
            if (responseRequired) {
                respond(root.pending);
                root.pending = "";
            }
        }
        onCompleted: result => {
            root.busy = false;
            root.pending = "";
            if (result === PamResult.Success) {
                root.unlocking = true;
                unlockTimer.restart();
            } else {
                root.failed = true;
            }
        }
    }
    Timer {
        id: unlockTimer
        interval: 320 // let the fade-out play
        onTriggered: {
            root.locked = false;
            root.unlocking = false;
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: Theme.bg
            LockSurface {
                lock: root
            }
        }
    }

    // Preview: the same surface as a fullscreen overlay on the focused
    // monitor, without locking (Settings > Power & lock, or `ipc call lock preview`).
    LazyLoader {
        active: root.previewing
        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nothing:lockpreview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.bg
            LockSurface {
                lock: root
                preview: true
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function preview(): void { root.previewing = !root.previewing; }
        function isLocked(): bool { return root.locked; }
    }
}
