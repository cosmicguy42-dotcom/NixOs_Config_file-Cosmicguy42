import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.components

// The resting pill:  workspaces · clock · [media] · status
Row {
    id: root

    required property var screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    height: Theme.barHeight
    spacing: 16

    // Workspaces: one dot per workspace that exists, the active one stretched.
    Row {
        id: workspaces
        visible: Config.get("pill.workspaces")
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        readonly property var list: Hyprland.workspaces.values
            .filter(w => w.id > 0 && (!w.monitor || w.monitor === root.monitor))
            .sort((a, b) => a.id - b.id)

        Repeater {
            model: workspaces.list

            Rectangle {
                required property var modelData
                readonly property bool current: root.monitor?.activeWorkspace?.id === modelData.id

                anchors.verticalCenter: parent.verticalCenter
                width: current ? 20 : 6
                height: 6
                radius: Theme.r(3)
                color: modelData.urgent ? Theme.error : Theme.fg
                opacity: current || modelData.urgent ? 1 : 0.35

                Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({workspace = ${parent.modelData.id}})`)
                }
            }
        }

        WheelHandler {
            onWheel: e => Hyprland.dispatch(`hl.dsp.focus({workspace = "${e.angleDelta.y > 0 ? "r-1" : "r+1"}"})`)
        }
    }

    // Clock
    Item {
        anchors.verticalCenter: parent.verticalCenter
        readonly property string style: Config.get("pill.clock")
        readonly property string timeText: Qt.formatDateTime(time.date, Config.get("pill.clock24h") ? "hh:mm" : "h:mm")
        width: style === "dots" ? dots.width : text.implicitWidth
        height: style === "dots" ? dots.height : 20

        SystemClock {
            id: time
            precision: SystemClock.Minutes
        }
        DotText {
            id: dots
            visible: parent.style === "dots"
            text: parent.timeText
            dot: 2.2
            gap: 1
        }
        Text {
            id: text
            visible: parent.style !== "dots"
            anchors.verticalCenter: parent.verticalCenter
            text: parent.timeText
            font.family: parent.style === "serif" ? Theme.serif : Theme.mono
            font.pixelSize: parent.style === "serif" ? 22 : 13
            color: Theme.fg
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: Ui.toggle("calendar")
        }
    }

    // Weather: tiny dot glyph + temperature
    Item {
        visible: Forecast.ready && Config.get("pill.weather")
        anchors.verticalCenter: parent.verticalCenter
        width: wx.width
        height: wx.height

        Row {
            id: wx
            spacing: 7
            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                kind: Forecast.kind
                dot: 1.3
                gap: 0.6
                offOpacity: 0
            }
            Caption {
                anchors.verticalCenter: parent.verticalCenter
                text: Forecast.temp + "°"
                color: Theme.fg
                font.letterSpacing: 0.5
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: Ui.toggle("weather")
        }
    }

    // Now playing (only while there's a player)
    Item {
        visible: Player.active !== null && Player.title !== "" && Config.get("pill.media")
        anchors.verticalCenter: parent.verticalCenter
        width: media.width
        height: media.height

        Row {
            id: media
            spacing: 8

            // Live dot-matrix waveform (cava)
            DotWave {
                anchors.verticalCenter: parent.verticalCenter
                columns: 7
                lines: 5
                dot: 2
                gap: 1
                color: Player.playing ? Player.artAccent : Theme.dim
                offOpacity: 0.12
                glow: false
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 170)
                text: Player.title
                font.pixelSize: 12
                color: Player.playing ? Theme.fg : Theme.dim
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: Ui.toggle("media")
        }
    }

    // Screen recording: blinking red dot, click to stop
    Item {
        visible: Toggles.recording
        anchors.verticalCenter: parent.verticalCenter
        width: recRow.width
        height: recRow.height
        Row {
            id: recRow
            spacing: 6
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 7
                height: 7
                radius: Theme.r(3.5)
                color: Theme.error
                SequentialAnimation on opacity {
                    running: Toggles.recording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                }
            }
            DotText {
                anchors.verticalCenter: parent.verticalCenter
                text: Toggles.recElapsed
                dot: 1.6
                gap: 0.7
                color: Theme.error
                glow: false
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: Toggles.stopRecording()
        }
    }

    Tray {
        visible: items.length > 0 && Config.get("pill.tray")
        anchors.verticalCenter: parent.verticalCenter
    }

    // Status: unread dot + battery (volume icon when muted / no battery)
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: status.width
        height: status.height

        Row {
            id: status
            spacing: 8

            Rectangle {
                visible: Notifs.list.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: Theme.r(3)
                color: Theme.accent
            }
            Icon {
                visible: Toggles.dnd
                anchors.verticalCenter: parent.verticalCenter
                text: "notifications_off"
                size: 15
                color: Theme.dim
            }
            Icon {
                visible: Toggles.caffeine
                anchors.verticalCenter: parent.verticalCenter
                text: "coffee"
                size: 15
            }
            Icon {
                visible: Audio.muted
                anchors.verticalCenter: parent.verticalCenter
                text: "volume_off"
                size: 15
                color: Theme.dim
            }
            Icon {
                visible: Net.btConnected.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "bluetooth_connected"
                size: 15
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: Net.wifiIcon
                size: 15
                color: Net.active ? Theme.fg : Theme.dim
            }
            Battery {
                id: battery
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: Ui.toggle("control")
            onWheel: e => Audio.setVolume(Audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }
}
