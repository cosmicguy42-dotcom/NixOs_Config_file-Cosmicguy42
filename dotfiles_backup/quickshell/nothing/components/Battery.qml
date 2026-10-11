import QtQuick
import Quickshell.Services.UPower
import qs.services

// Outline battery pill with a proportional fill, Nothing-style.
Row {
    id: root

    readonly property real level: Bat.level
    readonly property bool charging: Bat.charging
    readonly property bool low: level <= 0.15 && !charging

    visible: Bat.available
    spacing: 6

    Caption {
        visible: Config.get("pill.batteryPercent")
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.level * 100)
        color: root.low ? Theme.error : Theme.fg
        font.letterSpacing: 0.5
    }
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 11

        Rectangle {
            id: body
            width: 20
            height: 11
            radius: Theme.r(3.5)
            color: "transparent"
            border.width: 1
            border.color: root.low ? Theme.error : Theme.dim

            Rectangle {
                x: 2
                y: 2
                height: parent.height - 4
                width: Math.max(1.5, (parent.width - 4) * root.level)
                radius: Theme.r(1.5)
                color: root.charging ? Theme.accent : root.low ? Theme.error : Theme.fg
                Behavior on width { NumberAnimation { duration: 400 } }
            }
        }
        Rectangle {
            anchors.left: body.right
            anchors.leftMargin: 0.5
            anchors.verticalCenter: body.verticalCenter
            width: 1.5
            height: 4
            radius: Theme.r(1)
            color: root.low ? Theme.error : Theme.dim
        }
    }
}
