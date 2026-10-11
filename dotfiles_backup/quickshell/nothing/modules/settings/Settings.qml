import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.components

// "Nothing Settings" window: `qs -c nothing ipc call settings open [page]`,
// Super+I, or the gear in the pill's quick settings.
Scope {
    id: root

    property bool open: false
    property string page: "appearance"

    readonly property var pages: [
        { id: "appearance", label: "Appearance", icon: "palette" },
        { id: "pill", label: "Pill", icon: "capture" },
        { id: "widgets", label: "Widgets", icon: "widgets" },
        { id: "wallhaven", label: "Wallhaven", icon: "travel_explore" },
        { id: "windows", label: "Windows", icon: "select_window" },
        { id: "input", label: "Input", icon: "keyboard" },
        { id: "display", label: "Display", icon: "desktop_windows" },
        { id: "sound", label: "Sound", icon: "volume_up" },
        { id: "network", label: "Network", icon: "wifi" },
        { id: "power", label: "Power & lock", icon: "lock" },
        { id: "weather", label: "Weather", icon: "partly_cloudy_day" },
        { id: "notifications", label: "Notifications", icon: "notifications" },
        { id: "keybinds", label: "Keybinds", icon: "keyboard_command_key" },
        { id: "about", label: "About", icon: "info" }
    ]

    function show(p) {
        if (p && pages.some(x => x.id === p))
            page = p;
        open = true;
        Ui.close();
    }

    IpcHandler {
        target: "settings"
        function open(page: string): void { root.show(page); }
        function toggle(): void { root.open ? root.open = false : root.show(""); }
        function close(): void { root.open = false; }
        // Scriptable: ipc call settings set decoration:rounding 12  (value is JSON)
        function set(key: string, value: string): void {
            let v = value;
            try { v = JSON.parse(value); } catch (e) {}
            HyprConf.set(key, v);
        }
        function reset(key: string): void { HyprConf.reset(key); }
    }
    GlobalShortcut {
        name: "settingsToggle"
        onPressed: root.open ? root.open = false : root.show("")
    }
    Connections {
        target: Ui
        function onSettingsRequestChanged() {
            if (Ui.settingsRequest === "__close") {
                root.open = false;
                Ui.settingsRequest = "";
            } else if (Ui.settingsRequest !== "") {
                root.show(Ui.settingsRequest);
                Ui.settingsRequest = "";
            }
        }
    }

    LazyLoader {
        active: root.open

        FloatingWindow {
            id: win
            title: "Nothing Settings"
            // 1000x680 logical px, shrunk to fit small or heavily scaled screens
            readonly property var scr: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            implicitWidth: Math.min(1000, Math.round((scr?.width ?? 1920) * 0.9))
            implicitHeight: Math.min(680, Math.round((scr?.height ?? 1080) * 0.85))
            minimumSize: Qt.size(720, 480)
            color: Theme.glass
            onClosed: root.open = false
            Component.onCompleted: HyprConf.reload()

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.open = false

                // Sidebar
                Rectangle {
                    id: side
                    width: 240
                    height: parent.height
                    color: Qt.alpha(Theme.bg, 0.5)

                    Column {
                        x: 18
                        y: 28
                        width: parent.width - 36
                        spacing: 2

                        Row {
                            x: 10
                            spacing: 10
                            bottomPadding: 16
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 10
                                height: 10
                                radius: Theme.r(5)
                                color: Theme.accent
                            }
                            Heading {
                                text: "Settings"
                                font.pixelSize: 32
                            }
                        }

                        Repeater {
                            model: root.pages
                            Rectangle {
                                id: item
                                required property var modelData
                                readonly property bool on: root.page === modelData.id
                                width: parent.width
                                height: 36
                                radius: Theme.r(height / 2)
                                color: on ? Theme.fg : (m.containsMouse ? Theme.card : "transparent")
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Row {
                                    x: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12
                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: item.modelData.icon
                                        size: 18
                                        color: item.on ? Theme.bg : Theme.fg
                                    }
                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: item.modelData.label
                                        color: item.on ? Theme.bg : Theme.fg
                                    }
                                }
                                MouseArea {
                                    id: m
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.page = item.modelData.id
                                }
                            }
                        }
                    }
                }

                // Page
                Loader {
                    id: loader
                    anchors.left: side.right
                    anchors.right: parent.right
                    height: parent.height
                    source: "Page" + root.page.charAt(0).toUpperCase() + root.page.slice(1) + ".qml"
                    opacity: status === Loader.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }
            }
        }
    }
}
