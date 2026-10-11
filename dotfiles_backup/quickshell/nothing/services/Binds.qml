pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Keybind editor backend.
//  - reads every live bind from ~/.local/state/nothing/binds.json
//    (written by ~/.config/hypr/hyprland/lib/bindlog.lua on each config load)
//  - your edits live in ~/.config/quickshell/nothing/keybinds.json and are
//    generated into ~/.config/hypr/hyprland/keybinds-custom.lua (unbind the
//    original, bind the new one), then Hyprland reloads.
Singleton {
    id: root

    property var all: []
    property var custom: [] // [{ uid, replaces, combo, action: { type, value, lua, label }, description }]
    property bool capturing: false

    // --- Normalisation ("SUPER + shift + a" -> "SHIFT+SUPER|A"), same as bindlog.lua
    function norm(combo) {
        const mods = [];
        let key = "";
        for (let p of (combo ?? "").split("+")) {
            p = p.trim().toUpperCase();
            if (["SUPER", "SHIFT", "CTRL", "CONTROL", "ALT"].includes(p))
                mods.push(p === "CONTROL" ? "CTRL" : p);
            else if (p)
                key = p;
        }
        return mods.sort().join("+") + "|" + key;
    }
    function keysOf(combo) {
        return (combo ?? "").split("+").map(s => s.trim()).filter(s => s)
            .map(k => ({ SUPER: "Super", CTRL: "Ctrl", CONTROL: "Ctrl", ALT: "Alt", SHIFT: "Shift" })[k.toUpperCase()] ?? k.replace(/^XF86/, ""));
    }
    function isCustom(b) { return (b.source ?? "").startsWith("hyprland/keybinds-custom.lua"); }
    function overrideFor(b) {
        return custom.find(c => norm(c.combo) === b.id) ?? custom.find(c => c.replaces && norm(c.replaces) === b.id) ?? null;
    }

    // --- Plain-English description of what a recorded bind does
    readonly property var shellNames: ({
        launcherToggle: "Open the app launcher", sidebarRightToggle: "Open quick settings", calendarToggle: "Open the calendar",
        weatherToggle: "Open the weather", mediaControlsToggle: "Open media controls", wifiToggle: "Open Wi-Fi networks",
        bluetoothToggle: "Open Bluetooth devices", wallpaperSelectorToggle: "Open the wallpaper picker",
        wallpaperSelectorRandom: "Random wallpaper", toggleLightDark: "Switch light / dark mode", sessionToggle: "Open the power menu",
        settingsToggle: "Open Settings", barToggle: "Hide / show the pill"
    })
    function dirName(d) { return ({ l: "left", r: "right", u: "up", d: "down" })[d] ?? d; }
    function appName(id) {
        const e = DesktopEntries.byId(id) ?? DesktopEntries.byId(id + ".desktop");
        return e ? e.name : id;
    }
    function explain(b) {
        if (b.kind === "lua")
            return "Custom Lua function (" + b.source + ")";
        const a = b.args ?? [];
        const a0 = a[0];
        switch (b.dsp) {
        case "exec_cmd": {
            const cmd = String(a0 ?? "");
            if (cmd.includes("launcher.sh apps")) return "Open the launcher (vicinae, or the pill launcher)";
            if (cmd.includes("launcher.sh clipboard")) return "Clipboard history (vicinae, or fuzzel)";
            if (cmd.includes("launcher.sh emoji")) return "Emoji picker (vicinae, or fuzzel)";
            if (cmd.includes("toggle launcher")) return "Open the app launcher (fuzzel if the shell isn't running)";
            const m = /^gtk-launch\s+(\S+)/.exec(cmd);
            if (m) return "Open " + appName(m[1]);
            if (cmd.includes("launch_first_available.sh")) {
                const apps = [], re = /'([^']+)'/g;
                let m2;
                while ((m2 = re.exec(cmd)) !== null)
                    apps.push(m2[1].split(" ")[0]);
                return "Open the first installed of: " + apps.join(", ");
            }
            if (/^playerctl/.test(cmd)) return "Media: " + cmd.replace("playerctl ", "");
            if (/^wpctl/.test(cmd)) return "Audio: " + cmd;
            return "Run: " + cmd;
        }
        case "global": {
            const n = String(a0 ?? "").replace("quickshell:", "");
            return shellNames[n] ?? "Shell shortcut: " + n;
        }
        case "window.close": return "Close the focused window";
        case "window.kill": return "Force-kill a window";
        case "window.fullscreen": return a0?.mode === "maximized" ? "Toggle maximize" : "Toggle fullscreen";
        case "window.fullscreen_state": return "Fake fullscreen (window thinks it's fullscreen)";
        case "window.float": return "Toggle floating";
        case "window.pin": return "Pin window on every workspace";
        case "window.center": return "Center the window";
        case "window.drag": return "Move window with the mouse";
        case "window.resize": return a0 ? "Resize window" : "Resize window with the mouse";
        case "window.move":
            if (a0?.direction) return "Move window " + dirName(a0.direction);
            if (a0?.workspace !== undefined) return "Send window to workspace " + a0.workspace + (a0.follow === false ? " (stay here)" : "");
            return "Move window";
        case "focus":
            if (a0?.direction) return "Focus the window " + dirName(a0.direction);
            if (a0?.workspace !== undefined) return "Go to workspace " + a0.workspace;
            return "Change focus";
        case "workspace.toggle_special": return "Show / hide the scratchpad";
        case "layout": return "Layout: " + a0;
        case "exit": return "Log out of Hyprland";
        case "submap": return "Enter submap " + a0;
        }
        return b.dsp + (a.length ? " " + JSON.stringify(a) : "");
    }
    function titleOf(b) {
        const d = (b.description ?? "").replace(/^[^:]+:\s*/, "");
        return d || explain(b);
    }
    function categoryOf(b) {
        const m = /^([^:]+):/.exec(b.description ?? "");
        if (m) return m[1];
        if (isCustom(b)) return "Custom";
        if ((b.dsp ?? "").startsWith("window") ) return "Window";
        if (b.dsp === "focus") return "Workspace";
        return "Other";
    }

    // --- Actions for the editor
    readonly property var presets: ({
        shell: [
            { label: "Launcher", lua: 'hl.dsp.global("quickshell:launcherToggle")' },
            { label: "Quick settings", lua: 'hl.dsp.global("quickshell:sidebarRightToggle")' },
            { label: "Calendar", lua: 'hl.dsp.global("quickshell:calendarToggle")' },
            { label: "Weather", lua: 'hl.dsp.global("quickshell:weatherToggle")' },
            { label: "Media", lua: 'hl.dsp.global("quickshell:mediaControlsToggle")' },
            { label: "Wi-Fi", lua: 'hl.dsp.global("quickshell:wifiToggle")' },
            { label: "Bluetooth", lua: 'hl.dsp.global("quickshell:bluetoothToggle")' },
            { label: "Wallpapers", lua: 'hl.dsp.global("quickshell:wallpaperSelectorToggle")' },
            { label: "Random wallpaper", lua: 'hl.dsp.global("quickshell:wallpaperSelectorRandom")' },
            { label: "Light / dark", lua: 'hl.dsp.global("quickshell:toggleLightDark")' },
            { label: "Power menu", lua: 'hl.dsp.global("quickshell:sessionToggle")' },
            { label: "Settings", lua: 'hl.dsp.global("quickshell:settingsToggle")' },
            { label: "Hide pill", lua: 'hl.dsp.global("quickshell:barToggle")' }
        ],
        window: [
            { label: "Close", lua: "hl.dsp.window.close()" },
            { label: "Fullscreen", lua: 'hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })' },
            { label: "Maximize", lua: 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })' },
            { label: "Float", lua: 'hl.dsp.window.float({ action = "toggle" })' },
            { label: "Pin", lua: "hl.dsp.window.pin()" },
            { label: "Center", lua: "hl.dsp.window.center()" },
            { label: "Force kill", lua: 'hl.dsp.exec_cmd("hyprctl kill")' },
            { label: "Scratchpad", lua: 'hl.dsp.workspace.toggle_special("special")' }
        ],
        media: [
            { label: "Play / pause", lua: 'hl.dsp.exec_cmd("playerctl play-pause")' },
            { label: "Next track", lua: 'hl.dsp.exec_cmd("playerctl next")' },
            { label: "Previous track", lua: 'hl.dsp.exec_cmd("playerctl previous")' },
            { label: "Volume up", lua: 'hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0")' },
            { label: "Volume down", lua: 'hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")' },
            { label: "Mute", lua: 'hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")' },
            { label: "Mic mute", lua: 'hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")' },
            { label: "Brightness up", lua: 'hl.dsp.exec_cmd("qs -c nothing ipc call brightness increment")' },
            { label: "Brightness down", lua: 'hl.dsp.exec_cmd("qs -c nothing ipc call brightness decrement")' }
        ],
        system: [
            { label: "Lock", lua: 'hl.dsp.exec_cmd("loginctl lock-session")' },
            { label: "Sleep", lua: 'hl.dsp.exec_cmd("systemctl suspend")' },
            { label: "Log out", lua: "hl.dsp.exit()" },
            { label: "Screenshot area", lua: 'hl.dsp.exec_cmd("hyprshot --freeze --clipboard-only --mode region --silent")' },
            { label: "Screenshot screen", lua: 'hl.dsp.exec_cmd("grim - | wl-copy")' },
            { label: "Colour picker", lua: 'hl.dsp.exec_cmd("hyprpicker -a")' },
            { label: "Clipboard history", lua: 'hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy")' },
            { label: "Emoji picker", lua: 'hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/fuzzel-emoji.sh copy")' }
        ]
    })
    function luaString(s) { return JSON.stringify(String(s)); }
    function actionLua(a) {
        switch (a.type) {
        case "app": return "hl.dsp.exec_cmd(" + luaString("gtk-launch " + a.value) + ")";
        case "command": return "hl.dsp.exec_cmd(" + luaString(a.value) + ")";
        case "goto": return "hl.dsp.focus({ workspace = " + parseInt(a.value) + " })";
        case "send": return "hl.dsp.window.move({ workspace = " + parseInt(a.value) + ", follow = false })";
        default: return a.lua ?? "";
        }
    }

    // --- Persist + apply
    function save(entry) {
        const list = custom.filter(c => c.uid !== entry.uid);
        list.push(entry);
        write(list);
    }
    function remove(uid) {
        write(custom.filter(c => c.uid !== uid));
    }
    function write(list) {
        custom = list;
        store.setText(JSON.stringify(list, null, 2) + "\n");
        let lua = "-- Generated by Nothing Settings (~/.config/quickshell/nothing/keybinds.json). Do not edit.\n";
        for (const c of list) {
            if (c.replaces)
                lua += "hl.unbind(" + luaString(c.replaces) + ")\n";
            if (c.combo && c.replaces && norm(c.combo) !== norm(c.replaces))
                lua += "hl.unbind(" + luaString(c.combo) + ")\n";
            if (c.action.type !== "off" && c.combo) {
                const opts = c.description ? ", { description = " + luaString(c.description) + " }" : "";
                lua += "hl.bind(" + luaString(c.combo) + ", " + actionLua(c.action) + opts + ")\n";
            }
        }
        luaFile.setText(lua);
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; hyprctl reload config-only"]);
    }

    // --- Key capture: an empty Hyprland submap so no bind fires meanwhile.
    function startCapture() {
        capturing = true;
        Hyprland.dispatch('hl.dsp.submap("nothing-capture")');
        captureTimeout.restart();
    }
    function stopCapture() {
        if (!capturing)
            return;
        capturing = false;
        captureTimeout.stop();
        Hyprland.dispatch('hl.dsp.submap("reset")');
    }
    Timer {
        id: captureTimeout
        interval: 10000
        onTriggered: root.stopCapture()
    }

    // Qt key event -> Hyprland key name
    function keyName(e) {
        const k = e.key;
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F24) return "F" + (k - Qt.Key_F1 + 1);
        // Shift+digit gives symbols; use the physical key instead
        if (e.nativeScanCode >= 10 && e.nativeScanCode <= 19) return "1234567890"[e.nativeScanCode - 10];
        const m = {};
        m[Qt.Key_Return] = "Return"; m[Qt.Key_Enter] = "KP_Enter"; m[Qt.Key_Space] = "Space"; m[Qt.Key_Tab] = "Tab";
        m[Qt.Key_Backtab] = "Tab"; m[Qt.Key_Backspace] = "BackSpace"; m[Qt.Key_Delete] = "Delete"; m[Qt.Key_Escape] = "Escape";
        m[Qt.Key_Left] = "Left"; m[Qt.Key_Right] = "Right"; m[Qt.Key_Up] = "Up"; m[Qt.Key_Down] = "Down";
        m[Qt.Key_Home] = "Home"; m[Qt.Key_End] = "End"; m[Qt.Key_PageUp] = "Page_Up"; m[Qt.Key_PageDown] = "Page_Down";
        m[Qt.Key_Insert] = "Insert"; m[Qt.Key_Print] = "Print"; m[Qt.Key_Comma] = "Comma"; m[Qt.Key_Period] = "Period";
        m[Qt.Key_Slash] = "Slash"; m[Qt.Key_Backslash] = "Backslash"; m[Qt.Key_Minus] = "Minus"; m[Qt.Key_Equal] = "Equal";
        m[Qt.Key_Semicolon] = "Semicolon"; m[Qt.Key_Apostrophe] = "Apostrophe"; m[Qt.Key_BracketLeft] = "BracketLeft";
        m[Qt.Key_BracketRight] = "BracketRight"; m[Qt.Key_QuoteLeft] = "Grave";
        m[Qt.Key_VolumeUp] = "XF86AudioRaiseVolume"; m[Qt.Key_VolumeDown] = "XF86AudioLowerVolume"; m[Qt.Key_VolumeMute] = "XF86AudioMute";
        m[Qt.Key_MediaTogglePlayPause] = "XF86AudioPlay"; m[Qt.Key_MediaPlay] = "XF86AudioPlay"; m[Qt.Key_MediaNext] = "XF86AudioNext";
        m[Qt.Key_MediaPrevious] = "XF86AudioPrev"; m[Qt.Key_MonBrightnessUp] = "XF86MonBrightnessUp"; m[Qt.Key_MonBrightnessDown] = "XF86MonBrightnessDown";
        return m[k] ?? "";
    }
    function comboFromEvent(e) {
        const mods = [];
        if (e.modifiers & Qt.MetaModifier) mods.push("SUPER");
        if (e.modifiers & Qt.ControlModifier) mods.push("CTRL");
        if (e.modifiers & Qt.AltModifier) mods.push("ALT");
        if (e.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
        const k = keyName(e);
        return k ? mods.concat([k]).join(" + ") : "";
    }
    function conflict(combo, ignoreId) {
        const id = norm(combo);
        return all.find(b => b.id === id && b.id !== ignoreId && b.submap === "") ?? null;
    }

    // Scriptable: ipc call binds add "SUPER + ALT + B" "firefox"   /   ipc call binds remove "SUPER + ALT + B"
    IpcHandler {
        target: "binds"
        function add(combo: string, command: string): void {
            const hit = root.conflict(combo, "");
            root.save({ uid: "ipc-" + root.norm(combo), replaces: hit ? hit.combo : "", combo: combo,
                action: { type: "command", value: command }, description: "Custom: " + command });
        }
        function remove(combo: string): void {
            const id = root.norm(combo);
            root.write(root.custom.filter(c => root.norm(c.combo) !== id));
        }
    }

    FileView {
        path: Theme.stateDir + "/binds.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.all = JSON.parse(text()); } catch (e) {}
        }
    }
    FileView {
        id: store
        path: Quickshell.shellPath("keybinds.json")
        onLoaded: {
            try { root.custom = JSON.parse(text()); } catch (e) {}
        }
    }
    FileView {
        id: luaFile
        path: Quickshell.env("HOME") + "/.config/hypr/hyprland/keybinds-custom.lua"
    }
}
