import QtQuick
import qs.services
import qs.components

// Pill button.
Rectangle {
    id: b

    property string text
    property string icon: ""
    property bool accent: false
    signal clicked

    width: row.width + 30
    height: 34
    radius: Theme.r(17)
    color: accent ? Theme.active : (m.containsMouse ? Theme.raised : "transparent")
    border.width: accent ? 0 : 1
    border.color: Theme.faint
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon {
            visible: b.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: b.icon
            size: 16
            color: b.accent ? Theme.activeFg : Theme.fg
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: b.text
            font.pixelSize: 12
            color: b.accent ? Theme.activeFg : Theme.fg
        }
    }
    MouseArea {
        id: m
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
