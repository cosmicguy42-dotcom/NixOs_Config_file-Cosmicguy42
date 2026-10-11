import QtQuick
import Quickshell
import qs.services
import qs.components

// Quick settings: volume, brightness, theme, wallpaper, power, notifications.
Column {
    id: root

    width: 380
    spacing: 16

    Column {
        width: parent.width
        spacing: 8
        PillSlider {
            width: parent.width
            icon: Audio.muted ? "volume_off" : "volume_up"
            value: Audio.muted ? 0 : Audio.volume
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
        PillSlider {
            visible: Brightness.available
            width: parent.width
            icon: "light_mode"
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }
    }

    Grid {
        width: parent.width
        columns: 3
        spacing: 8
        readonly property real tileW: (width - 16) / 3

        Tile {
            width: parent.tileW
            icon: Net.wifiIcon
            label: "Wi-Fi"
            sub: !Net.wifiOn ? "Off" : Net.active ? Net.active.name : "Not connected"
            on: Net.wifiOn
            more: true
            onToggled: Net.setWifi(!Net.wifiOn)
            onOpened: Ui.open("wifi")
        }
        Tile {
            width: parent.tileW
            icon: Net.btConnected.length > 0 ? "bluetooth_connected" : Net.btOn ? "bluetooth" : "bluetooth_disabled"
            label: "Bluetooth"
            sub: !Net.btOn ? "Off" : Net.btConnected.length > 0 ? Net.btConnected[0].name : "On"
            on: Net.btOn
            more: true
            onToggled: Net.setBt(!Net.btOn)
            onOpened: Ui.open("bluetooth")
        }
        Tile {
            width: parent.tileW
            icon: Toggles.dnd ? "notifications_off" : "notifications"
            label: "Silent"
            sub: Toggles.dnd ? "No popups" : "Off"
            on: Toggles.dnd
            onToggled: Toggles.dnd = !Toggles.dnd
        }
        Tile {
            width: parent.tileW
            icon: "coffee"
            label: "Caffeine"
            sub: Toggles.caffeine ? "Stay awake" : "Off"
            on: Toggles.caffeine
            onToggled: Toggles.caffeine = !Toggles.caffeine
        }
        Tile {
            width: parent.tileW
            icon: "nightlight"
            label: "Night light"
            sub: Toggles.nightLight ? Config.nightTemp + "K" : "Off"
            on: Toggles.nightLight
            onToggled: Toggles.setNightLight(!Toggles.nightLight)
        }
        Tile {
            width: parent.tileW
            icon: Audio.micMuted ? "mic_off" : "mic"
            label: "Microphone"
            sub: Audio.micMuted ? "Muted" : "Live"
            on: !Audio.micMuted
            onToggled: Audio.toggleMic()
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.faint }

    Row {
        width: parent.width
        spacing: 10

        CircleButton {
            icon: Theme.dark ? "dark_mode" : "light_mode"
            onClicked: Appearance.toggleMode()
        }
        CircleButton {
            icon: "wallpaper"
            onClicked: Ui.open("wallpaper")
        }
        CircleButton {
            icon: "shuffle"
            onClicked: Appearance.randomWallpaper()
        }
        CircleButton {
            icon: "screenshot_region"
            onClicked: Ui.open("capture")
        }
        Item { width: parent.width - 6 * 40 - 6 * 10; height: 1 }
        CircleButton {
            icon: "settings"
            onClicked: Ui.openSettings("appearance")
        }
        CircleButton {
            icon: "power_settings_new"
            onClicked: Ui.open("power")
        }
    }

    Column {
        width: parent.width
        spacing: 8
        Overline { text: "Palette" }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: Appearance.schemes
                Rectangle {
                    required property var modelData
                    readonly property bool on: Appearance.scheme === modelData.id
                    width: chip.implicitWidth + 22
                    height: 26
                    radius: Theme.r(13)
                    color: on ? Theme.fg : "transparent"
                    border.width: on ? 0 : 1
                    border.color: Theme.faint
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Caption {
                        id: chip
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.on ? Theme.bg : Theme.fg
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Appearance.setScheme(parent.modelData.id)
                    }
                }
            }
        }
    }

    // Notifications
    Column {
        visible: Notifs.list.length > 0
        width: parent.width
        spacing: 8

        Rectangle { width: parent.width; height: 1; color: Theme.faint }
        Row {
            width: parent.width
            Overline { width: parent.width - clear.width; text: "Notifications · " + Notifs.list.length }
            Caption {
                id: clear
                text: "Clear"
                color: Theme.accent
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clear()
                }
            }
        }
        Repeater {
            model: Notifs.list.slice(-4).reverse()
            Rectangle {
                id: card
                required property var modelData
                width: root.width
                height: 54
                radius: Theme.radius
                color: hover.containsMouse ? Theme.raised : Qt.alpha(Theme.raised, 0.5)
                Behavior on color { ColorAnimation { duration: 150 } }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 14
                    width: parent.width - 28 - 24
                    spacing: 2
                    Label {
                        width: parent.width
                        text: (card.modelData.appName ? card.modelData.appName + "  ·  " : "") + card.modelData.summary
                        font.weight: Font.Medium
                        font.pixelSize: 12
                    }
                    Label {
                        width: parent.width
                        text: card.modelData.body.replace(/\n/g, " ")
                        color: Theme.dim
                        font.pixelSize: 12
                        visible: text !== ""
                    }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.activate(card.modelData)
                }
                Icon {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "close"
                    size: 16
                    color: Theme.dim
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.modelData.dismiss()
                    }
                }
            }
        }
    }
}
