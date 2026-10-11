import QtQuick
import qs.services

// Material Symbols glyph, thin weight to match the line-art Nothing look.
Text {
    property real size: 18
    property bool filled: false

    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "wght": 300, "FILL": filled ? 1 : 0, "opsz": 24 })
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
