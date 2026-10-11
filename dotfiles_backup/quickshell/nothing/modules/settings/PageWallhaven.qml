import QtQuick
import qs.services
import qs.components

Page {
    id: page
    title: "Wallhaven"
    subtitle: "Browse wallhaven.cc (safe for work only). Setting one saves it to your wallpaper folder."

    Component.onCompleted: if (Wallhaven.results.length === 0) Wallhaven.search()

    component Chip: Rectangle {
        id: c
        property string text
        property bool on
        signal clicked
        width: ct.implicitWidth + 24
        height: 30
        radius: Theme.r(height / 2)
        color: on ? Theme.active : (cm.containsMouse ? Theme.raised : "transparent")
        border.width: on ? 0 : 1
        border.color: Theme.faint
        Caption { id: ct; anchors.centerIn: parent; text: c.text; color: c.on ? Theme.activeFg : Theme.fg; font.pixelSize: 11 }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.clicked() }
    }

    // Search
    Rectangle {
        width: parent.width
        height: 44
        radius: Theme.r(height / 2)
        color: Theme.card
        Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; text: "search"; size: 18; color: Theme.dim }
        TextInput {
            id: q
            x: 44
            width: parent.width - 60
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.mono
            font.pixelSize: 13
            color: Theme.fg
            text: Wallhaven.query
            onAccepted: { Wallhaven.query = text; Wallhaven.sorting = text.trim() ? "relevance" : "toplist"; Wallhaven.search(); }
            Caption { visible: q.text.length === 0; anchors.verticalCenter: parent.verticalCenter; text: "Search, e.g. minimal, mountains, nord · Enter"; font.pixelSize: 12 }
        }
    }

    Flow {
        width: parent.width
        spacing: 6
        Repeater {
            model: [{ id: "toplist", l: "Top" }, { id: "date_added", l: "Latest" }, { id: "views", l: "Popular" }, { id: "random", l: "Random" }]
            Chip {
                required property var modelData
                text: modelData.l
                on: Wallhaven.sorting === modelData.id
                onClicked: { Wallhaven.sorting = modelData.id; Wallhaven.search(); }
            }
        }
        Item { width: 12; height: 1 }
        Chip { text: "General"; on: Wallhaven.general; onClicked: { Wallhaven.general = !Wallhaven.general; Wallhaven.search(); } }
        Chip { text: "Anime"; on: Wallhaven.anime; onClicked: { Wallhaven.anime = !Wallhaven.anime; Wallhaven.search(); } }
        Chip { text: "People"; on: Wallhaven.people; onClicked: { Wallhaven.people = !Wallhaven.people; Wallhaven.search(); } }
    }

    Caption {
        visible: Wallhaven.error !== "" || (Wallhaven.loading && Wallhaven.results.length === 0)
        text: Wallhaven.error || "Loading…"
        color: Wallhaven.error ? Theme.error : Theme.dim
    }

    Grid {
        id: grid
        width: parent.width
        columns: 3
        spacing: 10
        readonly property real cw: (width - 20) / 3

        Repeater {
            model: Wallhaven.results
            Item {
                id: tile
                required property var modelData
                readonly property bool busy: Wallhaven.busyId === modelData.id
                width: grid.cw
                height: grid.cw * 0.62

                RoundImage {
                    anchors.fill: parent
                    radius: Theme.r(Theme.radius)
                    source: tile.modelData.thumb
                    scale: tm.containsMouse ? 1.02 : 1
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }
                // hover strip
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    height: 30
                    radius: Theme.r(height / 2)
                    color: Qt.alpha(Theme.bg, 0.75)
                    opacity: tm.containsMouse || tile.busy ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Row {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: tile.modelData.colors.slice(0, 4)
                            Rectangle { required property string modelData; width: 8; height: 8; radius: Theme.r(4); color: modelData; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                    Caption {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: tile.busy ? "Downloading…" : tile.modelData.resolution + " · Set"
                        color: Theme.fg
                        font.pixelSize: 10
                    }
                }
                MouseArea {
                    id: tm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallhaven.set(tile.modelData)
                }
            }
        }
    }

    OptButton {
        visible: Wallhaven.results.length > 0 && Wallhaven.page < Wallhaven.lastPage
        text: Wallhaven.loading ? "Loading…" : "Load more"
        icon: "expand_more"
        onClicked: Wallhaven.more()
    }
}
