pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    // Prefer whatever is playing; otherwise the first player around.
    // The one you picked in the media view wins (while it exists); otherwise
    // whatever is playing, otherwise the first player.
    property MprisPlayer pinned: null
    readonly property MprisPlayer active: (pinned && players.includes(pinned) ? pinned : null) ?? players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle || active?.identity || ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string art: active?.trackArtUrl ?? ""

    // Colour from the cover art: the most vivid of a small quantised palette,
    // falling back to the theme accent. Used by the media views and, when
    // "Theme from cover art" is on, by the whole shell.
    readonly property color artAccent: {
        let best = null, score = -1;
        for (const c of quant.colors) {
            const s = c.hsvSaturation * (0.35 + c.hsvValue) * (c.hsvValue > 0.25 ? 1 : 0.2);
            if (s > score) { score = s; best = c; }
        }
        return best && score > 0.12 ? Qt.hsva(best.hsvHue, Math.min(0.85, best.hsvSaturation + 0.1), Math.max(0.7, best.hsvValue), 1) : Theme.accent;
    }
    readonly property bool hasArtColor: quant.colors.length > 0

    ColorQuantizer {
        id: quant
        source: root.art
        depth: 3
        rescaleSize: 64
    }

    // MPRIS doesn't push position updates; poll while something plays.
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.active.positionChanged()
    }
}
