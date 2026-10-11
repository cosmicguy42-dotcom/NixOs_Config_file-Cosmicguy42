import QtQuick
import qs.services

// Pill switch: hollow when off, accent-filled when on.
Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool on)

    implicitWidth: 38
    implicitHeight: 22
    radius: Theme.r(height / 2)
    color: checked ? Theme.active : "transparent"
    border.width: checked ? 0 : 1
    border.color: Theme.faint
    Behavior on color { ColorAnimation { duration: 180 } }

    Rectangle {
        width: 14
        height: 14
        radius: Theme.r(7)
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 4 : 4
        color: root.checked ? Theme.activeFg : Theme.dim
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
