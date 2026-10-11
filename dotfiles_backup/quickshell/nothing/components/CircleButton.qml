import QtQuick
import qs.services

// Round button: outlined by default, solid accent when `active`.
Rectangle {
    id: root

    property string icon
    property bool active: false
    property real size: 40
    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: Theme.r(size / 2)
    color: active ? Theme.active : (mouse.containsMouse ? Theme.raised : "transparent")
    border.width: active ? 0 : 1
    border.color: Theme.faint

    Behavior on color { ColorAnimation { duration: 180 } }

    Icon {
        anchors.centerIn: parent
        text: root.icon
        size: root.size * 0.48
        filled: root.active
        color: root.active ? Theme.activeFg : Theme.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    scale: mouse.pressed ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }
}
