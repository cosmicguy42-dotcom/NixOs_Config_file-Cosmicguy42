import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services
import qs.components

// Big dot-matrix time with a serif date, straight on the wallpaper.
Column {
    id: root
    spacing: 14

    // Sits straight on the wallpaper (no glass), so always light ink with a
    // soft shadow, whatever the light/dark mode.
    readonly property color ink: "#f4f4f4"
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.35
        shadowBlur: 0.6
        shadowVerticalOffset: 2
        autoPaddingEnabled: true
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - new Date(Date.UTC(t.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7);
    }

    SystemClock {
        id: time
        precision: SystemClock.Minutes
    }
    DotText {
        text: Qt.formatDateTime(time.date, Config.get("pill.clock24h") ? "hh:mm" : "h:mm")
        dot: 9
        gap: 3.4
        offOpacity: 0.08
        color: root.ink
    }
    Heading {
        text: Qt.formatDateTime(time.date, "dddd, d MMMM")
        font.pixelSize: 46
        color: root.ink
    }
    Caption {
        text: "Week " + root.isoWeek(time.date) + " · " + (Forecast.location || Quickshell.env("USER"))
        font.pixelSize: 12
        color: root.ink
        opacity: 0.8
    }
}
