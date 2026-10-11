import QtQuick
import qs.services
import qs.components

Row {
    height: Theme.barHeight
    spacing: 12

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: Ui.osdKind === "brightness" ? "light_mode" : Ui.osdMuted ? "volume_off" : Ui.osdValue < 0.33 ? "volume_mute" : Ui.osdValue < 0.66 ? "volume_down" : "volume_up"
        size: 18
    }
    Track {
        anchors.verticalCenter: parent.verticalCenter
        width: 150
        interactive: false
        value: Ui.osdMuted ? 0 : Ui.osdValue
    }
    Caption {
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        horizontalAlignment: Text.AlignRight
        text: Ui.osdMuted ? "—" : Math.round(Ui.osdValue * 100)
        color: Theme.fg
    }
}
