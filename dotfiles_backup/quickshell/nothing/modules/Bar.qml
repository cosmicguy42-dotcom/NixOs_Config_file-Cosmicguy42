import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components
import qs.modules.views

// Top layer holding the island. The window is tall enough for any expanded
// view, but only the pill itself takes input (mask) or reserves space.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property bool here: Hyprland.focusedMonitor?.name === modelData.name
    readonly property string mode: {
        if (Agent.active && here) return "auth";
        if (Ui.view !== "" && here) return Ui.view;
        if (Ui.popup !== "" && here) return Ui.popup;
        return "compact";
    }
    readonly property bool expanded: mode !== "compact" && mode !== "osd" && mode !== "notif"

    visible: Ui.barVisible
    anchors { top: true; left: true; right: true }
    implicitHeight: 820
    exclusiveZone: Theme.margin + Theme.barHeight
    color: "transparent"
    mask: Region { item: island }

    WlrLayershell.namespace: "nothing:bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: mode === "auth" ? WlrKeyboardFocus.Exclusive
        : expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Clicking anywhere else collapses the island.
    HyprlandFocusGrab {
        windows: [win]
        active: win.expanded && win.mode !== "auth"
        onCleared: Ui.close()
    }

    Rectangle {
        id: island

        readonly property Item current: {
            for (let i = 0; i < slots.children.length; i++)
                if (slots.children[i].name === win.mode)
                    return slots.children[i];
            return compact;
        }
        readonly property real padX: win.mode === "compact" || win.mode === "osd" || win.mode === "notif" ? 18 : 22
        readonly property real padY: win.expanded ? 20 : 0

        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.margin
        width: current.implicitWidth + padX * 2
        height: Math.max(Theme.barHeight, current.implicitHeight + padY * 2)
        radius: Theme.r(Math.min(height / 2, Theme.radius))
        color: Theme.glass
        border.width: Config.get("pill.border") ? 1 : 0
        border.color: Qt.alpha(Theme.faint, 0.5)
        clip: true

        Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }
        Behavior on height { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }
        Behavior on radius { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }

        focus: true
        Keys.onEscapePressed: Ui.close()

        // Right-click on the pill always collapses it.
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: Ui.close()
        }

        Item {
            id: slots
            anchors.fill: parent

            Slot { id: compact; name: "compact"; Compact { screen: win.modelData } }
            Slot { name: "osd"; Osd {} }
            Slot { name: "notif"; NotifPopup {} }
            Slot { name: "calendar"; lazy: true; Calendar {} }
            Slot { name: "media"; lazy: true; Media {} }
            Slot { name: "control"; lazy: true; Control {} }
            Slot { name: "wallpaper"; lazy: true; Wallpapers {} }
            Slot { name: "power"; lazy: true; Power {} }
            Slot { name: "weather"; lazy: true; Weather {} }
            Slot { name: "wifi"; lazy: true; Networks {} }
            Slot { name: "bluetooth"; lazy: true; Devices {} }
            Slot { name: "tray"; lazy: true; TrayMenu {} }
            Slot { name: "capture"; lazy: true; Capture {} }
            Slot { name: "launcher"; Launcher {} } // not lazy: icons stay warm
            Slot {
                name: "auth"
                lazy: true
                Auth { flow: Agent.flow }
            }
        }
    }

    // A view inside the island. Only the current one is visible; lazy views
    // are only instantiated while shown (plus their fade-out).
    component Slot: Item {
        id: slot

        required property string name
        property bool lazy: false
        default property Component content
        readonly property bool shown: win.mode === name

        implicitWidth: loader.item?.implicitWidth ?? loader.item?.width ?? 0
        implicitHeight: loader.item?.implicitHeight ?? loader.item?.height ?? 0
        width: implicitWidth
        height: implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        y: island.padY
        opacity: shown ? 1 : 0
        visible: opacity > 0
        scale: shown ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: slot.shown ? 320 : 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }

        Loader {
            id: loader
            active: !slot.lazy || slot.shown || slot.visible
            sourceComponent: slot.content
        }
    }
}
