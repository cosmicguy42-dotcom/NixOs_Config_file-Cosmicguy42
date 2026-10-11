import QtQuick
import qs.components

OptRow {
    id: r
    property bool checked: false
    signal toggled(bool on)
    Switch {
        checked: r.checked
        onToggled: on => r.toggled(on)
    }
}
