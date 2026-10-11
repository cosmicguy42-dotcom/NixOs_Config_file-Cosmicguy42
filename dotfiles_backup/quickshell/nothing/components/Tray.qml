import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import qs.services

// System tray: collapsed to a dot grip; click it to slide the icons out.
// Icons are greyscale until hovered. Left click activates, right click
// opens the item's menu inside the island.
Item {
    id: root

    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)
    readonly property bool open: Ui.trayOpen

    // pad the right so the grip's hit area stays inside the tray (the status
    // area's click target sits right next to it, on top)
    implicitWidth: row.width + 6
    implicitHeight: 20

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Item {
            id: strip
            anchors.verticalCenter: parent.verticalCenter
            height: 16
            width: root.open ? icons.width : 0
            clip: true
            Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }

            Row {
                id: icons
                spacing: 10
                anchors.right: parent.right

                Repeater {
                    model: root.items

                    Item {
                        id: tray
                        required property var modelData
                        width: 16
                        height: 16

                        Image {
                            id: img
                            anchors.fill: parent
                            source: tray.modelData.icon
                            sourceSize: Qt.size(48, 48)
                            visible: false
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: img
                            saturation: mouse.containsMouse ? 0 : -1
                            opacity: mouse.containsMouse ? 1 : 0.85
                            Behavior on saturation { NumberAnimation { duration: 200 } }
                        }
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: e => {
                                const it = tray.modelData;
                                if (e.button === Qt.MiddleButton)
                                    it.secondaryActivate();
                                else if (e.button === Qt.RightButton || it.onlyMenu)
                                    it.hasMenu ? Ui.openTray(it) : it.secondaryActivate();
                                else
                                    it.activate();
                            }
                            onWheel: e => tray.modelData.scroll(e.angleDelta.y, false)
                        }
                    }
                }
            }
        }

        // Grip: a 2x2 dot cluster; turns into a single accent dot when open.
        Grid {
            anchors.verticalCenter: parent.verticalCenter
            columns: 2
            spacing: 2
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 3
                    height: 3
                    radius: Theme.r(1.5)
                    color: root.open && index === 0 ? Theme.accent : Theme.fg
                    opacity: root.open && index !== 0 ? 0.25 : 0.8
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }

    MouseArea {
        id: grip
        x: row.width - 14
        width: 20
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        cursorShape: Qt.PointingHandCursor
        onClicked: Ui.trayOpen = !Ui.trayOpen
    }
}
