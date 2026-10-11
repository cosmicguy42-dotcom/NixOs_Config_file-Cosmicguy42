pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallhaven.cc browser (SFW only, no API key needed). Setting one downloads
// the full image into the wallpaper folder and applies it.
Singleton {
    id: root

    property string query: ""
    property string sorting: "toplist"  // toplist | date_added | random | views | favorites | relevance
    property string topRange: "1M"
    property bool general: true
    property bool anime: true
    property bool people: false
    property int page: 1
    property int lastPage: 1
    property var results: []            // { id, thumb, full, resolution, size, colors, ext }
    property bool loading: false
    property string busyId: ""          // downloading
    property string error: ""

    readonly property string categories: (general ? "1" : "0") + (anime ? "1" : "0") + (people ? "1" : "0")

    function url() {
        const q = [
            "categories=" + categories, "purity=100", "sorting=" + sorting, "atleast=1920x1080",
            "ratios=16x9,16x10,21x9", "page=" + page
        ];
        if (sorting === "toplist") q.push("topRange=" + topRange);
        if (query.trim()) q.push("q=" + encodeURIComponent(query.trim()));
        return "https://wallhaven.cc/api/v1/search?" + q.join("&");
    }
    function search() {
        page = 1;
        results = [];
        fetch();
    }
    function more() {
        if (page >= lastPage || loading) return;
        page += 1;
        fetch();
    }
    function fetch() {
        loading = true;
        error = "";
        proc.command = ["curl", "-sf", "--max-time", "20", url()];
        proc.running = true;
    }
    function set(item) {
        if (busyId) return;
        busyId = item.id;
        const file = Appearance.wallDir + "/wallhaven-" + item.id + "." + item.ext;
        dl.target = file;
        dl.command = ["sh", "-c", 'test -s "$1" || curl -sfL --max-time 120 -o "$1.part" "$2" && { test -s "$1" || mv "$1.part" "$1"; }', "sh", file, item.full];
        dl.running = true;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const j = JSON.parse(text);
                    root.lastPage = j.meta.last_page;
                    root.results = root.results.concat(j.data.map(d => ({
                        id: d.id,
                        thumb: d.thumbs.small,
                        full: d.path,
                        resolution: d.resolution,
                        size: (d.file_size / 1048576).toFixed(1) + " MB",
                        colors: d.colors,
                        ext: d.path.split(".").pop()
                    })));
                } catch (e) {
                    root.error = "Couldn't reach wallhaven.cc";
                }
            }
        }
    }
    Process {
        id: dl
        property string target
        onExited: code => {
            root.busyId = "";
            if (code === 0)
                Appearance.setWallpaper(target);
            else
                root.error = "Download failed";
        }
    }
}
