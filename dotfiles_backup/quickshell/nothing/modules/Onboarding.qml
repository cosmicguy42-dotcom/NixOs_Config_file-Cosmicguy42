import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// First-run welcome: wallpaper, look, colour, weather, keys. Shown once
// (flag: ~/.local/state/nothing/onboarded); reopen from Settings > About or
// `qs -c nothing ipc call onboarding open`.
Scope {
    id: root

    FileView {
        id: flag
        path: Theme.stateDir + "/onboarded"
        blockLoading: true
        printErrors: false
    }
    property bool open: flag.text().trim() === ""

    function finish() {
        flag.setText("1\n");
        open = false;
    }

    IpcHandler {
        target: "onboarding"
        function open(): void { root.open = true; }
        function close(): void { root.finish(); }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nothing:onboarding"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            property int step: 0
            readonly property var steps: ["Welcome", "Wallpaper", "Look", "Colour", "Weather", "Keys", "Done"]
            readonly property real s: Math.max(0.6, Math.min(width / 1920, height / 1080))

            function next() { if (step < steps.length - 1) step++; else root.finish(); }
            function back() { if (step > 0) step--; }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.bg, 0.86)
                focus: true
                Keys.onEscapePressed: root.finish()
                Keys.onRightPressed: win.next()
                Keys.onLeftPressed: win.back()
                Keys.onReturnPressed: win.next()
            }

            // --- Card
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 760 * win.s
                height: 560 * win.s
                radius: Theme.r(Theme.radius * 1.6)
                color: Theme.glass
                border.width: 1
                border.color: Qt.alpha(Theme.faint, 0.6)
                clip: true

                Overline {
                    x: 40 * win.s
                    y: 34 * win.s
                    text: (win.step + 1) + " / " + win.steps.length + "  ·  " + win.steps[win.step]
                    font.pixelSize: 11 * win.s
                }
                Caption {
                    anchors.right: parent.right
                    anchors.rightMargin: 40 * win.s
                    y: 34 * win.s
                    text: "Skip"
                    font.pixelSize: 12 * win.s
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.finish() }
                }

                // Pages
                Item {
                    id: pages
                    x: 40 * win.s
                    y: 80 * win.s
                    width: parent.width - 80 * win.s
                    height: parent.height - 170 * win.s

                    component Pg: Item {
                        required property int index
                        anchors.fill: parent
                        opacity: win.step === index ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 260 } }
                        transform: Translate {
                            x: (win.step === parent.index ? 0 : win.step > parent.index ? -30 : 30) * win.s
                            Behavior on x { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }
                        }
                    }
                    component Big: Heading { font.pixelSize: 54 * win.s; wrapMode: Text.Wrap; width: pages.width }
                    component Body: Label { font.pixelSize: 13 * win.s; color: Theme.dim; wrapMode: Text.Wrap; width: pages.width; elide: Text.ElideNone }
                    component Choice: Rectangle {
                        id: ch
                        property string text
                        property string sub: ""
                        property bool on: false
                        signal clicked
                        width: 200 * win.s
                        height: 96 * win.s
                        radius: Theme.r(Theme.radius)
                        color: on ? Theme.active : (cm.containsMouse ? Theme.raised : Theme.card)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Column {
                            x: 18 * win.s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Label { text: ch.text; font.pixelSize: 15 * win.s; color: ch.on ? Theme.activeFg : Theme.fg }
                            Caption { text: ch.sub; visible: text !== ""; font.pixelSize: 10 * win.s; color: ch.on ? Qt.alpha(Theme.activeFg, 0.7) : Theme.dim }
                        }
                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ch.clicked() }
                    }

                    // 0 Welcome
                    Pg {
                        index: 0
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 26 * win.s
                            DotText { text: "HELLO"; dot: 11 * win.s; gap: 4 * win.s; offOpacity: 0.07 }
                            Big { text: "Welcome to Everything." }
                            Body { text: "A quiet Hyprland desktop built around one pill at the top of the screen. It grows into whatever you open: launcher, quick settings, media, weather, capture. Let's set it up - it takes a minute." }
                        }
                    }

                    // 1 Wallpaper
                    Pg {
                        index: 1
                        Column {
                            width: parent.width
                            spacing: 18 * win.s
                            Big { text: "Pick a wallpaper." }
                            Body { text: "Every colour on screen is taken from it. More in Settings › Wallhaven." }
                            Grid {
                                id: wg
                                columns: 4
                                spacing: 10 * win.s
                                readonly property real cw: (pages.width - 30 * win.s) / 4
                                Repeater {
                                    model: FolderListModel {
                                        folder: "file://" + Appearance.wallDir
                                        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                                        showDirs: false
                                    }
                                    delegate: Item {
                                        id: wt
                                        required property string filePath
                                        required property int index
                                        visible: index < 8
                                        width: wg.cw
                                        height: wg.cw * 0.6
                                        RoundImage { anchors.fill: parent; radius: Theme.r(Theme.radius * 0.7); thumb: 320; source: "file://" + wt.filePath }
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.r(Theme.radius * 0.7)
                                            color: "transparent"
                                            border.width: 2
                                            border.color: Theme.fg
                                            visible: Appearance.wallpaper === wt.filePath
                                        }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Appearance.setWallpaper(wt.filePath) }
                                    }
                                }
                            }
                        }
                    }

                    // 2 Look
                    Pg {
                        index: 2
                        Column {
                            spacing: 18 * win.s
                            Big { text: "Choose a look." }
                            Row {
                                spacing: 12 * win.s
                                Choice { text: "Dark"; sub: "Black glass"; on: Appearance.mode === "dark"; onClicked: Appearance.setMode("dark") }
                                Choice { text: "Light"; sub: "White glass"; on: Appearance.mode === "light"; onClicked: Appearance.setMode("light") }
                            }
                            Row {
                                spacing: 12 * win.s
                                Choice { text: "Rounded"; sub: "Soft corners"; on: !Theme.brutal; onClicked: Config.set("look.brutal", false) }
                                Choice { text: "Brutalist"; sub: "No curves at all"; on: Theme.brutal; onClicked: Config.set("look.brutal", true) }
                                Choice { text: "Bloom"; sub: "Glowing dot matrix"; on: Config.get("look.bloom"); onClicked: Config.set("look.bloom", !Config.get("look.bloom")) }
                            }
                        }
                    }

                    // 3 Colour
                    Pg {
                        index: 3
                        Column {
                            spacing: 18 * win.s
                            Big { text: "What leads?" }
                            Body { text: "One accent colour, used only for small signals: today, weekends, charging, recording." }
                            Row {
                                spacing: 12 * win.s
                                Choice { text: "Wallpaper"; sub: "Accent from the image"; on: Appearance.source === "wallpaper"; onClicked: Appearance.setSource("wallpaper") }
                                Choice { text: "Nothing"; sub: "Black and red"; on: Appearance.source === "custom" && Appearance.custom.accent === "#d71921"; onClicked: Appearance.setCustom("#000000", "#141414", "#d71921") }
                                Choice { text: "Cover art"; sub: "Follows your music"; on: Config.get("look.coverTheme"); onClicked: Config.set("look.coverTheme", !Config.get("look.coverTheme")) }
                            }
                            Row {
                                visible: Appearance.source === "wallpaper"
                                spacing: 10 * win.s
                                Caption { anchors.verticalCenter: parent.verticalCenter; text: "Lead colour"; font.pixelSize: 11 * win.s }
                                Repeater {
                                    model: Appearance.sources
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        width: 30 * win.s
                                        height: width
                                        radius: Theme.r(width / 2)
                                        color: modelData
                                        border.width: Appearance.lead === index ? 2 : 1
                                        border.color: Appearance.lead === index ? Theme.fg : Theme.faint
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Appearance.setLead(parent.index) }
                                    }
                                }
                            }
                        }
                    }

                    // 4 Weather
                    Pg {
                        index: 4
                        Column {
                            spacing: 18 * win.s
                            Big { text: "Where are you?" }
                            Body { text: "For the weather in the pill, on the lock screen and on the desktop. Leave it empty to locate you automatically." }
                            Rectangle {
                                width: 420 * win.s
                                height: 52 * win.s
                                radius: Theme.r(height / 2)
                                color: Theme.card
                                border.width: city.activeFocus ? 1 : 0
                                border.color: Theme.fg
                                TextInput {
                                    id: city
                                    anchors.fill: parent
                                    anchors.leftMargin: 20 * win.s
                                    anchors.rightMargin: 20 * win.s
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.mono
                                    font.pixelSize: 14 * win.s
                                    color: Theme.fg
                                    text: Config.weatherLocation
                                    onEditingFinished: Config.set("weather.location", text.trim())
                                    Caption { anchors.verticalCenter: parent.verticalCenter; visible: city.text === ""; text: "City, or empty for automatic"; font.pixelSize: 12 * win.s }
                                }
                            }
                            Row {
                                spacing: 12 * win.s
                                Choice { text: "°C"; sub: "km/h"; height: 70 * win.s; on: !Config.imperial; onClicked: Config.set("weather.units", "metric") }
                                Choice { text: "°F"; sub: "mph"; height: 70 * win.s; on: Config.imperial; onClicked: Config.set("weather.units", "imperial") }
                            }
                            Caption {
                                visible: Forecast.ready
                                text: Forecast.location + " · " + Forecast.temp + "°" + Forecast.unit + " · " + Forecast.desc
                                color: Theme.fg
                                font.pixelSize: 12 * win.s
                            }
                        }
                    }

                    // 5 Keys
                    Pg {
                        index: 5
                        Column {
                            spacing: 16 * win.s
                            Big { text: "A few keys." }
                            Grid {
                                columns: 2
                                columnSpacing: 40 * win.s
                                rowSpacing: 14 * win.s
                                Repeater {
                                    model: [
                                        [["Super"], "App launcher (tap)"], [["Super", "/"], "All keys"],
                                        [["Super", "I"], "Settings"], [["Super", "N"], "Quick settings"],
                                        [["Super", "Print"], "Screenshot / record"], [["Super", "Return"], "Terminal"],
                                        [["Super", "Q"], "Close window"], [["Super", "L"], "Lock"]
                                    ]
                                    Row {
                                        required property var modelData
                                        spacing: 6 * win.s
                                        width: (pages.width - 40 * win.s) / 2
                                        Repeater {
                                            model: parent.modelData[0]
                                            Rectangle {
                                                required property string modelData
                                                width: kc.implicitWidth + 16 * win.s
                                                height: 30 * win.s
                                                radius: Theme.r(8 * win.s)
                                                color: Theme.raised
                                                border.width: 1
                                                border.color: Theme.faint
                                                Caption { id: kc; anchors.centerIn: parent; text: parent.modelData; color: Theme.fg; font.pixelSize: 11 * win.s }
                                            }
                                        }
                                        Label { anchors.verticalCenter: parent.verticalCenter; leftPadding: 8 * win.s; text: parent.modelData[1]; font.pixelSize: 13 * win.s }
                                    }
                                }
                            }
                            Body { text: "Click anything in the pill to open it. Right-click or Esc closes it." }
                        }
                    }

                    // 6 Done
                    Pg {
                        index: 6
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 24 * win.s
                            DotText { text: "READY"; dot: 11 * win.s; gap: 4 * win.s; offOpacity: 0.07; color: Theme.accent }
                            Big { text: "You're set." }
                            Body { text: "Everything else lives in Settings (Super + I). Your dots update themselves from GitHub." }
                        }
                    }
                }

                // --- Footer: progress dots + buttons
                Row {
                    x: 40 * win.s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 44 * win.s
                    spacing: 6 * win.s
                    Repeater {
                        model: win.steps.length
                        Rectangle {
                            required property int index
                            width: (index === win.step ? 22 : 7) * win.s
                            height: 7 * win.s
                            radius: Theme.r(height / 2)
                            color: index <= win.step ? Theme.fg : Theme.faint
                            Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: win.step = parent.index }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 40 * win.s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 32 * win.s
                    spacing: 10 * win.s
                    CircleButton { visible: win.step > 0; size: 48 * win.s; icon: "arrow_back"; onClicked: win.back() }
                    Rectangle {
                        width: nl.implicitWidth + 48 * win.s
                        height: 48 * win.s
                        radius: Theme.r(height / 2)
                        color: Theme.active
                        scale: nm.pressed ? 0.96 : 1
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Label {
                            id: nl
                            anchors.centerIn: parent
                            text: win.step === 0 ? "Get started" : win.step === win.steps.length - 1 ? "Finish" : "Next"
                            font.pixelSize: 14 * win.s
                            color: Theme.activeFg
                        }
                        MouseArea { id: nm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.next() }
                    }
                }
            }
        }
    }
}
