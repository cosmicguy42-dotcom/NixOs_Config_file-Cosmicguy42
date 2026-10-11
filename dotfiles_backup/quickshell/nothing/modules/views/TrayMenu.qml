import QtQuick
import Quickshell
import qs.services
import qs.components

// A tray item's menu, rendered in the island. Submenus push; back pops.
Column {
    id: root

    width: 260
    spacing: 6

    property var stack: [Ui.trayItem?.menu]
    readonly property var current: stack[stack.length - 1]

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    Row {
        width: parent.width
        spacing: 10
        CircleButton {
            visible: root.stack.length > 1
            anchors.verticalCenter: parent.verticalCenter
            size: 30
            icon: "arrow_back"
            onClicked: root.stack = root.stack.slice(0, -1)
        }
        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            sourceSize: Qt.size(32, 32)
            source: Ui.trayItem?.icon ?? ""
        }
        Caption {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 60
            elide: Text.ElideRight
            text: Ui.trayItem?.tooltipTitle || Ui.trayItem?.title || Ui.trayItem?.id || ""
        }
    }

    Column {
        width: parent.width

        Repeater {
            model: opener.children

            Item {
                id: entry
                required property var modelData
                width: root.width
                height: modelData.isSeparator ? 9 : 34

                Rectangle {
                    visible: entry.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 16
                    height: 1
                    color: Theme.faint
                }

                Rectangle {
                    visible: !entry.modelData.isSeparator
                    anchors.fill: parent
                    radius: Theme.radius
                    color: Theme.card
                    opacity: mouse.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
                Row {
                    visible: !entry.modelData.isSeparator
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    opacity: entry.modelData.enabled ? 1 : 0.4

                    Icon {
                        visible: entry.modelData.buttonType !== QsMenuButtonType.None
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.buttonType === QsMenuButtonType.RadioButton
                            ? (entry.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked")
                            : (entry.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank")
                        size: 16
                        color: entry.modelData.checkState === Qt.Checked ? Theme.accent : Theme.dim
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.width - 60
                        text: entry.modelData.text.replace(/&(?!&)/g, "")
                        font.pixelSize: 12
                    }
                }
                Icon {
                    visible: entry.modelData.hasChildren
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "chevron_right"
                    size: 16
                    color: Theme.dim
                }
                MouseArea {
                    id: mouse
                    enabled: !entry.modelData.isSeparator && entry.modelData.enabled
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (entry.modelData.hasChildren) {
                            root.stack = root.stack.concat([entry.modelData]);
                        } else {
                            entry.modelData.triggered();
                            Ui.close();
                        }
                    }
                }
            }
        }
    }
}
