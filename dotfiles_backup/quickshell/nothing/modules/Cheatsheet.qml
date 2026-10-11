import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// Keybind cheat sheet (Super + /). Reads the live binds recorded by
// hypr/hyprland/lib/bindlog.lua, so edits made in Settings show up here.
Scope {
    id: root

    property bool open: false

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.open = !root.open; }
    }
    GlobalShortcut {
        name: "cheatsheetToggle"
        onPressed: root.open = !root.open
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nothing:cheatsheet"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            property string query: ""
            readonly property var order: ["App", "Shell", "Window", "Workspace", "Media", "Utilities", "Screen", "Session", "Custom"]
            readonly property var groups: {
                const g = {};
                const q = query.toLowerCase();
                for (const b of Binds.all) {
                    if (b.submap !== "" || b.mouse || !b.description || /code:|mouse/.test(b.combo))
                        continue;
                    if (q && !(Binds.titleOf(b) + " " + b.combo).toLowerCase().includes(q))
                        continue;
                    const c = Binds.categoryOf(b);
                    (g[c] = g[c] ?? []).push(b);
                }
                return Object.keys(g)
                    .sort((a, b) => ((order.indexOf(a) + 1) || 99) - ((order.indexOf(b) + 1) || 99))
                    .map(k => ({ name: k, binds: g[k].sort((x, y) => Binds.titleOf(x).localeCompare(Binds.titleOf(y))) }));
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.bg, 0.9)
                MouseArea { anchors.fill: parent; onClicked: root.open = false }
            }

            Item {
                anchors.fill: parent
                anchors.margins: 64
                anchors.topMargin: 56

                Row {
                    id: head
                    width: parent.width
                    spacing: 24
                    Heading { id: title; text: "Keys"; font.pixelSize: 64 }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 360
                        height: 44
                        radius: Theme.r(height / 2)
                        color: Theme.card
                        Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; text: "search"; size: 18; color: Theme.dim }
                        TextInput {
                            id: search
                            x: 44
                            width: parent.width - 60
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.mono
                            font.pixelSize: 13
                            color: Theme.fg
                            focus: true
                            Component.onCompleted: forceActiveFocus()
                            onTextChanged: win.query = text
                            Keys.onEscapePressed: root.open = false
                            Caption { anchors.verticalCenter: parent.verticalCenter; visible: search.text === ""; text: "Type to filter"; font.pixelSize: 12 }
                        }
                    }
                    Caption { anchors.verticalCenter: parent.verticalCenter; text: "Esc closes · edit in Settings › Keybinds" }
                }

                Flickable {
                    anchors.top: head.bottom
                    anchors.topMargin: 32
                    anchors.bottom: parent.bottom
                    width: parent.width
                    contentHeight: flow.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Flow {
                        id: flow
                        width: parent.width
                        spacing: 28

                        Repeater {
                            model: win.groups
                            Column {
                                id: grp
                                required property var modelData
                                width: (flow.width - 28 * 2) / 3
                                spacing: 6
                                Overline { text: grp.modelData.name; bottomPadding: 4 }
                                Repeater {
                                    model: grp.modelData.binds
                                    Item {
                                        id: row
                                        required property var modelData
                                        width: grp.width
                                        height: 30
                                        Label {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - keys.width - 12
                                            text: Binds.titleOf(row.modelData)
                                            font.pixelSize: 12
                                        }
                                        Row {
                                            id: keys
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3
                                            Repeater {
                                                model: Binds.keysOf(row.modelData.combo)
                                                Rectangle {
                                                    required property string modelData
                                                    width: kt.implicitWidth + 12
                                                    height: 22
                                                    radius: Theme.r(6)
                                                    color: Theme.raised
                                                    border.width: 1
                                                    border.color: Theme.faint
                                                    Caption { id: kt; anchors.centerIn: parent; text: parent.modelData; color: Theme.fg; font.pixelSize: 10 }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
