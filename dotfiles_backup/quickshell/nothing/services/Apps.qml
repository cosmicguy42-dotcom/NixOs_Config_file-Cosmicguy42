pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// App search for the launcher. Everything is in memory (DesktopEntries), and
// launch counts (~/.local/state/nothing/launcher.json) boost frequent apps.
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    property var counts: ({})

    // Empty query: most used first, then A-Z.
    readonly property var byUse: all.slice().sort((a, b) => (counts[b.id] ?? 0) - (counts[a.id] ?? 0) || a.name.localeCompare(b.name))

    function fuzzy(text, q) {
        let i = 0;
        for (const ch of text)
            if (ch === q[i] && ++i === q.length)
                return true;
        return false;
    }
    function score(a, q) {
        const n = a.name.toLowerCase();
        let s = 0;
        if (n === q) s = 1000;
        else if (n.startsWith(q)) s = 800;
        else if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 600;
        else if (n.includes(q)) s = 450;
        else if ((a.genericName ?? "").toLowerCase().includes(q)) s = 300;
        else if (((a.keywords ?? "") + " " + (a.categories ?? "")).toLowerCase().includes(q)) s = 220;
        else if (q.length > 1 && fuzzy(n, q)) s = 150;
        else if ((a.execString ?? "").toLowerCase().includes(q)) s = 100;
        return s ? s + Math.min(150, (counts[a.id] ?? 0) * 6) : 0;
    }
    function search(query) {
        const q = query.trim().toLowerCase();
        if (!q)
            return byUse;
        return all.map(a => ({ a: a, s: score(a, q) }))
            .filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s)
            .map(x => x.a);
    }

    function launch(app, action) {
        const c = Object.assign({}, counts);
        c[app.id] = (c[app.id] ?? 0) + 1;
        counts = c;
        store.setText(JSON.stringify(c));
        if (action)
            action.execute();
        else if (app.runInTerminal)
            Quickshell.execDetached(["kitty", "-1", "--instance-group", "nothing", "--"].concat(app.command));
        else
            app.execute();
    }

    FileView {
        id: store
        path: Theme.stateDir + "/launcher.json"
        onLoaded: {
            try { root.counts = JSON.parse(text()); } catch (e) {}
        }
    }
}
