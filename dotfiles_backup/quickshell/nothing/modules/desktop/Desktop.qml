import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Desktop widgets: sit on the wallpaper, below windows. Positions are stored as
// fractions of the screen in config.json (widgets.<name>.x/y). In arrange mode
// (Settings > Widgets, or `ipc call shell arrange`) the layer rises above
// windows and widgets can be dragged.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property bool arranging: Ui.widgetEdit

    visible: Config.get("widgets.enabled")
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: arranging ? WlrLayer.Top : WlrLayer.Bottom
    WlrLayershell.namespace: "nothing:widgets"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Only widgets take input; the rest of the desktop stays click-through.
    mask: Region {
        item: win.arranging ? canvas : null
        Region { item: clock.visible ? clock : null }
        Region { item: weather.visible ? weather : null }
        Region { item: media.visible ? media : null }
        Region { item: battery.visible ? battery : null }
        Region { item: system.visible ? system : null }
        Region { item: calendar.visible ? calendar : null }
        Region { item: note.visible ? note : null }
    }

    Rectangle {
        id: canvas
        anchors.fill: parent
        color: win.arranging ? Qt.alpha(Theme.bg, 0.35) : "transparent"
        Behavior on color { ColorAnimation { duration: 250 } }

        Slot { id: clock; name: "clock"; ClockWidget {} }
        Slot { id: weather; name: "weather"; WeatherWidget {} }
        Slot { id: media; name: "media"; MediaWidget {} }
        Slot { id: battery; name: "battery"; BatteryWidget {} }
        Slot { id: system; name: "system"; SystemWidget {} }
        Slot { id: calendar; name: "calendar"; CalendarWidget {} }
        Slot { id: note; name: "note"; NoteWidget {} }

        // Arrange-mode bar
        Rectangle {
            visible: win.arranging
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            width: bar.width + 32
            height: 56
            radius: Theme.r(height / 2)
            color: Theme.glass
            border.width: 1
            border.color: Qt.alpha(Theme.faint, 0.6)
            Row {
                id: bar
                anchors.centerIn: parent
                spacing: 14
                Caption { anchors.verticalCenter: parent.verticalCenter; text: "Drag widgets to move them"; color: Theme.fg; font.pixelSize: 12 }
                CircleButton { size: 36; icon: "restart_alt"; onClicked: Config.set("widgets.layout", {}) }
                Rectangle {
                    width: done.implicitWidth + 32
                    height: 36
                    radius: Theme.r(height / 2)
                    color: Theme.accent
                    Label { id: done; anchors.centerIn: parent; text: "Done"; color: Theme.accentFg }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.widgetEdit = false }
                }
            }
        }
    }

    // A placed widget. Default positions live in Config.defaults.widgets.layout.
    component Slot: Item {
        id: slot

        required property string name
        default property alias content: holder.data

        readonly property var pos: Config.get("widgets.layout." + name) ?? Config.defaults.widgets.layout[name]
        property real dx: 0
        property real dy: 0

        // `available` (not `visible`, which includes our own visibility) lets a
        // widget hide itself, e.g. media with nothing playing.
        visible: Config.get("widgets.show." + name) && (holder.children[0]?.available ?? true)
        width: holder.childrenRect.width
        height: holder.childrenRect.height
        x: Math.max(0, Math.min(parent.width - width, pos.x * parent.width + (drag.active ? dx : 0)))
        y: Math.max(0, Math.min(parent.height - height, pos.y * parent.height + (drag.active ? dy : 0)))

        Item {
            id: holder
        }

        Rectangle {
            visible: win.arranging
            anchors.fill: parent
            anchors.margins: -10
            radius: Theme.r(Theme.radius + 10) // concentric with the widget
            color: drag.active ? Qt.alpha(Theme.accent, 0.08) : "transparent"
            border.width: 1.5
            border.color: drag.active ? Theme.accent : Qt.alpha(Theme.fg, 0.4)
        }

        DragHandler {
            id: drag
            enabled: win.arranging
            target: null
            onActiveTranslationChanged: {
                if (active) {
                    slot.dx = activeTranslation.x;
                    slot.dy = activeTranslation.y;
                }
            }
            onActiveChanged: {
                if (active)
                    return;
                const W = slot.parent.width, H = slot.parent.height;
                const nx = Math.max(0, Math.min(W - slot.width, slot.pos.x * W + slot.dx)) / W;
                const ny = Math.max(0, Math.min(H - slot.height, slot.pos.y * H + slot.dy)) / H;
                slot.dx = 0;
                slot.dy = 0;
                Config.set("widgets.layout." + slot.name, { x: Number(nx.toFixed(4)), y: Number(ny.toFixed(4)) });
            }
        }
    }
}
