import QtQuick
import QtQuick.Effects
import qs.services

// Soft glow around lit dots, like light bleeding from an LED matrix.
// Used as a layer.effect by DotMatrix / DotText; toggled in
// Settings > Appearance > Dot matrix.
MultiEffect {
    property color glow: Theme.fg
    property real size: 12

    shadowEnabled: true
    shadowColor: glow
    shadowBlur: 1
    shadowOpacity: Config.get("look.bloomStrength")
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    shadowScale: 1.04
    blurMax: size
    autoPaddingEnabled: true
}
