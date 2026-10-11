import QtQuick
import Qt.labs.folderlistmodel
import qs.services
import qs.components

Page {
    title: "Appearance"
    subtitle: "Pick what leads: a wallpaper colour, or your own base, surface and accent."

    Section {
        title: "Wallpaper"
        Item {
            width: parent.width
            height: grid.height + 32
            GridView {
                id: grid
                x: 16
                y: 16
                width: parent.width - 32
                height: Math.min(3, Math.ceil(count / 4)) * cellHeight
                cellWidth: width / 4
                cellHeight: cellWidth * 0.62
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: FolderListModel {
                    folder: "file://" + Appearance.wallDir
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"]
                    showDirs: false
                }
                delegate: Item {
                    id: tile
                    required property string filePath
                    readonly property bool current: filePath === Appearance.wallpaper
                    width: grid.cellWidth
                    height: grid.cellHeight
                    RoundImage {
                        anchors.fill: parent
                        anchors.margins: tile.current ? 7 : 4
                        radius: Theme.radius
                        thumb: 360
                        source: "file://" + tile.filePath
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: Theme.radius
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.accent
                        visible: tile.current
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Appearance.setWallpaper(tile.filePath)
                    }
                }
            }
        }
        CText {
            label: "Folder"
            sub: "Where wallpapers are picked from"
            path: "wallpaper.dir"
            placeholder: "~/Pictures/Wallpapers"
            fieldWidth: 280
        }
        OptRow {
            label: "Random wallpaper"
            OptButton { text: "Shuffle"; icon: "shuffle"; onClicked: Appearance.randomWallpaper() }
        }
    }

    Section {
        title: "Colour"
        OptChoice {
            label: "Mode"
            options: [{ label: "Dark", value: "dark" }, { label: "Light", value: "light" }]
            current: Appearance.mode
            onPicked: v => Appearance.setMode(v)
        }
        OptChoice {
            label: "Colours from"
            sub: "The wallpaper, or three colours you pick yourself: a base, a surface and one accent"
            options: [{ label: "Wallpaper", value: "wallpaper" }, { label: "Hand-picked", value: "custom" }]
            current: Appearance.source
            onPicked: v => Appearance.setSource(v)
        }

        // --- From the wallpaper
        OptRow {
            visible: Appearance.source === "wallpaper"
            label: "Lead colour"
            sub: "Which of the wallpaper's colours becomes the accent. Auto-extraction averages; you decide what leads."
            Row {
                spacing: 8
                Repeater {
                    model: Appearance.sources
                    Rectangle {
                        required property string modelData
                        required property int index
                        readonly property bool on: Appearance.lead === index
                        width: 30
                        height: 30
                        radius: Theme.r(height / 2)
                        color: modelData
                        border.width: on ? 2 : 1
                        border.color: on ? Theme.fg : Theme.faint
                        Rectangle {
                            visible: parent.on
                            anchors.centerIn: parent
                            width: 8
                            height: 8
                            radius: Theme.r(4)
                            color: Theme.fg
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -3
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Appearance.setLead(parent.index)
                        }
                    }
                }
            }
        }
        OptSwitch {
            visible: Appearance.source === "wallpaper"
            label: "Neutral surfaces"
            sub: "Near-black (or near-white) glass instead of wallpaper-tinted surfaces, so only the accent carries colour"
            checked: Appearance.neutral
            onToggled: on => Appearance.setNeutral(on)
        }
        CSwitch {
            label: "Theme from cover art"
            sub: "While music plays, the accent follows the album's colour everywhere, then returns"
            path: "look.coverTheme"
        }
        OptChoice {
            label: "Accent tones"
            sub: "How the accent is expanded into tones"
            options: Appearance.schemes.map(s => ({ label: s.label, value: s.id }))
            current: Appearance.scheme
            onPicked: v => Appearance.setScheme(v)
        }

        // --- Hand-picked
        OptRow {
            visible: Appearance.source === "custom"
            label: "Presets"
            Row {
                spacing: 8
                Repeater {
                    model: Appearance.presets
                    Rectangle {
                        required property var modelData
                        readonly property bool on: Appearance.custom.base === modelData.base && Appearance.custom.accent === modelData.accent
                        width: pr.width + 20
                        height: 34
                        radius: Theme.r(height / 2)
                        color: modelData.base
                        border.width: on ? 2 : 1
                        border.color: on ? Theme.fg : Theme.faint
                        Row {
                            id: pr
                            anchors.centerIn: parent
                            spacing: 6
                            Rectangle { width: 10; height: 10; radius: Theme.r(5); color: parent.parent.modelData.surface; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle { width: 10; height: 10; radius: Theme.r(5); color: parent.parent.modelData.accent; anchors.verticalCenter: parent.verticalCenter }
                            Caption {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.modelData.name
                                color: parent.parent.modelData.base.charAt(1) >= "a" ? "#111111" : "#f2f2f2"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Appearance.setCustom(parent.modelData.base, parent.modelData.surface, parent.modelData.accent)
                        }
                    }
                }
            }
        }
        Repeater {
            model: Appearance.source === "custom" ? [
                { k: "base", label: "Base", sub: "Window and pill background" },
                { k: "surface", label: "Surface", sub: "Cards and tiles" },
                { k: "accent", label: "Accent", sub: "The one colour your eye lands on" }
            ] : []
            OptText {
                id: hex
                required property var modelData
                label: modelData.label
                sub: modelData.sub
                text: Appearance.custom[modelData.k] ?? ""
                placeholder: "#000000"
                fieldWidth: 150
                onAccepted: t => {
                    if (!/^#[0-9a-fA-F]{6}$/.test(t.trim()))
                        return;
                    const c = Object.assign({}, Appearance.custom);
                    c[hex.modelData.k] = t.trim();
                    Appearance.setCustom(c.base, c.surface, c.accent);
                }
                Rectangle {
                    parent: hex
                    anchors.right: parent.right
                    anchors.rightMargin: 22 + 150 + 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: Theme.r(12)
                    color: Appearance.custom[hex.modelData.k] ?? "transparent"
                    border.width: 1
                    border.color: Theme.faint
                }
            }
        }

        OptSlider {
            label: "Contrast"
            sub: "-1 softest, 1 strongest"
            from: -1
            to: 1
            step: 0.25
            decimals: 2
            value: Appearance.contrast
            onCommitted: v => Appearance.setContrast(v)
        }
        OptRow {
            label: "In use"
            sub: "Base · surface · text · accent"
            Row {
                spacing: 6
                Repeater {
                    model: ["surface_container_lowest", "surface_container_high", "on_surface", "primary"]
                    Rectangle {
                        required property string modelData
                        width: 22
                        height: 22
                        radius: Theme.r(11)
                        color: Theme.c[modelData] ?? "transparent"
                        border.width: 1
                        border.color: Theme.faint
                    }
                }
            }
        }
    }

    Section {
        title: "Shape"
        CSwitch {
            label: "Brutalist"
            sub: "No rounded corners anywhere: windows, pill, cards, buttons, launcher, lock screen. Dot-matrix dots turn into square pixels."
            path: "look.brutal"
        }
        CSlider {
            label: "Corner radius"
            sub: "One radius for every surface: windows, the pill's panels, cards, launcher, widgets, lock screen"
            path: "look.radius"
            from: 0
            to: 32
            suffix: " px"
        }
        CSlider {
            label: "Gap"
            sub: "One gap: between windows, to the screen edge, and around the pill"
            path: "look.gap"
            from: 0
            to: 24
            step: 2
            suffix: " px"
        }
        OptRow {
            label: "Preview"
            Row {
                spacing: Theme.margin
                Repeater {
                    model: 3
                    Rectangle {
                        width: 54
                        height: 38
                        radius: Theme.r(Math.min(Theme.radius, height / 2))
                        color: Theme.raised
                        border.width: 1
                        border.color: Theme.faint
                    }
                }
            }
        }
    }

    Section {
        title: "Cursor"
        OptChoice {
            label: "Theme"
            options: [
                { label: "Bibata", value: "Bibata-Modern-Classic" },
                { label: "Bibata Ice", value: "Bibata-Modern-Ice" },
                { label: "Breeze", value: "breeze_cursors" },
                { label: "Adwaita", value: "Adwaita" }
            ]
            current: Config.get("look.cursor")
            onPicked: v => Config.set("look.cursor", v)
        }
        CChoice {
            label: "Size"
            path: "look.cursorSize"
            options: [{ label: "24", value: 24 }, { label: "32", value: 32 }, { label: "48", value: 48 }]
        }
    }

    Section {
        title: "Dot matrix"
        CSwitch { label: "Bloom"; sub: "Lit dots glow like an LED panel (clock, weather glyphs, lock screen)"; path: "look.bloom" }
        CSlider {
            label: "Bloom strength"
            path: "look.bloomStrength"
            from: 0.2
            to: 1
            step: 0.05
            decimals: 2
        }
        OptRow {
            label: "Preview"
            DotText {
                text: "12:34"
                dot: 3.4
                gap: 1.4
            }
        }
    }

    Section {
        title: "Icons"
        CSwitch { label: "Accent-coloured controls"; sub: "Active toggles and buttons use the wallpaper accent instead of Nothing's white"; path: "look.accentFills" }
        CSwitch { label: "Monochrome app icons"; sub: "Tint launcher icons to match the palette, Nothing-style"; path: "look.monoIcons" }
    }

    Section {
        title: "Glass"
        CSlider {
            label: "Pill opacity"
            sub: "Lower shows more of the blur behind the pill"
            path: "pill.opacity"
            from: 0.3
            to: 1
            step: 0.02
            decimals: 2
        }
        CSwitch { label: "Pill outline"; sub: "Hairline border around the pill"; path: "pill.border" }
        HSwitch { label: "Blur"; sub: "Blur behind translucent windows, the pill and the launcher"; key: "decoration:blur:enabled" }
    }
}
