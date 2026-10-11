import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

Page {
    id: page
    title: "About"

    property var info: ({})

    Process {
        running: true
        command: [Quickshell.shellPath("scripts/sysinfo.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.info = JSON.parse(text); } catch (e) {}
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 150
        radius: Theme.radius
        color: Theme.card
        Column {
            anchors.centerIn: parent
            spacing: 14
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "NOTHING"
                dot: 4
                gap: 1.8
                color: Theme.fg
            }
            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "A Quickshell shell for Hyprland · " + (page.info.host ?? "")
            }
        }
    }

    Section {
        title: "System"
        Repeater {
            model: [["OS", "os"], ["Kernel", "kernel"], ["Uptime", "uptime"], ["CPU", "cpu"], ["GPU", "gpu"],
                    ["Memory", "memory"], ["Disk (/)", "disk"], ["Hyprland", "hyprland"], ["Quickshell", "quickshell"],
                    ["User", "user"], ["Shell", "shell"]]
            OptRow {
                id: info
                required property var modelData
                label: modelData[0]
                Caption {
                    width: 380
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                    text: page.info[info.modelData[1]] ?? "…"
                    color: Theme.fg
                    font.pixelSize: 11
                }
            }
        }
    }

    Section {
        title: "Files"
        OptRow {
            label: "Shell config"
            sub: "~/.config/quickshell/nothing"
            OptButton { text: "Open"; icon: "folder_open"; onClicked: Qt.openUrlExternally("file://" + Quickshell.shellDir) }
        }
        OptRow {
            label: "Hyprland config"
            sub: "~/.config/hypr"
            OptButton { text: "Open"; icon: "folder_open"; onClicked: Qt.openUrlExternally("file://" + Quickshell.env("HOME") + "/.config/hypr") }
        }
        OptRow {
            label: "Welcome tour"
            sub: "The first-run setup: wallpaper, look, colour, weather, keys"
            OptButton { text: "Show again"; icon: "waving_hand"; onClicked: Quickshell.execDetached(["qs", "-c", "nothing", "ipc", "call", "onboarding", "open"]) }
        }
        OptRow {
            label: "Keybind cheat sheet"
            sub: "Super + /"
            OptButton { text: "Open"; icon: "keyboard"; onClicked: Quickshell.execDetached(["qs", "-c", "nothing", "ipc", "call", "cheatsheet", "toggle"]) }
        }
        OptRow {
            label: "Reload the shell"
            sub: "Restarts Quickshell (Ctrl + Super + R)"
            OptButton { text: "Reload"; icon: "refresh"; onClicked: Quickshell.execDetached(["sh", "-c", "killall qs quickshell; qs -c nothing &"]) }
        }
    }
}
