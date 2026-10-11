import QtQuick
import Quickshell.Networking
import qs.services
import qs.components

// Wi-Fi list. Scans while open. New secured networks ask for a password inline.
Column {
    id: root

    width: 380
    spacing: 10

    property bool embedded: false // inside Settings: no back arrow

    property var pending: null // network waiting for a password

    Component.onCompleted: Net.setScanning(true)
    Component.onDestruction: Net.setScanning(false)

    Row {
        width: parent.width
        CircleButton { visible: !root.embedded; size: 32; icon: "arrow_back"; anchors.verticalCenter: parent.verticalCenter; onClicked: Ui.open("control") }
        Overline { leftPadding: 10; width: parent.width - (root.embedded ? 0 : 32) - sw.width; anchors.verticalCenter: parent.verticalCenter; text: "Wi-Fi" + (Net.active ? " · " + Net.active.name : "") }
        Switch { id: sw; checked: Net.wifiOn; onToggled: on => Net.setWifi(on) }
    }

    Card {
        visible: Net.wifiOn
        width: parent.width
        height: list.height + 12

        Column {
            id: list
            y: 6
            width: parent.width

            Caption {
                visible: Net.networks.length === 0
                width: parent.width
                height: 44
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Scanning…"
            }

            Repeater {
                model: Net.networks.slice(0, 8)

                Column {
                    id: entry
                    required property var modelData
                    readonly property bool secured: modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Unknown
                    width: list.width

                    Item {
                        width: parent.width
                        height: 42
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            radius: Theme.radius
                            color: Theme.raised
                            opacity: row.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        Icon {
                            x: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: Net.strengthIcon(entry.modelData.signalStrength)
                            size: 18
                            color: entry.modelData.connected ? Theme.accent : Theme.fg
                        }
                        Label {
                            x: 46
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 46 - 110
                            text: entry.modelData.name
                            color: entry.modelData.connected ? Theme.accent : Theme.fg
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Caption {
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData.connected ? "Connected" : entry.modelData.stateChanging ? "…" : entry.modelData.known ? "Saved" : ""
                            }
                            Icon {
                                visible: entry.secured
                                anchors.verticalCenter: parent.verticalCenter
                                text: "lock"
                                size: 14
                                color: Theme.dim
                            }
                        }
                        MouseArea {
                            id: row
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const n = entry.modelData;
                                if (n.connected)
                                    n.disconnect();
                                else if (n.known || !entry.secured)
                                    Net.connect(n);
                                else
                                    root.pending = root.pending === n ? null : n;
                            }
                        }
                    }

                    // Inline password prompt
                    Item {
                        visible: root.pending === entry.modelData
                        width: parent.width
                        height: visible ? 52 : 0
                        Rectangle {
                            x: 12
                            width: parent.width - 24 - 48
                            height: 40
                            radius: Theme.r(height / 2)
                            color: Theme.raised
                            border.width: 1
                            border.color: Theme.accent
                            TextInput {
                                id: pw
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                passwordCharacter: "•"
                                font.family: Theme.mono
                                font.pixelSize: 13
                                color: Theme.fg
                                onVisibleChanged: if (visible) forceActiveFocus()
                                Keys.onReturnPressed: go.clicked()
                                Keys.onEscapePressed: root.pending = null
                                Caption {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: pw.text.length === 0
                                    text: "Password"
                                }
                            }
                        }
                        CircleButton {
                            id: go
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            y: 0
                            icon: "arrow_forward"
                            active: true
                            onClicked: {
                                if (pw.text.length === 0)
                                    return;
                                Net.connect(entry.modelData, pw.text);
                                pw.text = "";
                                root.pending = null;
                            }
                        }
                    }
                }
            }
        }
    }
}
