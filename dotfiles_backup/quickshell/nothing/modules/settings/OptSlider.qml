import QtQuick
import qs.services
import qs.components

// Slider row. `value` in real units; emits committed(v) on release.
OptRow {
    id: r

    property real value: 0
    property real from: 0
    property real to: 1
    property real step: 1
    property int decimals: 0
    property string suffix: ""
    property real shown: value
    signal committed(real v)

    onValueChanged: shown = value

    function snap(t) {
        const v = from + t * (to - from);
        return Math.round(v / step) * step;
    }

    Row {
        spacing: 14
        Caption {
            anchors.verticalCenter: parent.verticalCenter
            width: 58
            horizontalAlignment: Text.AlignRight
            text: r.shown.toFixed(r.decimals) + r.suffix
            color: Theme.fg
            font.pixelSize: 11
        }
        Track {
            anchors.verticalCenter: parent.verticalCenter
            width: 210
            value: (r.shown - r.from) / (r.to - r.from)
            onMoved: t => r.shown = r.snap(t)
            onCommitted: t => r.committed(r.shown)
        }
    }
}
