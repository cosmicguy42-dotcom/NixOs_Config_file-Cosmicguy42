import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// Screenshots + screen recording (scripts/capture.sh).
Column {
    id: root

    width: 420
    spacing: 16

    property int delay: 0
    property bool audio: false
    property string last: ""

    function run(args) {
        Ui.close();
        Quickshell.execDetached([Quickshell.shellPath("scripts/capture.sh")].concat(args));
    }

    FileView {
        path: Theme.stateDir + "/last-capture"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.last = text().trim()
    }

    component Big: Rectangle {
        id: b
        property string icon
        property string label
        signal clicked
        width: (root.width - 16) / 3
        height: 92
        radius: Theme.r(Theme.radius)
        color: m.containsMouse ? Theme.raised : Theme.card
        scale: m.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Column {
            anchors.centerIn: parent
            spacing: 8
            Icon { anchors.horizontalCenter: parent.horizontalCenter; text: b.icon; size: 26 }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: b.label }
        }
        MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
    }
    component Chip: Rectangle {
        id: c
        property string text
        property bool on
        signal clicked
        width: ct.implicitWidth + 24
        height: 28
        radius: Theme.r(height / 2)
        color: on ? Theme.active : "transparent"
        border.width: on ? 0 : 1
        border.color: Theme.faint
        Caption { id: ct; anchors.centerIn: parent; text: c.text; color: c.on ? Theme.activeFg : Theme.fg }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: c.clicked() }
    }

    Row {
        spacing: 10
        Heading { text: "Capture"; font.pixelSize: 28 }
    }

    // --- Recording in progress
    Rectangle {
        visible: Toggles.recording
        width: parent.width
        height: 76
        radius: Theme.r(Theme.radius)
        color: Qt.alpha(Theme.error, 0.12)
        border.width: 1
        border.color: Qt.alpha(Theme.error, 0.5)
        Row {
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 10; height: 10; radius: Theme.r(5)
                color: Theme.error
                SequentialAnimation on opacity {
                    running: Toggles.recording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 700 }
                    NumberAnimation { to: 1; duration: 700 }
                }
            }
            DotText {
                anchors.verticalCenter: parent.verticalCenter
                text: Toggles.recElapsed
                dot: 4
                gap: 1.6
                color: Theme.error
            }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: st.implicitWidth + 36
            height: 40
            radius: Theme.r(height / 2)
            color: Theme.error
            Label { id: st; anchors.centerIn: parent; text: "Stop"; color: "#ffffff" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.run(["stop"]) }
        }
    }

    // --- Screenshot
    Column {
        width: parent.width
        spacing: 10
        Row {
            width: parent.width
            Overline { width: parent.width - delays.width; anchors.verticalCenter: parent.verticalCenter; text: "Screenshot" }
            Row {
                id: delays
                spacing: 4
                Repeater {
                    model: [0, 3, 5, 10]
                    Chip {
                        required property int modelData
                        text: modelData ? modelData + "s" : "Now"
                        on: root.delay === modelData
                        onClicked: root.delay = modelData
                    }
                }
            }
        }
        Row {
            spacing: 8
            Big { icon: "crop"; label: "Area"; onClicked: root.run(["shot", "area", String(root.delay)]) }
            Big { icon: "select_window"; label: "Window"; onClicked: root.run(["shot", "window", String(root.delay)]) }
            Big { icon: "desktop_windows"; label: "Screen"; onClicked: root.run(["shot", "screen", String(root.delay)]) }
        }
    }

    // --- Record
    Column {
        visible: !Toggles.recording
        width: parent.width
        spacing: 10
        Row {
            width: parent.width
            Overline { width: parent.width - aud.width; anchors.verticalCenter: parent.verticalCenter; text: "Record" }
            Row {
                id: aud
                spacing: 8
                Caption { anchors.verticalCenter: parent.verticalCenter; text: "System audio" }
                Switch { checked: root.audio; onToggled: on => root.audio = on }
            }
        }
        Row {
            spacing: 8
            Big { icon: "screen_record"; label: "Area"; onClicked: root.run(["rec", "area"].concat(root.audio ? ["audio"] : [])) }
            Big { icon: "videocam"; label: "Screen"; onClicked: root.run(["rec", "screen"].concat(root.audio ? ["audio"] : [])) }
            Big { icon: "folder_open"; label: "Folder"; onClicked: { Ui.close(); Qt.openUrlExternally("file://" + Quickshell.env("HOME") + "/Videos/Recordings"); } }
        }
    }

    // --- Last capture
    Rectangle {
        visible: root.last !== ""
        width: parent.width
        height: 84
        radius: Theme.r(Theme.radius)
        color: Theme.card
        RoundImage {
            id: thumb
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 96
            height: 60
            radius: Theme.r(Theme.radius / 2)
            thumb: 200
            source: root.last.endsWith(".png") ? "file://" + root.last : ""
        }
        Icon {
            visible: !root.last.endsWith(".png")
            anchors.centerIn: thumb
            text: "movie"
            size: 26
            color: Theme.dim
        }
        Column {
            anchors.left: thumb.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 96 - 14 - 12 - acts.width - 20
            Overline { text: "Last capture" }
            Caption { width: parent.width; elide: Text.ElideLeft; text: root.last.split("/").pop(); color: Theme.fg }
        }
        Row {
            id: acts
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            CircleButton { size: 36; icon: "edit"; visible: root.last.endsWith(".png"); onClicked: root.run(["edit"]) }
            CircleButton { size: 36; icon: "content_copy"; onClicked: root.run(["copy"]) }
            CircleButton { size: 36; icon: "open_in_new"; onClicked: root.run(["open"]) }
        }
    }
}
