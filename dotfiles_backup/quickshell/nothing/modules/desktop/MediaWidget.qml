import QtQuick
import qs.services
import qs.components

// Now playing, only while there's a player.
Glass {
    id: root
    readonly property bool available: Player.active !== null && Player.title !== ""
    width: 380
    height: 168

    readonly property var p: Player.active

    Row {
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16
        Item {
            width: 100
            height: 100
            anchors.verticalCenter: parent.verticalCenter
            Rectangle { anchors.fill: parent; radius: Theme.r(20); color: Theme.raised }
            Icon { anchors.centerIn: parent; text: "music_note"; size: 32; color: Theme.dim }
            RoundImage { anchors.fill: parent; radius: Theme.r(20); thumb: 200; source: Player.art }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: 228
            spacing: 6
            Heading { width: parent.width; text: Player.title; font.pixelSize: 22 }
            Caption { width: parent.width; elide: Text.ElideRight; text: Player.artist || (root.p?.identity ?? "") }
            DotWave {
                columns: 24
                lines: 5
                dot: 3
                gap: 2.4
                color: Player.artAccent
                offOpacity: 0.1
            }
            Track {
                width: parent.width
                interactive: false
                visible: (root.p?.length ?? 0) > 0
                value: root.p ? root.p.position / Math.max(1, root.p.length) : 0
            }
            Row {
                spacing: 6
                CircleButton { size: 32; icon: "skip_previous"; onClicked: Player.active?.previous() }
                CircleButton { size: 32; icon: Player.playing ? "pause" : "play_arrow"; active: true; onClicked: Player.active?.togglePlaying() }
                CircleButton { size: 32; icon: "skip_next"; onClicked: Player.active?.next() }
            }
        }
    }
}
