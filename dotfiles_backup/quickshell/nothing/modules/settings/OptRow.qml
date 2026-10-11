import QtQuick
import qs.services
import qs.components

// One setting: label + description on the left, control on the right.
// `modified` shows an accent dot; clicking it emits reset().
Item {
    id: row

    property string label
    property string sub: ""
    property bool modified: false
    signal reset
    default property alias control: slot.data

    width: parent ? parent.width : 400
    implicitHeight: Math.max(58, text.height + 26)

    Column {
        id: text
        x: 22
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - slot.width - 70
        spacing: 3
        Row {
            spacing: 8
            Label {
                text: row.label
                font.pixelSize: 13
            }
            Rectangle {
                visible: row.modified
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: Theme.r(3)
                color: Theme.accent
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.reset()
                }
            }
        }
        Caption {
            visible: row.sub !== ""
            width: parent.width
            text: row.sub
            wrapMode: Text.Wrap
        }
    }
    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
    Rectangle {
        anchors.bottom: parent.bottom
        x: 22
        width: parent.width - 44
        height: 1
        color: Theme.faint
        opacity: 0.35
    }
}
