import QtQuick
import Quickshell
import qs.services
import qs.components

// Every Hyprland bind, what it does, and an editor to change keys/actions.
Page {
    id: page
    title: "Keybinds"
    subtitle: "Click a bind to change its keys or what it does. Changes apply instantly; edits are saved in keybinds.json."

    property string query: ""
    property bool showHidden: false

    readonly property var visibleBinds: Binds.all.filter(b => b.submap === "" && (page.showHidden || (!b.mouse && !/code:|mouse/.test(b.combo))))
        .filter(b => {
            if (!page.query) return true;
            const q = page.query.toLowerCase();
            return (Binds.titleOf(b) + " " + Binds.explain(b) + " " + b.combo).toLowerCase().includes(q);
        })
    readonly property var groups: {
        const g = {};
        for (const b of visibleBinds)
            (g[Binds.categoryOf(b)] = g[Binds.categoryOf(b)] ?? []).push(b);
        const order = ["Custom", "App", "Shell", "Window", "Workspace", "Media", "Utilities", "Screen", "Session"];
        return Object.keys(g).sort((a, b) => ((order.indexOf(a) + 1) || 99) - ((order.indexOf(b) + 1) || 99) || a.localeCompare(b))
            .map(k => ({ name: k, binds: g[k].sort((x, y) => Binds.titleOf(x).localeCompare(Binds.titleOf(y))) }));
    }
    readonly property var disabled: Binds.custom.filter(c => c.action.type === "off")

    // ---------------- Editor state
    property bool editing: false
    property bool isNew: false
    property string eUid: ""
    property string eReplaces: ""
    property string eCombo: ""
    property string eOrigId: ""
    property string eCurrent: ""   // explanation of the bind being edited
    property bool eCanKeep: false
    property string eType: "keep"   // keep | app | command | shell | window | media | system | workspace | off
    property string eValue: ""
    property string eLua: ""
    property string eLabel: ""
    property string eKeepLua: ""
    property string eDesc: ""
    property string eWsMode: "goto"
    property string appQuery: ""

    readonly property var conflictWith: eCombo ? Binds.conflict(eCombo, eOrigId) : null
    readonly property bool valid: eCombo !== "" && (eType === "off" || eType === "keep" && eCanKeep
        || eType === "app" && eValue !== "" || eType === "command" && eValue.trim() !== ""
        || eType === "workspace" && eValue !== "" || ["shell", "window", "media", "system"].includes(eType) && eLua !== "")

    function toLua(v) {
        if (typeof v === "string") return Binds.luaString(v);
        if (typeof v === "number" || typeof v === "boolean") return String(v);
        if (Array.isArray(v)) return "{ " + v.map(toLua).join(", ") + " }";
        if (v && typeof v === "object")
            return "{ " + Object.keys(v).map(k => k.replace(/-/g, "_") + " = " + toLua(v[k])).join(", ") + " }";
        return "nil";
    }
    function newUid() { return Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36); }

    function startNew() {
        isNew = true;
        eUid = newUid();
        eReplaces = "";
        eCombo = "";
        eOrigId = "";
        eCurrent = "";
        eCanKeep = false;
        eType = "app";
        eValue = eLua = eLabel = eDesc = appQuery = "";
        editing = true;
        page.contentY = 0;
    }
    function startEdit(b) {
        const o = Binds.overrideFor(b);
        isNew = false;
        eOrigId = b.id;
        eCurrent = Binds.explain(b);
        eCanKeep = b.kind === "dsp";
        eKeepLua = b.kind === "dsp" ? "hl.dsp." + b.dsp + "(" + (b.args ?? []).map(toLua).join(", ") + ")" : "";
        appQuery = "";
        if (o) {
            eUid = o.uid;
            eReplaces = o.replaces ?? "";
            eCombo = o.combo;
            eType = o.action.type;
            eValue = o.action.value ?? "";
            eLua = o.action.lua ?? "";
            eLabel = o.action.label ?? "";
            eDesc = o.description ?? "";
            if (eType === "goto" || eType === "send") { eWsMode = eType; eType = "workspace"; }
            if (eType === "lua") { eType = "keep"; eKeepLua = eLua; eCanKeep = true; }
        } else {
            eUid = newUid();
            eReplaces = b.combo;
            eCombo = b.combo;
            eType = eCanKeep ? "keep" : "app";
            eValue = eLua = eLabel = "";
            eDesc = b.description ?? "";
        }
        editing = true;
        page.contentY = 0;
    }
    function save() {
        let type = eType, lua = eLua;
        if (type === "keep") { type = "lua"; lua = eKeepLua; }
        if (type === "workspace") type = eWsMode;
        let replaces = eReplaces;
        // A new bind on a combo that's already taken replaces the old one.
        if (!replaces && conflictWith)
            replaces = conflictWith.combo;
        Binds.save({
            uid: eUid,
            replaces: replaces,
            combo: eCombo,
            action: { type: type, value: eValue, lua: lua, label: eLabel },
            description: eDesc
        });
        Binds.stopCapture();
        editing = false;
    }
    function cancel() {
        Binds.stopCapture();
        editing = false;
    }
    Component.onDestruction: Binds.stopCapture()

    // ---------------- Toolbar
    Row {
        width: parent.width
        spacing: 10
        Rectangle {
            width: parent.width - add.width - hidden.width - 20
            height: 42
            radius: Theme.r(21)
            color: Theme.card
            Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; text: "search"; size: 18; color: Theme.dim }
            TextInput {
                id: search
                x: 44
                width: parent.width - 60
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.mono
                font.pixelSize: 13
                color: Theme.fg
                onTextChanged: page.query = text
                Caption { visible: search.text.length === 0; text: "Search " + Binds.all.length + " binds"; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 12 }
            }
        }
        OptButton { id: add; anchors.verticalCenter: parent.verticalCenter; text: "Add keybind"; icon: "add"; accent: true; onClicked: page.startNew() }
        OptButton { id: hidden; anchors.verticalCenter: parent.verticalCenter; text: page.showHidden ? "Hide extras" : "Show extras"; icon: "visibility"; onClicked: page.showHidden = !page.showHidden }
    }

    // ---------------- Editor
    Rectangle {
        visible: page.editing
        width: parent.width
        height: editor.height + 44
        radius: Theme.radius
        color: Theme.card
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.5)

        Column {
            id: editor
            x: 22
            y: 22
            width: parent.width - 44
            spacing: 18

            Column {
                spacing: 4
                Heading { text: page.isNew ? "New keybind" : "Edit keybind"; font.pixelSize: 30 }
                Caption { visible: page.eCurrent !== ""; text: "Currently: " + page.eCurrent; width: editor.width; wrapMode: Text.Wrap }
            }

            // Keys
            Column {
                width: parent.width
                spacing: 8
                Caption { text: "Keys" ; color: Theme.accent; font.capitalization: Font.AllUppercase; font.letterSpacing: 2 }
                Rectangle {
                    id: capture
                    width: parent.width
                    height: 52
                    radius: Theme.r(height / 2)
                    color: Binds.capturing ? Qt.alpha(Theme.accent, 0.15) : Theme.raised
                    border.width: 1
                    border.color: Binds.capturing ? Theme.accent : Theme.faint
                    focus: Binds.capturing

                    Row {
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        visible: page.eCombo !== "" && !Binds.capturing
                        Repeater {
                            model: Binds.keysOf(page.eCombo)
                            KeyChip { required property string modelData; text: modelData }
                        }
                    }
                    Caption {
                        x: 18
                        anchors.verticalCenter: parent.verticalCenter
                        visible: page.eCombo === "" || Binds.capturing
                        text: Binds.capturing ? "Press the new key combo… (Esc cancels)" : "Click to record keys"
                        color: Binds.capturing ? Theme.accent : Theme.dim
                        font.pixelSize: 12
                    }
                    Caption {
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: Binds.capturing ? "" : "Record"
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Binds.startCapture();
                            capture.forceActiveFocus();
                        }
                    }
                    Keys.onPressed: e => {
                        if (!Binds.capturing)
                            return;
                        e.accepted = true;
                        if (e.key === Qt.Key_Escape && e.modifiers === Qt.NoModifier) {
                            Binds.stopCapture();
                            return;
                        }
                        const c = Binds.comboFromEvent(e);
                        if (c) {
                            page.eCombo = c;
                            Binds.stopCapture();
                        }
                    }
                }
                Caption {
                    visible: page.conflictWith !== null
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.error
                    text: page.conflictWith ? "Already used by “" + Binds.titleOf(page.conflictWith) + "” — saving replaces it." : ""
                }
            }

            // Action
            Column {
                width: parent.width
                spacing: 10
                Caption { text: "Action"; color: Theme.accent; font.capitalization: Font.AllUppercase; font.letterSpacing: 2 }
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: [
                            { id: "keep", label: "Keep current" }, { id: "app", label: "Open app" }, { id: "command", label: "Command" },
                            { id: "shell", label: "Shell" }, { id: "window", label: "Window" }, { id: "workspace", label: "Workspace" },
                            { id: "media", label: "Media" }, { id: "system", label: "System" }, { id: "off", label: "Disable" }
                        ].filter(t => t.id !== "keep" || page.eCanKeep)
                        Chip {
                            required property var modelData
                            text: modelData.label
                            on: page.eType === modelData.id
                            onClicked: {
                                page.eType = modelData.id;
                                page.eLua = "";
                                if (modelData.id !== "app" && modelData.id !== "command" && modelData.id !== "workspace") page.eValue = "";
                            }
                        }
                    }
                }

                // Open app
                Column {
                    visible: page.eType === "app"
                    width: parent.width
                    spacing: 8
                    Field {
                        width: parent.width
                        placeholder: page.eValue ? "Selected: " + Binds.appName(page.eValue) : "Search apps"
                        onEdited: t => page.appQuery = t
                    }
                    Flow {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: Apps.search(page.appQuery).slice(0, 12)
                            Rectangle {
                                required property var modelData
                                readonly property bool on: page.eValue === modelData.id
                                width: ar.width + 20
                                height: 36
                                radius: Theme.r(height / 2)
                                color: on ? Theme.fg : (am.containsMouse ? Theme.raised : "transparent")
                                border.width: on ? 0 : 1
                                border.color: Theme.faint
                                Row {
                                    id: ar
                                    anchors.centerIn: parent
                                    spacing: 8
                                    AppIcon { anchors.verticalCenter: parent.verticalCenter; icon: parent.parent.modelData.icon; size: 20 }
                                    Caption { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.modelData.name; color: parent.parent.on ? Theme.bg : Theme.fg }
                                }
                                MouseArea {
                                    id: am
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        page.eValue = parent.modelData.id;
                                        page.eLabel = parent.modelData.name;
                                        if (!page.eDesc || page.eDesc.startsWith("Open ")) page.eDesc = "Open " + parent.modelData.name;
                                    }
                                }
                            }
                        }
                    }
                }

                // Command
                Field {
                    visible: page.eType === "command"
                    width: parent.width
                    text: page.eValue
                    placeholder: "Shell command, e.g. kitty -e btop"
                    onEdited: t => page.eValue = t
                }

                // Presets
                Flow {
                    visible: ["shell", "window", "media", "system"].includes(page.eType)
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: Binds.presets[page.eType] ?? []
                        Chip {
                            required property var modelData
                            text: modelData.label
                            on: page.eLua === modelData.lua
                            onClicked: {
                                page.eLua = modelData.lua;
                                page.eLabel = modelData.label;
                                if (!page.eDesc || page.isNew) page.eDesc = modelData.label;
                            }
                        }
                    }
                }

                // Workspace
                Column {
                    visible: page.eType === "workspace"
                    spacing: 8
                    Row {
                        spacing: 6
                        Chip { text: "Go to"; on: page.eWsMode === "goto"; onClicked: page.eWsMode = "goto" }
                        Chip { text: "Send window to"; on: page.eWsMode === "send"; onClicked: page.eWsMode = "send" }
                    }
                    Row {
                        spacing: 6
                        Repeater {
                            model: 10
                            Chip {
                                required property int index
                                text: String(index + 1)
                                on: page.eValue === String(index + 1)
                                onClicked: page.eValue = String(index + 1)
                            }
                        }
                    }
                }

                Caption {
                    visible: page.eType === "off"
                    text: "This combo will do nothing. You can restore it from “Disabled” below."
                }
                Caption {
                    visible: page.eType === "keep"
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "Keeps: " + page.eCurrent
                }
            }

            // Description
            Column {
                width: parent.width
                spacing: 8
                Caption { text: "Name"; color: Theme.accent; font.capitalization: Font.AllUppercase; font.letterSpacing: 2 }
                Field {
                    width: parent.width
                    text: page.eDesc
                    placeholder: "How it's listed here, e.g. Custom: Open Firefox"
                    onEdited: t => page.eDesc = t
                }
            }

            Row {
                spacing: 8
                OptButton { text: "Cancel"; onClicked: page.cancel() }
                OptButton {
                    visible: !page.isNew && Binds.custom.some(c => c.uid === page.eUid)
                    text: "Reset to default"
                    icon: "restart_alt"
                    onClicked: {
                        Binds.remove(page.eUid);
                        page.cancel();
                    }
                }
                OptButton {
                    text: "Save"
                    icon: "check"
                    accent: true
                    opacity: page.valid ? 1 : 0.4
                    enabled: page.valid
                    onClicked: page.save()
                }
            }
        }
    }

    // ---------------- Lists
    Repeater {
        model: page.groups
        Section {
            id: group
            required property var modelData
            title: modelData.name + " · " + modelData.binds.length
            Repeater {
                model: group.modelData.binds
                Item {
                    id: row
                    required property var modelData
                    readonly property bool modified: Binds.isCustom(modelData) || Binds.overrideFor(modelData) !== null
                    width: parent.width
                    height: 62

                    Rectangle {
                        anchors.fill: parent
                        color: rm.containsMouse ? Qt.alpha(Theme.raised, 0.6) : "transparent"
                    }
                    Column {
                        x: 22
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - keys.width - 80
                        spacing: 3
                        Row {
                            spacing: 8
                            Label { text: Binds.titleOf(row.modelData); font.pixelSize: 13; width: Math.min(implicitWidth, row.width - keys.width - 110) }
                            Rectangle { visible: row.modified; anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; radius: Theme.r(3); color: Theme.accent }
                        }
                        Caption {
                            width: parent.width
                            elide: Text.ElideRight
                            text: Binds.explain(row.modelData)
                        }
                    }
                    Row {
                        id: keys
                        anchors.right: parent.right
                        anchors.rightMargin: 50
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: Binds.keysOf(row.modelData.combo)
                            KeyChip { required property string modelData; text: modelData }
                        }
                    }
                    Icon {
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: "edit"
                        size: 16
                        color: rm.containsMouse ? Theme.accent : Theme.dim
                    }
                    MouseArea {
                        id: rm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.startEdit(row.modelData)
                    }
                    Rectangle { anchors.bottom: parent.bottom; x: 22; width: parent.width - 44; height: 1; color: Theme.faint; opacity: 0.35 }
                }
            }
        }
    }

    Section {
        visible: page.disabled.length > 0
        title: "Disabled · " + page.disabled.length
        Repeater {
            model: page.disabled
            OptRow {
                required property var modelData
                label: modelData.description || modelData.replaces
                sub: modelData.replaces
                OptButton { text: "Restore"; icon: "undo"; onClicked: Binds.remove(parent.parent.modelData.uid) }
            }
        }
    }

    component KeyChip: Rectangle {
        property string text
        width: kt.implicitWidth + 14
        height: 24
        radius: Theme.r(8)
        color: Theme.raised
        border.width: 1
        border.color: Theme.faint
        Caption { id: kt; anchors.centerIn: parent; text: parent.text; color: Theme.fg; font.pixelSize: 10 }
    }
    component Chip: Rectangle {
        id: chip
        property string text
        property bool on: false
        signal clicked
        width: ct.implicitWidth + 24
        height: 30
        radius: Theme.r(15)
        color: on ? Theme.fg : (cm.containsMouse ? Theme.raised : "transparent")
        border.width: on ? 0 : 1
        border.color: Theme.faint
        Behavior on color { ColorAnimation { duration: 120 } }
        Caption { id: ct; anchors.centerIn: parent; text: chip.text; color: chip.on ? Theme.bg : Theme.fg; font.pixelSize: 11 }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
    }
    component Field: Rectangle {
        id: field
        property string text
        property string placeholder
        signal edited(string t)
        height: 40
        radius: Theme.r(height / 2)
        color: Theme.raised
        border.width: fi.activeFocus ? 1 : 0
        border.color: Theme.accent
        TextInput {
            id: fi
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            text: field.text
            font.family: Theme.mono
            font.pixelSize: 12
            color: Theme.fg
            selectionColor: Theme.accent
            clip: true
            onTextEdited: field.edited(text)
            Caption { anchors.verticalCenter: parent.verticalCenter; visible: fi.text.length === 0; text: field.placeholder }
        }
    }
}
