import QtQuick
import qs.services
import qs.components

Page {
    title: "Pill"
    subtitle: "What the bar shows while it's resting."

    Section {
        title: "Modules"
        CSwitch { label: "Workspaces"; sub: "Dots for each open workspace"; path: "pill.workspaces" }
        CSwitch { label: "Weather"; sub: "Glyph and temperature next to the clock"; path: "pill.weather" }
        CSwitch { label: "Now playing"; sub: "Title of the active media player"; path: "pill.media" }
        CSwitch { label: "System tray"; path: "pill.tray" }
        CSwitch { label: "Battery percentage"; path: "pill.batteryPercent" }
    }

    Section {
        title: "Clock"
        CChoice {
            label: "Style"
            options: [{ label: "Dot matrix", value: "dots" }, { label: "Serif", value: "serif" }, { label: "Mono", value: "mono" }]
            path: "pill.clock"
        }
        CSwitch { label: "24-hour time"; path: "pill.clock24h" }
    }

    Section {
        title: "Behaviour"
        OptSwitch {
            label: "Show the pill"
            sub: "Super + J toggles it too"
            checked: Ui.barVisible
            onToggled: on => Ui.barVisible = on
        }
        CSlider {
            label: "Notification popups"
            sub: "How long a new notification stays in the pill"
            path: "notifications.timeout"
            from: 2
            to: 15
            step: 1
            suffix: " s"
        }
    }
}
