import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.components

// The lock screen itself: blurred wallpaper, dot-matrix clock, serif date,
// glass widget cards, password pill. Used by the real session lock and the
// preview window (preview = true: no PAM, Esc closes).
Item {
    id: root

    required property var lock // Lock.qml scope
    property bool preview: false

    anchors.fill: parent

    // Everything is sized for 1080p and scaled to the actual screen.
    readonly property real s: Math.max(0.5, Math.min(width / 1920, height / 1080))

    SystemClock {
        id: time
        precision: SystemClock.Seconds
    }

    // --- Background
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }
    Image {
        id: wall
        anchors.fill: parent
        source: Appearance.wallpaper ? "file://" + Appearance.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width / 2, height / 2) // blurred anyway: half-res is plenty
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: Theme.dark ? -0.25 : 0.05
        saturation: -0.1
        opacity: wall.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.35)
    }

    // --- Content (fades/rises in on lock, out on unlock)
    Item {
        id: content
        anchors.fill: parent
        opacity: root.lock.unlocking ? 0 : 1
        scale: root.lock.unlocking ? 1.03 : 1
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        property real rise: 0
        Component.onCompleted: rise = 1
        transform: Translate { y: (1 - content.rise) * 30 }
        Behavior on rise { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }

        Column {
            id: head
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.17
            spacing: 26 * root.s

            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Locked"
                color: Theme.accent
                font.pixelSize: 12 * root.s
                font.letterSpacing: 4 * root.s
                font.capitalization: Font.AllUppercase
            }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(time.date, Config.get("pill.clock24h") ? "hh:mm" : "h:mm")
                dot: 14 * root.s
                gap: 5 * root.s
                offOpacity: 0.07
            }
            Heading {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(time.date, "dddd, d MMMM")
                font.pixelSize: 54 * root.s
            }
        }

        // Widget cards: each sized to its content, all the same height.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: head.bottom
            anchors.topMargin: 56 * root.s
            spacing: 14 * root.s

            GlassCard {
                visible: Config.get("lock.weather") && Forecast.ready
                content: Row {
                    spacing: 20 * root.s
                    DotIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        kind: Forecast.kind
                        dot: 5 * root.s
                        gap: 2 * root.s
                        offOpacity: 0.05
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * root.s
                        Heading { text: Forecast.temp + "°"; font.pixelSize: 52 * root.s }
                        Caption { text: Forecast.desc; font.pixelSize: 12 * root.s; color: Theme.fg }
                        Caption { text: Forecast.location; font.pixelSize: 11 * root.s }
                    }
                }
            }

            GlassCard {
                visible: Config.get("lock.media") && Player.active !== null && Player.title !== ""
                content: Row {
                    spacing: 18 * root.s
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 76 * root.s
                        height: width
                        Rectangle { anchors.fill: parent; radius: Theme.r(18 * root.s); color: Theme.raised }
                        Icon { anchors.centerIn: parent; text: "music_note"; size: 28 * root.s; color: Theme.dim }
                        RoundImage { anchors.fill: parent; radius: Theme.r(18 * root.s); thumb: 160; source: Player.art }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10 * root.s
                        Column {
                            spacing: 3 * root.s
                            Label {
                                width: Math.min(implicitWidth, 260 * root.s)
                                text: Player.title
                                font.pixelSize: 15 * root.s
                            }
                            Caption {
                                visible: text !== ""
                                width: Math.min(implicitWidth, 260 * root.s)
                                elide: Text.ElideRight
                                text: Player.artist
                                font.pixelSize: 12 * root.s
                            }
                        }
                        DotWave {
                            columns: 20
                            lines: 5
                            dot: 3 * root.s
                            gap: 2 * root.s
                            color: Player.artAccent
                            offOpacity: 0.1
                        }
                        Row {
                            spacing: 8 * root.s
                            CircleButton { size: 36 * root.s; icon: "skip_previous"; onClicked: Player.active?.previous() }
                            CircleButton { size: 36 * root.s; icon: Player.playing ? "pause" : "play_arrow"; active: true; onClicked: Player.active?.togglePlaying() }
                            CircleButton { size: 36 * root.s; icon: "skip_next"; onClicked: Player.active?.next() }
                        }
                    }
                }
            }

            GlassCard {
                visible: Bat.available
                content: Column {
                    spacing: 2 * root.s
                    Heading {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(Bat.level * 100) + "%"
                        font.pixelSize: 52 * root.s
                    }
                    Caption {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Bat.charging ? "Charging" : "Battery"
                        font.pixelSize: 12 * root.s
                    }
                }
            }
        }

        // Password
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height * 0.11
            spacing: 16 * root.s

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 400 * root.s
                height: 60 * root.s
                radius: Theme.r(height / 2)
                color: Theme.glass
                border.width: 1
                border.color: root.lock.failed ? Theme.error : input.activeFocus ? Qt.alpha(Theme.fg, 0.45) : Qt.alpha(Theme.faint, 0.6)
                Behavior on border.color { ColorAnimation { duration: 200 } }

                transform: Translate { id: shake }
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: shake; property: "x"; to: -12; duration: 50 }
                    NumberAnimation { target: shake; property: "x"; to: 12; duration: 80 }
                    NumberAnimation { target: shake; property: "x"; to: -8; duration: 70 }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
                }
                Connections {
                    target: root.lock
                    function onFailedChanged() { if (root.lock.failed) shakeAnim.restart(); }
                }

                Icon {
                    x: 22 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "lock"
                    size: 20 * root.s
                    color: Theme.dim
                }

                // Typed characters as dots
                Row {
                    anchors.centerIn: parent
                    spacing: 8 * root.s
                    Repeater {
                        model: Math.min(input.text.length, 20)
                        Rectangle {
                            width: 9 * root.s
                            height: width
                            radius: Theme.r(width / 2)
                            color: Theme.fg
                            opacity: root.lock.busy ? 0.4 : 1
                        }
                    }
                }
                Caption {
                    anchors.centerIn: parent
                    visible: input.text.length === 0
                    text: root.lock.busy ? "Checking…" : root.lock.failed ? "Wrong password" : root.preview ? "Preview · Esc to close" : "Enter password"
                    color: root.lock.failed ? Theme.error : Theme.dim
                    font.pixelSize: 13 * root.s
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 9 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 42 * root.s
                    height: width
                    radius: Theme.r(width / 2)
                    color: Theme.active
                    opacity: input.text.length > 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Icon { anchors.centerIn: parent; text: "arrow_forward"; size: 20 * root.s; color: Theme.activeFg }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.submit() }
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    opacity: 0 // rendered as dots above
                    echoMode: TextInput.Password
                    focus: true
                    enabled: !root.lock.busy
                    Component.onCompleted: forceActiveFocus()
                    onTextChanged: if (text.length > 0) root.lock.failed = false
                    Keys.onReturnPressed: root.submit()
                    Keys.onEnterPressed: root.submit()
                    Keys.onEscapePressed: {
                        if (root.preview)
                            root.lock.closePreview();
                        text = "";
                    }
                }
            }

            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Quickshell.env("USER")
                font.pixelSize: 12 * root.s
            }
        }

        // Session buttons
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 40 * root.s
            spacing: 12 * root.s
            CircleButton {
                size: 48 * root.s
                icon: "bedtime"
                onClicked: if (!root.preview) Quickshell.execDetached(["systemctl", "suspend"])
            }
            CircleButton {
                id: off
                property bool armed: false
                size: 48 * root.s
                icon: "power_settings_new"
                active: armed
                onClicked: {
                    if (!armed) { armed = true; disarm.restart(); return; }
                    if (!root.preview) Quickshell.execDetached(["systemctl", "poweroff"]);
                }
                Timer { id: disarm; interval: 3000; onTriggered: off.armed = false }
            }
        }
    }

    function submit() {
        if (input.text.length === 0)
            return;
        if (root.preview) {
            input.text = "";
            root.lock.closePreview();
            return;
        }
        root.lock.tryUnlock(input.text);
        input.text = "";
    }

    // Any click refocuses the password field.
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: input.forceActiveFocus()
    }

    // Glass card that wraps its content with even padding.
    component GlassCard: Rectangle {
        id: card
        property Item content
        implicitWidth: (content?.width ?? 0) + 52 * root.s
        implicitHeight: 150 * root.s
        radius: Theme.r(Theme.radius * root.s)
        color: Theme.glass
        border.width: 1
        border.color: Qt.alpha(Theme.faint, 0.5)
        onContentChanged: if (content) { content.parent = card; content.anchors.centerIn = card; }
    }
}
