pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper / light-dark / scheme state. scripts/theme.sh owns state.json;
// this reads it back and shells out to change it.
Singleton {
    id: root

    readonly property string wallDir: (Config.get("wallpaper.dir") || Quickshell.env("NOTHING_WALLPAPERS") || "~/Pictures/Wallpapers").replace(/^~/, Quickshell.env("HOME"))
    property string wallpaper: ""
    property string mode: "dark"
    property string scheme: "scheme-tonal-spot"
    property real contrast: 0
    property int lead: 0              // which wallpaper colour is the accent
    property bool neutral: true       // neutral surfaces instead of tinted
    property string source: "wallpaper" // wallpaper | custom
    property var custom: ({ base: "#000000", surface: "#141414", accent: "#d71921" })
    property var sources: []          // candidate lead colours from the wallpaper

    readonly property var presets: [
        { name: "Nothing", base: "#000000", surface: "#141414", accent: "#d71921" },
        { name: "Graphite", base: "#0b0b0c", surface: "#1a1a1c", accent: "#e8e8e8" },
        { name: "Paper", base: "#f4f2ee", surface: "#e9e6e0", accent: "#d71921" },
        { name: "Moss", base: "#0c0f0c", surface: "#171c17", accent: "#a8c686" },
        { name: "Ink", base: "#0a0d14", surface: "#141a26", accent: "#8fb3ff" }
    ]

    readonly property var schemes: [
        { id: "scheme-tonal-spot", label: "Tonal" },
        { id: "scheme-vibrant", label: "Vibrant" },
        { id: "scheme-expressive", label: "Expressive" },
        { id: "scheme-content", label: "Content" },
        { id: "scheme-neutral", label: "Neutral" },
        { id: "scheme-monochrome", label: "Mono" }
    ]

    // Shape + cursor tokens also drive Hyprland and the launcher (scripts/look.sh).
    readonly property string lookKey: [Config.get("look.radius"), Config.get("look.gap"), Config.get("look.cursor"), Config.get("look.cursorSize"), Config.get("look.brutal")].join("|")
    onLookKeyChanged: if (Config.loaded) lookApply.restart()
    Connections {
        target: Config
        function onLoadedChanged() { if (Config.loaded) lookApply.restart(); } // cursor on startup
    }
    Timer {
        id: lookApply
        interval: 400
        onTriggered: Quickshell.execDetached([Quickshell.shellPath("scripts/look.sh")])
    }

    // Theme from cover art: while music plays the accent follows the album,
    // and a few seconds after it stops the normal palette comes back.
    property string restoreSource: "wallpaper"
    readonly property string coverHex: Config.get("look.coverTheme") && Player.playing && Player.hasArtColor
        ? Player.artAccent.toString() : ""
    onCoverHexChanged: coverHex ? coverOn.restart() : coverOff.restart()
    Timer {
        id: coverOn
        interval: 1200
        onTriggered: {
            if (!root.coverHex)
                return;
            coverOff.stop();
            if (root.source !== "cover")
                root.restoreSource = root.source;
            root.run(["cover", root.coverHex]);
        }
    }
    Timer {
        id: coverOff
        interval: 6000
        onTriggered: if (!root.coverHex && root.source === "cover") root.run(["source", root.restoreSource || "wallpaper"])
    }

    function run(args) {
        Quickshell.execDetached([Quickshell.shellPath("scripts/theme.sh"), ...args]);
    }
    function setWallpaper(path) {
        root.wallpaper = path; // start the crossfade before matugen finishes
        run(["wall", path]);
    }
    function randomWallpaper() { run(["random"]); }
    function toggleMode() { run(["mode", "toggle"]); }
    function setScheme(id) { run(["scheme", id]); }
    function setMode(m) { run(["mode", m]); }
    function setContrast(c) { run(["contrast", String(c)]); }
    function setLead(i) { run(["lead", String(i), "source", "wallpaper"]); }
    function setNeutral(on) { run(["neutral", on ? "on" : "off"]); }
    function setSource(s) { run(["source", s]); }
    function setCustom(base, surface, accent) { run(["custom", base, surface, accent]); }

    FileView {
        path: Theme.stateDir + "/state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.wallpaper = s.wallpaper ?? "";
                root.mode = s.mode ?? "dark";
                root.scheme = s.scheme ?? "scheme-tonal-spot";
                root.contrast = s.contrast ?? 0;
                root.lead = s.lead ?? 0;
                root.neutral = s.neutral ?? true;
                root.source = s.source ?? "wallpaper";
                root.custom = s.custom ?? root.custom;
            } catch (e) {}
        }
        // First run: generate everything from the first wallpaper found.
        onLoadFailed: root.run([])
    }
    FileView {
        path: Theme.stateDir + "/sources.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.sources = JSON.parse(text()); } catch (e) {}
        }
    }
}
