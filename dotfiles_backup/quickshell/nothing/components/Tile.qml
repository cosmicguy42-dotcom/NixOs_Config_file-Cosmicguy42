import QtQuick
import qs.services

// Quick-settings tile. Click toggles; the chevron (if `more`) opens details.
Rectangle {
    id: root

    property string icon
    property string label
    property string sub: ""
    property bool on: false
    property bool more: false
    signal toggled
    signal opened

    implicitHeight: 80
    radius: Theme.radius
    color: on ? Theme.active : (hover.containsMouse ? Theme.raised : Theme.card)
    Behavior on color { ColorAnimation { duration: 180 } }
    scale: hover.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    Icon {
        x: 14
        y: 14
        text: root.icon
        size: 18
        filled: root.on
        color: root.on ? Theme.activeFg : Theme.fg
    }
    Icon {
        visible: root.more
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: 8
        width: 24
        height: 24
        text: "chevron_right"
        size: 18
        color: root.on ? Theme.activeFg : Theme.dim
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.opened()
        }
    }
    Column {
        x: 14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        width: parent.width - 28
        Label {
            width: parent.width
            text: root.label
            font.pixelSize: 12
            font.weight: Font.Medium
            color: root.on ? Theme.activeFg : Theme.fg
        }
        Caption {
            width: parent.width
            visible: text !== ""
            text: root.sub
            font.pixelSize: 9
            font.letterSpacing: 1
            elide: Text.ElideRight
            color: root.on ? Qt.alpha(Theme.activeFg, 0.75) : Theme.dim
        }
    }
}
