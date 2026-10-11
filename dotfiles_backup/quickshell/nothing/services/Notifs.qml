pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values
    property Notification latest: null

    function clear() {
        for (const n of list.slice())
            n.dismiss();
    }
    function activate(n) {
        const def = n.actions.find(a => a.identifier === "default") ?? n.actions[0];
        if (def)
            def.invoke();
        else
            n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true;
            root.latest = n;
            if (!Toggles.dnd || n.urgency === NotificationUrgency.Critical)
                Ui.flash("notif", n.urgency === NotificationUrgency.Critical ? 9000 : Config.get("notifications.timeout") * 1000);
        }
    }
}
