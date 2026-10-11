pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Polkit authentication agent; the island shows the prompt while active.
// On a hot reload the old generation still holds the registration when the
// new one starts, so re-create the agent until it registers.
Singleton {
    id: root

    readonly property var agent: loader.item
    readonly property bool active: (agent?.isActive ?? false) && agent.flow !== null
    readonly property var flow: agent?.flow ?? null

    LazyLoader {
        id: loader
        active: true
        PolkitAgent {}
    }
    Timer {
        interval: 3000
        running: !(root.agent?.isRegistered ?? false)
        repeat: true
        onTriggered: {
            loader.active = false;
            loader.active = true;
        }
    }
}
