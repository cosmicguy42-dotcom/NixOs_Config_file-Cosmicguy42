import QtQuick
import Quickshell
import qs.services
import qs.components

// Incoming notification, shown in the island for a few seconds.
Item {
    id: root

    readonly property var n: Notifs.latest
    readonly property string img: n?.image || (n?.appIcon ? Quickshell.iconPath(n.appIcon, true) : "")

    implicitWidth: row.width
    implicitHeight: Math.max(Theme.barHeight, row.height)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: Theme.r(4)
                color: Theme.accent
                visible: icon.status !== Image.Ready
            }
            RoundImage {
                id: icon
                anchors.fill: parent
                radius: Theme.r(13)
                thumb: 64
                source: root.img
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(360, Math.max(title.implicitWidth, body.implicitWidth))
            topPadding: 6
            bottomPadding: 6
            Label {
                id: title
                width: parent.width
                text: root.n?.summary ?? ""
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            Label {
                id: body
                width: parent.width
                text: (root.n?.body ?? "").replace(/\n/g, " ")
                font.pixelSize: 12
                color: Theme.dim
                visible: text !== ""
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => {
            if (root.n) {
                if (e.button === Qt.LeftButton)
                    Notifs.activate(root.n);
                else
                    root.n.dismiss();
            }
            Ui.popup = "";
        }
    }
}
