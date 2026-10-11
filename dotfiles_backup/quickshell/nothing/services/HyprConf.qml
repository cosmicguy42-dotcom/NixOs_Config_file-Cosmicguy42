pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hyprland options for the Settings window.
//  - reads live values with `hyprctl getoption` (scripts/hyprget.sh)
//  - applies changes instantly with `hyprctl eval`
//  - persists only what you changed to ~/.config/quickshell/nothing/hyprland.json
//    and regenerates ~/.config/hypr/hyprland/settings.lua (loaded last).
Singleton {
    id: root

    // Every option the Settings pages expose.
    readonly property var keys: [
        "general:layout", "general:gaps_in", "general:gaps_out", "general:border_size", "general:resize_on_border",
        "general:snap:enabled", "general:allow_tearing",
        "decoration:rounding", "decoration:rounding_power", "decoration:active_opacity", "decoration:inactive_opacity",
        "decoration:dim_inactive", "decoration:dim_strength",
        "decoration:blur:enabled", "decoration:blur:size", "decoration:blur:passes", "decoration:blur:vibrancy",
        "decoration:blur:noise", "decoration:blur:xray", "decoration:blur:popups",
        "decoration:shadow:enabled", "decoration:shadow:range", "decoration:shadow:render_power",
        "animations:enabled", "render:cm_enabled", "render:cm_auto_hdr", "render:send_content_type", "dwindle:preserve_split", "dwindle:smart_split", "master:new_status",
        "input:kb_layout", "input:kb_variant", "input:kb_options", "input:repeat_rate", "input:repeat_delay",
        "input:numlock_by_default", "input:sensitivity", "input:accel_profile", "input:natural_scroll",
        "input:follow_mouse", "input:scroll_factor", "input:left_handed",
        "input:touchpad:natural_scroll", "input:touchpad:tap-to-click", "input:touchpad:disable_while_typing",
        "input:touchpad:clickfinger_behavior", "input:touchpad:drag_lock", "input:touchpad:scroll_factor",
        "input:touchpad:middle_button_emulation",
        "gestures:workspace_swipe_invert", "gestures:workspace_swipe_distance", "gestures:workspace_swipe_create_new",
        "gestures:workspace_swipe_cancel_ratio",
        "cursor:inactive_timeout", "cursor:hide_on_key_press", "cursor:no_warps",
        "misc:vrr", "misc:focus_on_activate", "misc:enable_swallow", "misc:middle_click_paste",
        "misc:mouse_move_enables_dpms", "misc:key_press_enables_dpms", "binds:workspace_back_and_forth",
        "xwayland:force_zero_scaling"
    ]

    property var values: ({})
    property var overrides: ({})
    property var monitorOverrides: ({})
    property var monitors: []
    property bool ready: false

    function isSet(key) { return overrides[key] !== undefined; }

    function reload() {
        reader.running = true;
        monReader.running = true;
    }

    function set(key, value) {
        const v = Object.assign({}, values);
        v[key] = value;
        values = v;
        const o = Object.assign({}, overrides);
        o[key] = value;
        overrides = o;
        const one = {};
        one[key] = value;
        eval_(configLua(one));
        persist();
    }
    function reset(key) {
        const o = Object.assign({}, overrides);
        delete o[key];
        overrides = o;
        persist();
        // Re-run the whole config so the default from general.lua comes back.
        Quickshell.execDetached(["sh", "-c", "sleep 0.2; hyprctl reload config-only"]);
        reloadLater.restart();
    }
    function resetAll() {
        overrides = {};
        monitorOverrides = {};
        persist();
        Quickshell.execDetached(["sh", "-c", "sleep 0.2; hyprctl reload"]);
        reloadLater.restart();
    }

    // --- Monitors: applied live, then reverted unless confirmed.
    // A monitor's settings are one object with every field we manage, so a
    // change to one (say HDR) never drops the others:
    //   mode "WxH@Hz" | scale (number or "auto") | position | transform 0-7
    //   cm "srgb"|"wide"|"hdr"|"hdredid"|"auto" | bitdepth 8|10
    //   sdrbrightness | sdrsaturation (HDR only) | vrr 0|1|2 | icc path
    property var pendingMonitor: null // { name, previous, next }
    function monitorState(name) {
        const mon = monitors.find(m => m.name === name);
        if (!mon)
            return null;
        const live = {
            mode: mon.width + "x" + mon.height + "@" + mon.refreshRate.toFixed(2),
            scale: mon.scale,
            position: mon.x + "x" + mon.y,
            transform: mon.transform ?? 0,
            cm: mon.colorManagementPreset ?? "srgb",
            bitdepth: String(mon.currentFormat ?? "").includes("2101010") ? 10 : 8,
            sdrbrightness: mon.sdrBrightness ?? 1,
            sdrsaturation: mon.sdrSaturation ?? 1,
            // vrr: only once set per monitor (otherwise the global misc:vrr applies)
            icc: ""
        };
        return Object.assign(live, monitorOverrides[name] ?? {});
    }
    function setMonitor(name, patch) {
        const cur = monitorState(name);
        if (!cur)
            return;
        const next = Object.assign({}, cur, patch);
        pendingMonitor = { name: name, previous: cur, next: next };
        eval_(monitorLua(name, next));
        revertTimer.restart();
        monReaderLater.restart();
    }
    function keepMonitor() {
        if (!pendingMonitor)
            return;
        const m = Object.assign({}, monitorOverrides);
        m[pendingMonitor.name] = pendingMonitor.next;
        monitorOverrides = m;
        pendingMonitor = null;
        revertTimer.stop();
        persist();
    }
    function revertMonitor() {
        if (!pendingMonitor)
            return;
        eval_(monitorLua(pendingMonitor.name, pendingMonitor.previous));
        pendingMonitor = null;
        revertTimer.stop();
        monReaderLater.restart();
    }
    function resetMonitor(name) {
        const m = Object.assign({}, monitorOverrides);
        delete m[name];
        monitorOverrides = m;
        persist();
        Quickshell.execDetached(["sh", "-c", "sleep 0.2; hyprctl reload"]);
        reloadLater.restart();
    }
    readonly property int revertSeconds: 15
    Timer {
        id: revertTimer
        interval: root.revertSeconds * 1000
        onTriggered: root.revertMonitor()
    }

    // --- Lua generation
    function luaValue(v) {
        if (typeof v === "boolean") return v ? "true" : "false";
        if (typeof v === "number") return String(v);
        return JSON.stringify(String(v));
    }
    function configLua(flat) {
        const tree = {};
        for (const key in flat) {
            const parts = key.replace(/-/g, "_").split(":"); // Lua spells tap-to-click as tap_to_click
            let o = tree;
            for (const p of parts.slice(0, -1))
                o = o[p] = o[p] ?? {};
            o[parts[parts.length - 1]] = flat[key];
        }
        const render = (o, ind) => Object.keys(o).map(k => {
            const name = /^[A-Za-z_][A-Za-z0-9_]*$/.test(k) ? k : "[" + JSON.stringify(k) + "]";
            return typeof o[k] === "object"
                ? ind + name + " = {\n" + render(o[k], ind + "    ") + "\n" + ind + "},"
                : ind + name + " = " + luaValue(o[k]) + ",";
        }).join("\n");
        return "hl.config({\n" + render(tree, "    ") + "\n})";
    }
    function monitorLua(name, m) {
        const f = ["output = " + JSON.stringify(name), "mode = " + JSON.stringify(m.mode),
            "position = " + JSON.stringify(m.position), "scale = " + luaValue(m.scale),
            "transform = " + (m.transform ?? 0), "cm = " + JSON.stringify(m.cm ?? "srgb"),
            "bitdepth = " + (m.bitdepth ?? 8)];
        if (m.vrr !== undefined)
            f.push("vrr = " + m.vrr);
        if (String(m.cm).startsWith("hdr")) {
            f.push("sdrbrightness = " + (m.sdrbrightness ?? 1));
            f.push("sdrsaturation = " + (m.sdrsaturation ?? 1));
        }
        if (m.icc)
            f.push("icc = " + JSON.stringify(m.icc));
        if (m.supports_hdr)
            f.push("supports_hdr = 1", "supports_wide_color = 1");
        return "hl.monitor({ " + f.join(", ") + " })";
    }
    function eval_(lua) {
        Quickshell.execDetached(["hyprctl", "eval", lua]);
    }

    function persist() {
        store.setText(JSON.stringify({ options: overrides, monitors: monitorOverrides }, null, 2) + "\n");
        let lua = "-- Generated by Nothing Settings (~/.config/quickshell/nothing/hyprland.json).\n"
            + "-- Loaded after everything else. Delete this file to drop all overrides.\n";
        if (Object.keys(overrides).length)
            lua += configLua(overrides) + "\n";
        for (const name in monitorOverrides)
            lua += monitorLua(name, monitorOverrides[name]) + "\n";
        luaFile.setText(lua);
    }

    FileView {
        id: store
        path: Quickshell.shellPath("hyprland.json")
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.overrides = j.options ?? {};
                root.monitorOverrides = j.monitors ?? {};
            } catch (e) {}
        }
    }
    FileView {
        id: luaFile
        path: Quickshell.env("HOME") + "/.config/hypr/hyprland/settings.lua"
    }

    Process {
        id: reader
        command: [Quickshell.shellPath("scripts/hyprget.sh")].concat(root.keys)
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.values = JSON.parse(text);
                    root.ready = true;
                } catch (e) {}
            }
        }
    }
    Process {
        id: monReader
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    Timer {
        id: reloadLater
        interval: 900
        onTriggered: root.reload()
    }
    Timer {
        id: monReaderLater
        interval: 700
        onTriggered: monReader.running = true
    }
}
