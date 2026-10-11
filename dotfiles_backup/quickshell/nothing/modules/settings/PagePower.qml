import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.services
import qs.components

Page {
    id: page
    title: "Power & lock"

    readonly property var bat: UPower.displayDevice

    function fmtTime(s) {
        if (!s || s <= 0) return "estimating";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return h > 0 ? h + " h " + m + " min" : m + " min";
    }
    function idle(path, v) {
        Config.set(path, Math.round(v));
        idleApply.restart();
    }
    Timer {
        id: idleApply
        interval: 300 // let config.json land first
        onTriggered: Quickshell.execDetached([Quickshell.shellPath("scripts/idle.sh")])
    }

    Section {
        visible: page.bat?.isLaptopBattery ?? false
        title: "Battery"
        OptRow {
            label: Math.round((page.bat?.percentage ?? 0) * 100) + "%"
            sub: page.bat?.state === UPowerDeviceState.Charging ? "Charging · full in " + page.fmtTime(page.bat.timeToFull)
                : page.bat?.state === UPowerDeviceState.FullyCharged ? "Fully charged"
                : "On battery · " + page.fmtTime(page.bat?.timeToEmpty) + ((page.bat?.timeToEmpty ?? 0) > 0 ? " left" : "")
            Caption { visible: (page.bat?.changeRate ?? 0) > 0; text: page.bat.changeRate.toFixed(1) + " W"; color: Theme.fg }
        }
    }

    Section {
        title: "Lock screen"
        OptChoice {
            label: "Lock screen"
            sub: "Nothing is the shell's own lock; hyprlock is the themed fallback"
            options: [{ label: "Nothing", value: "quickshell" }, { label: "hyprlock", value: "hyprlock" }]
            current: Config.get("lock.engine")
            onPicked: v => Config.set("lock.engine", v)
        }
        CSwitch { label: "Weather card"; path: "lock.weather" }
        CSwitch { label: "Media card"; path: "lock.media" }
        OptRow {
            label: "Try it"
            Row {
                spacing: 8
                OptButton { text: "Preview"; icon: "visibility"; onClicked: Quickshell.execDetached(["qs", "-c", "nothing", "ipc", "call", "lock", "preview"]) }
                OptButton { text: "Lock now"; icon: "lock"; accent: true; onClicked: Quickshell.execDetached(["loginctl", "lock-session"]) }
            }
        }
    }

    Section {
        title: "When idle"
        OptSlider { label: "Lock after"; sub: "0 = never"; from: 0; to: 60; suffix: " min"; value: Config.get("idle.lock"); onCommitted: v => page.idle("idle.lock", v) }
        OptSlider { label: "Screen off after"; from: 0; to: 60; suffix: " min"; value: Config.get("idle.screenOff"); onCommitted: v => page.idle("idle.screenOff", v) }
        OptSlider { label: "Suspend after"; from: 0; to: 120; suffix: " min"; value: Config.get("idle.suspend"); onCommitted: v => page.idle("idle.suspend", v) }
        OptSwitch { label: "Caffeine"; sub: "Stay awake until turned off"; checked: Toggles.caffeine; onToggled: on => Toggles.caffeine = on }
    }

    Section {
        title: "Session"
        OptRow {
            label: "Power"
            Row {
                spacing: 8
                OptButton { text: "Sleep"; icon: "bedtime"; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
                OptButton { text: "Log out"; icon: "logout"; onClicked: Ui.open("power") }
                OptButton { text: "Restart"; icon: "restart_alt"; onClicked: Ui.open("power") }
                OptButton { text: "Shut down"; icon: "power_settings_new"; onClicked: Ui.open("power") }
            }
        }
    }
}
