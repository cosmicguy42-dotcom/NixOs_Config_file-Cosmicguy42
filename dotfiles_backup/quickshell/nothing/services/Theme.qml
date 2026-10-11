pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper-derived palette (matugen -> ~/.local/state/nothing/colors.json)
// plus the handful of design tokens everything else uses.
Singleton {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nothing"
    property var c: ({})
    readonly property bool dark: c.mode !== "light"

    // Nothing-style roles: near-black/near-white surfaces, one accent.
    // Plain properties animated by `fade` (Behaviors crash inside singletons).
    readonly property var roles: ({
        bg: "surface_container_lowest",
        raised: "surface_container_high",
        fg: "on_surface",
        dim: "on_surface_variant",
        faint: "outline_variant",
        accent: "primary",
        accentFg: "on_primary",
        error: "error"
    })
    property color bg: "#0b0b0b"
    property color raised: "#1f1f1f"
    property color fg: "#f2f2f2"
    property color dim: "#9a9a9a"
    property color faint: "#3a3a3a"
    property color accent: "#d71921"
    property color accentFg: "#ffffff"
    property color error: "#ff5449"

    ParallelAnimation {
        id: fade
        ColorAnimation { target: root; property: "bg"; to: root.c[root.roles.bg] ?? "#0b0b0b"; duration: 700 }
        ColorAnimation { target: root; property: "raised"; to: root.c[root.roles.raised] ?? "#1f1f1f"; duration: 700 }
        ColorAnimation { target: root; property: "fg"; to: root.c[root.roles.fg] ?? "#f2f2f2"; duration: 700 }
        ColorAnimation { target: root; property: "dim"; to: root.c[root.roles.dim] ?? "#9a9a9a"; duration: 700 }
        ColorAnimation { target: root; property: "faint"; to: root.c[root.roles.faint] ?? "#3a3a3a"; duration: 700 }
        ColorAnimation { target: root; property: "accent"; to: root.c[root.roles.accent] ?? "#d71921"; duration: 700 }
        ColorAnimation { target: root; property: "accentFg"; to: root.c[root.roles.accentFg] ?? "#ffffff"; duration: 700 }
        ColorAnimation { target: root; property: "error"; to: root.c[root.roles.error] ?? "#ff5449"; duration: 700 }
    }

    // "On" state for controls. Nothing-style: solid fg (white on dark), with
    // the accent kept for small signals. Settings > Appearance can switch
    // controls to accent fills instead.
    readonly property bool accentFills: Config.get("look.accentFills") === true
    readonly property color active: accentFills ? accent : fg
    readonly property color activeFg: accentFills ? accentFg : bg

    // Translucent surfaces; Hyprland blurs what's behind them (rules.lua).
    readonly property color glass: Qt.alpha(bg, Config.get("pill.opacity"))
    readonly property color card: Qt.alpha(raised, dark ? 0.55 : 0.6)

    // Nothing OS type system: serif for hero numbers + headings,
    // mono for everything else, dot-matrix (DotText) for the clock.
    readonly property string serif: "Instrument Serif"
    readonly property string mono: "Space Mono"
    readonly property string icons: "Material Symbols Rounded"

    readonly property int barHeight: 36
    // Shape: ONE corner radius for every surface (windows, island, cards,
    // launcher, widgets, lock screen) and ONE gap (window gaps, pill margin).
    // Pill-shaped controls are capsules. Both live in Settings > Appearance.
    readonly property bool brutal: Config.get("look.brutal") === true
    readonly property int radius: brutal ? 0 : Config.get("look.radius")
    // Every radius in the shell goes through r(): brutalist mode squares it all,
    // capsules and dot-matrix dots included.
    function r(x) { return brutal ? 0 : x; }
    readonly property int margin: Config.get("look.gap")
    readonly property int pad: 14

    // One motion curve for the whole shell: quick, with a soft settle.
    readonly property int dur: 480
    readonly property int easing: Easing.OutQuint

    FileView {
        path: root.stateDir + "/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.c = JSON.parse(text());
                fade.restart();
            } catch (e) {
                console.warn("nothing: bad colors.json", e);
            }
        }
    }
}
