import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// App launcher inside the island. Always loaded, so icons are already
// decoded when it opens.
//   empty query  -> grid, most used first
//   text         -> ranked list (+ calculator / command / web search)
//   "= expr"     -> qalculate (units, currency, …)   "> cmd" -> run command
Column {
    id: root

    width: 620
    spacing: 14

    property string query: ""
    property int index: 0
    readonly property bool grid: query.trim() === ""
    readonly property int cols: 6

    readonly property string calc: {
        const q = query.trim();
        if (q.startsWith("="))
            return qalc.result;
        if (!/^[\d\s.+\-*/%^()]+$/.test(q) || !/\d/.test(q) || !/[+\-*/%^]/.test(q))
            return "";
        try {
            const v = Function('"use strict"; return (' + q.replace(/\^/g, "**") + ")")();
            return typeof v === "number" && isFinite(v) ? String(Number(v.toFixed(10))) : "";
        } catch (e) {
            return "";
        }
    }
    readonly property var results: {
        if (grid)
            return Apps.byUse.map(a => ({ type: "app", app: a }));
        const q = query.trim();
        const out = [];
        if (calc !== "")
            out.push({ type: "calc", title: calc, sub: "= " + q.replace(/^=\s*/, "") + "  ·  Enter to copy" });
        if (q.startsWith(">") && q.length > 1)
            out.push({ type: "run", title: q.slice(1).trim(), sub: "Run command" });
        if (!q.startsWith("=") && !q.startsWith(">"))
            for (const a of Apps.search(q).slice(0, 30))
                out.push({ type: "app", app: a });
        if (!q.startsWith(">") && !q.startsWith("="))
            out.push({ type: "web", title: q, sub: "Search the web" });
        return out;
    }

    function reset() {
        field.text = "";
        index = 0;
        field.forceActiveFocus();
        grid_.positionViewAtBeginning();
    }
    Connections {
        target: Ui
        function onViewChanged() {
            if (Ui.view === "launcher")
                root.reset();
        }
    }
    onQueryChanged: {
        index = 0;
        if (query.trim().startsWith("="))
            qalcDebounce.restart();
    }

    function move(d) {
        index = Math.max(0, Math.min(results.length - 1, index + d));
    }
    function activate(i, action) {
        const r = results[i];
        if (!r)
            return;
        Ui.close();
        if (r.type === "app")
            Apps.launch(r.app, action);
        else if (r.type === "calc")
            Quickshell.execDetached(["wl-copy", r.title]);
        else if (r.type === "run")
            Quickshell.execDetached(["sh", "-c", r.title]);
        else if (r.type === "web")
            Qt.openUrlExternally("https://duckduckgo.com/?q=" + encodeURIComponent(r.title));
    }

    // qalculate for "= …" queries (debounced, async)
    Timer {
        id: qalcDebounce
        interval: 220
        onTriggered: {
            const e = root.query.trim().replace(/^=\s*/, "");
            qalc.result = "";
            if (e) {
                qalc.command = ["qalc", "-t", e];
                qalc.running = true;
            }
        }
    }
    Process {
        id: qalc
        property string result: ""
        stdout: StdioCollector {
            onStreamFinished: qalc.result = text.trim()
        }
    }

    // Warm the icon cache a few icons at a time after startup, so the launcher
    // opens with every icon already decoded and startup never stalls.
    Item {
        visible: false
        Repeater {
            model: warm.count
            Image {
                required property int index
                source: Quickshell.iconPath(Apps.all[index]?.icon ?? "", "application-x-executable")
                sourceSize: Qt.size(128, 128) // must match AppIcon for cache hits
                cache: true
            }
        }
        Timer {
            id: warm
            property int count: 0
            interval: 40
            running: count < Apps.all.length
            repeat: true
            onTriggered: count = Math.min(Apps.all.length, count + 8)
        }
    }

    // --- Search field
    Rectangle {
        width: parent.width
        height: 52
        radius: Theme.r(height / 2)
        color: Theme.card
        border.width: 1
        border.color: field.activeFocus ? Qt.alpha(Theme.fg, 0.2) : "transparent"

        Icon {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            size: 20
            color: Theme.dim
        }
        TextInput {
            id: field
            x: 50
            width: parent.width - 50 - 110
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.mono
            font.pixelSize: 15
            color: Theme.fg
            selectionColor: Theme.accent
            clip: true
            onTextChanged: root.query = text
            Keys.onEscapePressed: Ui.close()
            Keys.onReturnPressed: root.activate(root.index)
            Keys.onEnterPressed: root.activate(root.index)
            Keys.onDownPressed: root.move(root.grid ? root.cols : 1)
            Keys.onUpPressed: root.move(root.grid ? -root.cols : -1)
            Keys.onTabPressed: root.move(1)
            Keys.onBacktabPressed: root.move(-1)
            Keys.onPressed: e => {
                if (root.grid && e.key === Qt.Key_Right) { root.move(1); e.accepted = true; }
                else if (root.grid && e.key === Qt.Key_Left) { root.move(-1); e.accepted = true; }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_J) { root.move(1); e.accepted = true; }
                else if (e.modifiers & Qt.ControlModifier && e.key === Qt.Key_K) { root.move(-1); e.accepted = true; }
            }
            Caption {
                anchors.verticalCenter: parent.verticalCenter
                visible: field.text.length === 0
                text: "Search apps · = calculate · > run"
                font.pixelSize: 13
            }
        }
        Caption {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: root.grid ? Apps.all.length + " apps" : (root.results.length ? root.results.length + " results" : "")
        }
    }

    // --- Grid (empty query)
    GridView {
        id: grid_
        visible: root.grid
        width: parent.width
        height: visible ? cellHeight * 3 : 0
        cellWidth: width / root.cols
        cellHeight: 104
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Apps.byUse
        currentIndex: root.grid ? root.index : -1
        highlightFollowsCurrentItem: false
        onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)
        cacheBuffer: 400

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool current: root.grid && root.index === index
            width: grid_.cellWidth
            height: grid_.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: Theme.radius
                color: cell.current ? Theme.card : (m.containsMouse ? Qt.alpha(Theme.card, 0.6) : "transparent")
                border.width: cell.current ? 1 : 0
                border.color: Qt.alpha(Theme.fg, 0.25)
            }
            Column {
                anchors.centerIn: parent
                spacing: 8
                AppIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon: cell.modelData.icon
                    size: 44
                    scale: m.pressed ? 0.9 : 1
                    Behavior on scale { NumberAnimation { duration: 120 } }
                }
                Caption {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: grid_.cellWidth - 16
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: cell.modelData.name
                    color: cell.current ? Theme.fg : Theme.dim
                }
            }
            MouseArea {
                id: m
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activate(cell.index)
                onEntered: root.index = cell.index
            }
        }
    }

    // --- Ranked list
    ListView {
        id: list
        visible: !root.grid
        width: parent.width
        height: visible ? Math.min(root.results.length, 7) * 56 : 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results
        currentIndex: root.grid ? -1 : root.index
        highlightMoveDuration: 0
        Behavior on height { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: !root.grid && root.index === index
            readonly property var app: modelData.app ?? null
            width: list.width
            height: 56

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                radius: Theme.radius
                color: row.current ? Theme.card : (rm.containsMouse ? Qt.alpha(Theme.card, 0.5) : "transparent")
            }
            Item {
                id: lead
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                AppIcon {
                    visible: row.app !== null
                    anchors.fill: parent
                    icon: row.app?.icon ?? ""
                    size: 34
                }
                Icon {
                    visible: row.app === null
                    anchors.centerIn: parent
                    text: row.modelData.type === "calc" ? "calculate" : row.modelData.type === "run" ? "terminal" : "travel_explore"
                    size: 22
                    color: Theme.accent
                }
            }
            Column {
                x: 62
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 62 - actions.width - 30
                spacing: 1
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.app ? row.app.name : row.modelData.title
                    font.family: row.modelData.type === "calc" ? Theme.serif : Theme.mono
                    font.pixelSize: row.modelData.type === "calc" ? 24 : 13
                    color: Theme.fg
                }
                Caption {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text !== ""
                    text: row.app ? (row.app.genericName || row.app.comment || "") : row.modelData.sub
                }
            }
            MouseArea {
                id: rm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activate(row.index)
                onEntered: root.index = row.index
            }
            // Desktop actions (e.g. "New private window") for the selected app
            Row {
                id: actions
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Repeater {
                    model: row.current && row.app ? row.app.actions.slice(0, 2) : []
                    Rectangle {
                        required property var modelData
                        width: at.implicitWidth + 20
                        height: 26
                        radius: Theme.r(13)
                        color: am.containsMouse ? Theme.raised : "transparent"
                        border.width: 1
                        border.color: Theme.faint
                        Caption { id: at; anchors.centerIn: parent; text: parent.modelData.name; color: Theme.fg }
                        MouseArea {
                            id: am
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activate(row.index, parent.modelData)
                        }
                    }
                }
                Caption {
                    visible: row.current
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↵"
                    color: Theme.accent
                    font.pixelSize: 14
                }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 18
        Repeater {
            model: root.grid ? ["↵ open", "← → ↑ ↓ move", "esc close"] : ["↵ open", "↑ ↓ / tab move", "esc close"]
            Caption {
                required property string modelData
                text: modelData
                color: Theme.faint
            }
        }
    }
}
