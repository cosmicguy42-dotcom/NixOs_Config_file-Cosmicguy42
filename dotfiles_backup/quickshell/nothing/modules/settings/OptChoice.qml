import QtQuick
import qs.services
import qs.components

// Segmented choice. options: [{ label, value }]
OptRow {
    id: r

    property var options: []
    property var current
    signal picked(var value)

    Rectangle {
        width: seg.width + 6
        height: 32
        radius: Theme.r(height / 2)
        color: "transparent"
        border.width: 1
        border.color: Theme.faint

        Row {
            id: seg
            x: 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: r.options
                Rectangle {
                    required property var modelData
                    readonly property bool on: r.current === modelData.value
                    width: t.implicitWidth + 24
                    height: 26
                    radius: Theme.r(13)
                    color: on ? Theme.fg : (m.containsMouse ? Theme.raised : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Caption {
                        id: t
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.on ? Theme.bg : Theme.fg
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: m
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: r.picked(parent.modelData.value)
                    }
                }
            }
        }
    }
}
