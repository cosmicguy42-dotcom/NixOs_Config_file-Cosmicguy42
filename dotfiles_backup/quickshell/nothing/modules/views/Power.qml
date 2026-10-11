import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.components

// Session actions. Destructive ones need a second click.
Row {
    id: root

    spacing: 14
    property string armed: ""

    readonly property var actions: [
        { id: "lock", icon: "lock", label: "Lock", confirm: false, run: () => Quickshell.execDetached(["loginctl", "lock-session"]) },
        { id: "sleep", icon: "bedtime", label: "Sleep", confirm: false, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { id: "logout", icon: "logout", label: "Log out", confirm: true, run: () => Hyprland.dispatch("hl.dsp.exit()") },
        { id: "reboot", icon: "restart_alt", label: "Restart", confirm: true, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { id: "off", icon: "power_settings_new", label: "Shut down", confirm: true, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
    ]

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    Repeater {
        model: root.actions
        Column {
            required property var modelData
            spacing: 8
            CircleButton {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 48
                icon: parent.modelData.icon
                active: root.armed === parent.modelData.id
                onClicked: {
                    const a = parent.modelData;
                    if (a.confirm && root.armed !== a.id) {
                        root.armed = a.id;
                        disarm.restart();
                        return;
                    }
                    Ui.close();
                    a.run();
                }
            }
            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64
                horizontalAlignment: Text.AlignHCenter
                text: root.armed === parent.modelData.id ? "Confirm" : parent.modelData.label
                color: root.armed === parent.modelData.id ? Theme.accent : Theme.dim
            }
        }
    }
}
