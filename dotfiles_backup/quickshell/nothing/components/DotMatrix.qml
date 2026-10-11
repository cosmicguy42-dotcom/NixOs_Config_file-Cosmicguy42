import QtQuick
import qs.services

// Renders a bitmap (array of equal-length strings, '#' = lit) as dots.
// Unlit dots stay faintly visible; lit dots fade when the bitmap changes.
Grid {
    id: root

    property var rows: ["."]
    property real dot: 2.4
    property real gap: 1.2
    property color color: Theme.fg
    property real offOpacity: 0.09
    property bool glow: true // bloom (when enabled in settings)
    property int fade: 260   // ms for a dot to light up / dim

    layer.enabled: glow && Config.get("look.bloom")
    layer.smooth: true
    layer.effect: Bloom {
        glow: root.color
        size: Math.max(6, root.dot * 3)
    }

    columns: rows[0].length
    rowSpacing: gap
    columnSpacing: gap

    Repeater {
        model: root.columns * root.rows.length

        Rectangle {
            required property int index
            readonly property bool lit: root.rows[Math.floor(index / root.columns)]?.charAt(index % root.columns) === "#"

            width: root.dot
            height: root.dot
            radius: Theme.r(root.dot / 2)
            color: root.color
            opacity: lit ? 1 : root.offOpacity

            Behavior on opacity {
                NumberAnimation { duration: root.fade; easing.type: Easing.OutCubic }
            }
        }
    }
}
