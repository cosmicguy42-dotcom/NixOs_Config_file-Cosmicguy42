import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services

// App icon from the icon theme. Loaded synchronously (the icon provider isn't
// thread-safe) but cached by URL - the launcher pre-warms the cache - and
// optionally tinted monochrome (Settings > Appearance > Monochrome icons).
Item {
    id: root

    property string icon
    property real size: 40

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: Quickshell.iconPath(root.icon, "application-x-executable")
        sourceSize: Qt.size(128, 128) // sharp up to 2x at the largest (44px) size
        asynchronous: false
        cache: true
        smooth: true
        mipmap: true
        layer.enabled: Config.get("look.monoIcons")
        layer.effect: MultiEffect {
            saturation: -1
            colorization: 0.35
            colorizationColor: Theme.fg
            brightness: Theme.dark ? 0.05 : -0.05
        }
    }
}
