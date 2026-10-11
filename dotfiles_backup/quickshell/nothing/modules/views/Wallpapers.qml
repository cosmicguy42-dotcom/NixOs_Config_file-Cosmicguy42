import QtQuick
import Qt.labs.folderlistmodel
import qs.services
import qs.components

// Horizontal strip of wallpapers. Click to apply; colours follow.
Column {
    id: root

    width: 620
    spacing: 12

    Row {
        width: parent.width
        Row {
            width: parent.width - shuffle.width - wh.width - 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Heading { text: "Wallpaper"; font.pixelSize: 24; anchors.baseline: count.baseline }
            Caption { id: count; text: folder.count; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle {
            id: wh
            anchors.verticalCenter: parent.verticalCenter
            width: whl.implicitWidth + 24
            height: 30
            radius: Theme.r(height / 2)
            color: whm.containsMouse ? Theme.raised : "transparent"
            border.width: 1
            border.color: Theme.faint
            Caption { id: whl; anchors.centerIn: parent; text: "Browse Wallhaven"; color: Theme.fg }
            MouseArea { id: whm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.openSettings("wallhaven") }
        }
        Item { width: 8; height: 1 }
        CircleButton {
            id: shuffle
            size: 30
            icon: "shuffle"
            onClicked: Appearance.randomWallpaper()
        }
    }

    ListView {
        id: list
        width: parent.width
        height: 96
        orientation: ListView.Horizontal
        spacing: 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.dur
        preferredHighlightBegin: width / 2 - 80
        preferredHighlightEnd: width / 2 + 80
        highlightRangeMode: ListView.ApplyRange

        model: FolderListModel {
            id: folder
            folder: "file://" + Appearance.wallDir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"]
            showDirs: false
            sortField: FolderListModel.Name
            onStatusChanged: if (status === FolderListModel.Ready) list.currentIndex = Math.max(0, indexOf("file://" + Appearance.wallpaper))
        }

        delegate: Item {
            id: tile
            required property string filePath
            required property int index
            readonly property bool current: filePath === Appearance.wallpaper

            width: 160
            height: 96

            RoundImage {
                anchors.fill: parent
                anchors.margins: tile.current ? 4 : 0
                radius: Theme.r(tile.current ? 14 : 18)
                thumb: 320
                source: "file://" + tile.filePath
                scale: hover.containsMouse && !tile.current ? 1.03 : 1
                Behavior on scale { NumberAnimation { duration: 200 } }
                Behavior on anchors.margins { NumberAnimation { duration: 200 } }
            }
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
                opacity: tile.current ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    list.currentIndex = tile.index;
                    Appearance.setWallpaper(tile.filePath);
                }
            }
        }

        // Vertical wheel scrolls the strip sideways.
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            onWheel: e => list.flick(e.angleDelta.y * 12, 0)
        }
    }
}
