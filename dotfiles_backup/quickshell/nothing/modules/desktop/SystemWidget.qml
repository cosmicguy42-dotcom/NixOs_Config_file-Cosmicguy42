import QtQuick
import qs.services
import qs.components

// CPU / memory / disk as dot bars.
Glass {
    width: 340
    height: 190
    Component.onCompleted: Sys.active = true
    Component.onDestruction: Sys.active = false

    component Meter: Row {
        id: m
        property string label
        property real value
        property string detail
        spacing: 14
        Caption { width: 44; anchors.verticalCenter: parent.verticalCenter; text: m.label; color: Theme.fg }
        DotMatrix {
            anchors.verticalCenter: parent.verticalCenter
            rows: [Array.from({ length: 18 }, (_, i) => i < Math.round(m.value * 18) ? "#" : ".").join("")]
            dot: 7
            gap: 4
            color: m.value > 0.85 ? Theme.error : Theme.fg
            offOpacity: 0.12
        }
        Heading { anchors.verticalCenter: parent.verticalCenter; text: Math.round(m.value * 100) + "%"; font.pixelSize: 22; width: 50 }
    }

    Column {
        anchors.centerIn: parent
        spacing: 14
        Meter { label: "CPU"; value: Sys.cpu }
        Meter { label: "RAM"; value: Sys.mem }
        Meter { label: "Disk"; value: Sys.disk }
        Caption {
            text: Sys.memText + "  ·  " + (Sys.temp > 0 ? Math.round(Sys.temp) + "°C" : "")
        }
    }
}
