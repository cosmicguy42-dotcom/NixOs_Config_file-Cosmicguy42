import QtQuick
import qs.services
import qs.components

Page {
    title: "Notifications"

    Section {
        title: "Popups"
        OptSwitch { label: "Silent mode"; sub: "Keep notifications but don't pop them up (critical ones still show)"; checked: Toggles.dnd; onToggled: on => Toggles.dnd = on }
        CSlider { label: "Popup duration"; path: "notifications.timeout"; from: 2; to: 15; suffix: " s" }
    }
    Section {
        title: "History · " + Notifs.list.length
        OptRow {
            visible: Notifs.list.length === 0
            label: "All caught up"
        }
        Repeater {
            model: Notifs.list.slice().reverse()
            OptRow {
                required property var modelData
                label: (modelData.appName ? modelData.appName + " · " : "") + modelData.summary
                sub: modelData.body.replace(/\n/g, " ")
                Icon {
                    text: "close"
                    size: 18
                    color: Theme.dim
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: modelData.dismiss() }
                }
            }
        }
    }
    OptButton { visible: Notifs.list.length > 0; text: "Clear all"; icon: "clear_all"; onClicked: Notifs.clear() }
}
