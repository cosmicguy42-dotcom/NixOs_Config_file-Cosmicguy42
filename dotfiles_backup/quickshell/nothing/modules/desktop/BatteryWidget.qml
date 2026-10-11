import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.components

// Ring of dots lit by charge level, Nothing-style.
Glass {
    id: root
    readonly property real level: Bat.level
    readonly property bool charging: Bat.charging
    readonly property int dots: 40
    readonly property int litCount: Math.round(level * dots)
    property int chase: 0 // charging: a bright head travels along the lit dots

    Timer {
        interval: 70
        running: root.charging && root.visible
        repeat: true
        onTriggered: root.chase = (root.chase + 1) % Math.max(1, root.litCount + 6)
    }

    readonly property bool available: Bat.available
    width: 180
    height: 180

    Item {
        id: ring
        anchors.fill: parent
        layer.enabled: Config.get("look.bloom")
        layer.effect: Bloom { glow: root.charging ? Theme.accent : Theme.fg; size: 12 }
        Repeater {
            model: root.dots
            Rectangle {
                required property int index
                readonly property real a: -Math.PI / 2 + index / root.dots * 2 * Math.PI
                readonly property bool lit: index < root.litCount
                readonly property bool head: root.charging && Math.abs(index - root.chase) <= 1
                width: 6
                height: 6
                radius: Theme.r(3)
                x: ring.width / 2 + Math.cos(a) * 68 - 3
                y: ring.height / 2 + Math.sin(a) * 68 - 3
                color: root.charging ? Theme.accent : (root.level <= 0.15 ? Theme.error : Theme.fg)
                opacity: !lit ? 0.12 : root.charging ? (head ? 1 : 0.55) : 1
                Behavior on opacity { NumberAnimation { duration: root.charging ? 90 : 400 } }
            }
        }
    }
    Column {
        anchors.centerIn: parent
        Heading {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.level * 100)
            font.pixelSize: 54
        }
        Caption {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.charging ? "Charging" : "Battery"
        }
    }
}
