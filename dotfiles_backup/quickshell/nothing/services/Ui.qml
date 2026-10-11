pragma Singleton

import QtQuick
import Quickshell

// What the island is showing.
//   view      - panel the user opened ("" when collapsed)
//   popup - short-lived popup (osd / notif) shown while collapsed
Singleton {
    id: root

    property string view: ""
    property bool barVisible: true

    property var trayItem: null // item whose menu the "tray" view shows
    property bool trayOpen: false
    property bool widgetEdit: false // desktop widgets arrange mode
    property string settingsRequest: "" // set to a page id to open Settings

    property string popup: ""
    property string osdKind: "volume" // volume | brightness
    property real osdValue: 0
    property bool osdMuted: false

    function toggle(name) { view = view === name ? "" : name; }
    function open(name) { view = name; }
    function close() { view = ""; }
    function openSettings(page) { settingsRequest = page || "appearance"; }
    function openTray(item) {
        trayItem = item;
        view = "tray";
    }

    function osd(kind, value, muted) {
        osdKind = kind;
        osdValue = value;
        osdMuted = muted ?? false;
        flash("osd", 1600);
    }
    function flash(kind, ms) {
        popup = kind;
        popupTimer.interval = ms;
        popupTimer.restart();
    }

    Timer {
        id: popupTimer
        onTriggered: root.popup = ""
    }
}
