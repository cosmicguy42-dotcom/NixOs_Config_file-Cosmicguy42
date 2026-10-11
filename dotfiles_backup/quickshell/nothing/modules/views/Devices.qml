import QtQuick
import Quickshell.Bluetooth
import qs.services
import qs.components

// Bluetooth devices. Discovers while open; click to pair / connect / disconnect.
Column {
    id: root

    width: 380
    spacing: 10

    property bool embedded: false // inside Settings: no back arrow

    Component.onCompleted: Net.setDiscovering(true)
    Component.onDestruction: Net.setDiscovering(false)

    Row {
        width: parent.width
        CircleButton { visible: !root.embedded; size: 32; icon: "arrow_back"; anchors.verticalCenter: parent.verticalCenter; onClicked: Ui.open("control") }
        Overline { leftPadding: 10; width: parent.width - (root.embedded ? 0 : 32) - sw.width; anchors.verticalCenter: parent.verticalCenter; text: "Bluetooth" + (Net.adapter?.discovering ? " · scanning" : "") }
        Switch { id: sw; checked: Net.btOn; onToggled: on => { Net.setBt(on); if (on) Net.setDiscovering(true); } }
    }

    Card {
        visible: Net.btOn
        width: parent.width
        height: list.height + 12

        Column {
            id: list
            y: 6
            width: parent.width

            Caption {
                visible: Net.devices.length === 0
                width: parent.width
                height: 44
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Looking for devices…"
            }

            Repeater {
                model: Net.devices.slice(0, 8)

                Item {
                    id: entry
                    required property var modelData
                    width: list.width
                    height: 42

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        radius: Theme.radius
                        color: Theme.raised
                        opacity: mouse.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Icon {
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: Net.deviceIcon(entry.modelData.icon)
                        size: 18
                        color: entry.modelData.connected ? Theme.accent : Theme.fg
                    }
                    Label {
                        x: 46
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 46 - 120
                        text: entry.modelData.name || entry.modelData.address
                        color: entry.modelData.connected ? Theme.accent : Theme.fg
                    }
                    Caption {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            const d = entry.modelData;
                            if (d.pairing) return "Pairing…";
                            if (d.state === BluetoothDeviceState.Connecting) return "Connecting…";
                            if (d.connected) return d.batteryAvailable ? Math.round(d.battery * 100) + "%" : "Connected";
                            return d.paired ? "Paired" : "";
                        }
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const d = entry.modelData;
                            if (!d.paired) {
                                d.trusted = true;
                                d.pair();
                            } else {
                                d.connected = !d.connected;
                            }
                        }
                    }
                }
            }
        }
    }
}
