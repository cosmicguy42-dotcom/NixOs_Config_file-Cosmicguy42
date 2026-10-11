import QtQuick
import qs.services

// Nothing-style chunky slider: a pill that fills with solid colour, icon
// inside the fill. Drag or scroll anywhere; click the icon for iconClicked().
Rectangle {
    id: root

    property real value: 0 // 0..1
    property string icon
    signal moved(real v)
    signal iconClicked

    implicitWidth: 300
    implicitHeight: 44
    radius: Theme.r(height / 2)
    color: Theme.card
    clip: true

    Rectangle {
        id: fill
        height: parent.height
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, root.value)))
        radius: Theme.r(height / 2)
        color: Theme.active
        Behavior on width { NumberAnimation { duration: mouse.pressed ? 0 : 220; easing.type: Easing.OutCubic } }
    }
    Icon {
        id: ic
        x: (parent.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        text: root.icon
        size: 19
        filled: true
        color: Theme.activeFg
    }
    Caption {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.value * 100)
        font.pixelSize: 11
        // readable whether or not the fill reaches under it
        color: fill.width > parent.width - 50 ? Theme.activeFg : Theme.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        property bool onIcon: false
        function set(x) { root.moved(Math.max(0, Math.min(1, x / root.width))); }
        onPressed: e => {
            onIcon = e.x < root.height;
            if (!onIcon)
                set(e.x);
        }
        onPositionChanged: e => { if (pressed && !onIcon) set(e.x); }
        onClicked: if (onIcon) root.iconClicked()
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
