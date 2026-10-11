import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Background layer. New wallpapers crossfade in with a slight settle-in zoom.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "nothing:wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.bg

    // Caffeine: keep the screen awake while toggled on.
    IdleInhibitor {
        window: win
        enabled: Toggles.caffeine
    }

    property Image front: a
    property Image back: b

    function show(path) {
        if (!path || front.source.toString() === "file://" + path)
            return;
        const url = "file://" + path;
        // Going back to the previous wallpaper: it's still loaded in the
        // hidden layer, so there's no load event - swap straight away.
        if (back.source.toString() === url && back.status === Image.Ready)
            swap(back);
        else
            back.source = url;
    }
    function swap(img) {
        img.z = 1;
        front.z = 0;
        fadeIn.target = img;
        fadeIn.restart();
        const old = front;
        front = img;
        back = old;
    }

    Connections {
        target: Appearance
        function onWallpaperChanged() { win.show(Appearance.wallpaper); }
    }
    Component.onCompleted: show(Appearance.wallpaper)

    component Wall: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        // decode at physical pixels, so hi-DPI / fractional scaling stays sharp
        sourceSize: Qt.size(win.width * win.devicePixelRatio, win.height * win.devicePixelRatio)
        opacity: 0
        onStatusChanged: {
            if (status === Image.Ready && this === win.back)
                win.swap(this);
        }
    }

    Wall { id: a }
    Wall { id: b }

    ParallelAnimation {
        id: fadeIn
        property Item target
        NumberAnimation { target: fadeIn.target; property: "opacity"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { target: fadeIn.target; property: "scale"; from: 1.04; to: 1; duration: 1400; easing.type: Easing.OutQuint }
        onFinished: win.back.opacity = 0
    }
}
