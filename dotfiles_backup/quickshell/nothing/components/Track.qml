import QtQuick
import qs.services

// Thin line slider with a dot handle. `value` is 0..1; emits moved(v) while dragging.
Item {
    id: root

    property real value: 0
    property bool interactive: true
    signal moved(real v)
    signal committed(real v) // on release / wheel

    implicitWidth: 200
    implicitHeight: 16

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 2
        radius: Theme.r(1)
        color: Theme.faint
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: 2
        radius: Theme.r(1)
        color: Theme.fg
        Behavior on width { NumberAnimation { duration: mouse.pressed ? 0 : 200; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        visible: root.interactive
        x: parent.width * Math.max(0, Math.min(1, root.value)) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: mouse.pressed || mouse.containsMouse ? 12 : 8
        height: width
        radius: Theme.r(width / 2)
        color: Theme.fg
        Behavior on width { NumberAnimation { duration: 120 } }
        Behavior on x { NumberAnimation { duration: mouse.pressed ? 0 : 200; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouse
        enabled: root.interactive
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function update(x) { root.moved(Math.max(0, Math.min(1, (x - 6) / root.width))); }
        onPressed: e => update(e.x)
        onReleased: root.committed(root.value)
        onPositionChanged: e => { if (pressed) update(e.x); }
        onWheel: e => {
            const v = Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)));
            root.moved(v);
            root.committed(v);
        }
    }
}
