import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.services
import qs.components

// Media player: blurred cover-art backdrop tinted by the album's colour, big
// art, serif title, live dot-matrix waveform, seekable dot progress, shuffle /
// repeat and a player switcher when more than one is running.
Item {
    id: root

    readonly property var p: Player.active
    readonly property bool has: p !== null
    readonly property color tint: Player.artAccent
    readonly property bool canSeek: (p?.canSeek ?? false) && (p?.length ?? 0) > 0

    implicitWidth: 440
    implicitHeight: col.height

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // --- Backdrop: cover art, blurred and tinted
    Rectangle {
        // bleed to the island's edges (it clips us to its own shape)
        anchors.fill: parent
        anchors.leftMargin: -22
        anchors.rightMargin: -22
        anchors.topMargin: -20
        anchors.bottomMargin: -20
        radius: Theme.r(Theme.radius)
        color: Qt.alpha(root.tint, 0.14)
        clip: true
        visible: root.has
        Image {
            id: bgArt
            anchors.fill: parent
            source: Player.art
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(96, 96)
            asynchronous: !String(source).startsWith("image://")
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: bgArt
            blurEnabled: true
            blur: 1
            blurMax: 48
            saturation: 0.2
            brightness: Theme.dark ? -0.35 : 0.2
            opacity: bgArt.status === Image.Ready ? 0.55 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
    }

    Column {
        id: col
        x: 16
        width: parent.width - 32
        topPadding: 16
        bottomPadding: 16
        spacing: 16

        Row {
            spacing: 18
            Item {
                width: 116
                height: 116
                Rectangle { anchors.fill: parent; radius: Theme.r(Theme.radius); color: Theme.raised }
                DotMatrix {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    rows: ["...######", "...#....#", "...#....#", "...#....#", ".###..###", "####.####", ".##...##."]
                    dot: 4
                    gap: 2
                    color: Theme.dim
                }
                RoundImage { id: art; anchors.fill: parent; radius: Theme.r(Theme.radius); thumb: 240; source: Player.art }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: col.width - 116 - 18
                spacing: 4
                Row {
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6; height: 6; radius: Theme.r(3)
                        color: Player.playing ? root.tint : Theme.faint
                    }
                    Overline { text: root.has ? root.p.identity : "Media" }
                }
                Heading {
                    width: parent.width
                    text: root.has ? (Player.title || "Untitled") : "Nothing playing"
                    font.pixelSize: 28
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    text: root.has ? [Player.artist, root.p?.trackAlbum].filter(x => x).join(" · ") : "Start something in any media player"
                    color: Theme.dim
                }
            }
        }

        // Live waveform
        DotWave {
            visible: root.has
            columns: Math.floor((col.width + 3) / 8)
            lines: 7
            dot: 5
            gap: 3
            color: root.tint
            offOpacity: 0.08
        }

        // Dot progress: click or drag to seek
        Column {
            visible: root.has && (root.p?.length ?? 0) > 0
            width: col.width
            spacing: 6
            Item {
                width: prog.width
                height: prog.height
                DotMatrix {
                    id: prog
                    readonly property int cols: Math.floor((col.width + 3) / 7)
                    readonly property real frac: root.p && root.p.length > 0 ? root.p.position / root.p.length : 0
                    rows: [Array.from({ length: cols }, (_, i) => i <= Math.floor(frac * cols) ? "#" : ".").join("")]
                    dot: 4
                    gap: 3
                    color: Theme.fg
                    offOpacity: 0.15
                    glow: false
                }
                // Grids can't hold anchored children, so the seek area is a sibling
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    enabled: root.canSeek
                    cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                    function seek(x) { root.p.position = Math.max(0, Math.min(1, x / prog.width)) * root.p.length; }
                    onPressed: e => seek(e.x)
                    onPositionChanged: e => { if (pressed) seek(e.x); }
                }
            }
            Row {
                width: parent.width
                Caption { width: parent.width / 2; text: root.fmt(root.p?.position ?? 0) }
                Caption { width: parent.width / 2; horizontalAlignment: Text.AlignRight; text: "-" + root.fmt((root.p?.length ?? 0) - (root.p?.position ?? 0)) }
            }
        }

        // Controls
        Item {
            visible: root.has
            width: col.width
            height: 56
            CircleButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                size: 38
                icon: "shuffle"
                visible: root.p?.shuffleSupported ?? false
                active: root.p?.shuffle ?? false
                onClicked: root.p.shuffle = !root.p.shuffle
            }
            Row {
                anchors.centerIn: parent
                spacing: 14
                CircleButton {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 44
                    icon: "skip_previous"
                    opacity: root.p?.canGoPrevious ? 1 : 0.35
                    onClicked: root.p?.previous()
                }
                Rectangle {
                    width: 56
                    height: 56
                    radius: Theme.r(height / 2)
                    color: root.tint
                    scale: pm.pressed ? 0.93 : 1
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Icon {
                        anchors.centerIn: parent
                        text: Player.playing ? "pause" : "play_arrow"
                        size: 28
                        filled: true
                        color: root.tint.hslLightness > 0.6 ? "#111111" : "#ffffff"
                    }
                    MouseArea { id: pm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.p?.togglePlaying() }
                }
                CircleButton {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 44
                    icon: "skip_next"
                    opacity: root.p?.canGoNext ? 1 : 0.35
                    onClicked: root.p?.next()
                }
            }
            CircleButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                size: 38
                visible: root.p?.loopSupported ?? false
                icon: root.p?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                active: (root.p?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                onClicked: root.p.loopState = root.p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                    : root.p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
            }
        }

        // Player switcher
        Flow {
            visible: Player.players.length > 1
            width: col.width
            spacing: 6
            Repeater {
                model: Player.players
                Rectangle {
                    required property var modelData
                    readonly property bool on: modelData === root.p
                    width: pl.implicitWidth + 22
                    height: 28
                    radius: Theme.r(height / 2)
                    color: on ? Theme.active : "transparent"
                    border.width: on ? 0 : 1
                    border.color: Theme.faint
                    Caption { id: pl; anchors.centerIn: parent; text: parent.modelData.identity; color: parent.on ? Theme.activeFg : Theme.fg }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Player.pinned = parent.modelData }
                }
            }
        }
    }
}
