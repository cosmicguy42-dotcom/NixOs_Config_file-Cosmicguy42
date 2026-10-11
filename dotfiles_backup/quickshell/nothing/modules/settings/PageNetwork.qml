import QtQuick
import qs.services
import qs.components
import qs.modules.views

Page {
    title: "Network"
    subtitle: "Wi-Fi via NetworkManager, Bluetooth via BlueZ."

    Networks {
        embedded: true
        width: parent.width
    }
    Devices {
        embedded: true
        width: parent.width
    }
}
