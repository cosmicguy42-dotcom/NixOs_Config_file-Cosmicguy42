pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shell options, stored in ~/.config/quickshell/nothing/config.json.
// Read with Config.get("pill.weather"), write with Config.set(...).
// The Settings window edits this; missing keys fall back to `defaults`.
Singleton {
    id: root

    readonly property var defaults: ({
        pill: {
            workspaces: true,
            weather: true,
            media: true,
            tray: true,
            batteryPercent: true,
            clock: "dots",      // dots | serif | mono
            clock24h: true,
            opacity: 0.72,      // glass opacity (0.3 - 1)
            border: true
        },
        look: {
            bloom: true,        // glow on dot-matrix elements
            bloomStrength: 0.9, // 0.2 - 1
            animatedIcons: true, // animated dot-matrix weather glyphs
            coverTheme: false,   // accent follows the playing track's cover art
            monoIcons: false,   // tint app icons monochrome (launcher)
            accentFills: false, // true: active controls use the accent instead of white
            radius: 20,         // the one corner radius (also Hyprland windows, launcher)
            brutal: false,      // brutalist: no rounded corners anywhere, square dots
            gap: 8,             // the one gap (window gaps + pill margin)
            cursor: "Bibata-Modern-Classic",
            cursorSize: 24
        },
        widgets: {
            enabled: true,
            show: { clock: true, weather: true, media: true, battery: true, system: true, calendar: true, note: false },
            // fractions of the screen (top-left corner)
            layout: {
                clock: { x: 0.045, y: 0.1 },
                weather: { x: 0.045, y: 0.39 },
                media: { x: 0.045, y: 0.67 },
                calendar: { x: 0.79, y: 0.1 },
                battery: { x: 0.79, y: 0.45 },
                system: { x: 0.79, y: 0.64 },
                note: { x: 0.6, y: 0.1 }
            }
        },
        weather: {
            location: "",       // empty = locate by IP
            units: "metric"     // metric | imperial
        },
        nightLight: { temperature: 4000 },
        notifications: { timeout: 5 },
        lock: {
            engine: "quickshell", // quickshell | hyprlock
            weather: true,
            media: true
        },
        idle: { lock: 5, screenOff: 10, suspend: 15 } // minutes, 0 = never
    })

    property var data: defaults
    property bool loaded: false

    // Convenience bindings used around the shell
    readonly property string weatherLocation: get("weather.location")
    readonly property bool imperial: get("weather.units") === "imperial"
    readonly property int nightTemp: get("nightLight.temperature")

    function get(path) {
        let v = root.data;
        for (const k of path.split(".")) {
            if (v === undefined || v === null)
                break;
            v = v[k];
        }
        if (v !== undefined)
            return v;
        let d = root.defaults;
        for (const k of path.split("."))
            d = d?.[k];
        return d;
    }

    function set(path, value) {
        const next = JSON.parse(JSON.stringify(root.data));
        const keys = path.split(".");
        let o = next;
        for (const k of keys.slice(0, -1)) {
            if (typeof o[k] !== "object" || o[k] === null)
                o[k] = {};
            o = o[k];
        }
        o[keys[keys.length - 1]] = value;
        root.data = next;
        file.setText(JSON.stringify(next, null, 2) + "\n");
    }

    function merge(base, over) {
        const out = JSON.parse(JSON.stringify(base));
        for (const k in over) {
            if (over[k] && typeof over[k] === "object" && !Array.isArray(over[k]) && typeof out[k] === "object")
                out[k] = merge(out[k], over[k]);
            else
                out[k] = over[k];
        }
        return out;
    }

    FileView {
        id: file
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = root.merge(root.defaults, JSON.parse(text()));
            } catch (e) {
                console.warn("nothing: bad config.json", e);
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
