import QtQuick
import qs.services

// Dot-matrix weather glyphs (11x9), after Nothing's weather app, animated:
// rain falls, snow drifts, lightning flickers, the sun's rays pulse, stars
// twinkle, clouds drift and fog slides. kind: clear | night | partly |
// cloudy | fog | rain | snow | storm.
DotMatrix {
    id: root

    property string kind: "cloudy"
    property bool animated: Config.get("look.animatedIcons") !== false
    property int frame: 0

    readonly property string blank: "..........."
    readonly property var cloud: [
        "......###..",
        "..##.#####.",
        ".##########",
        "###########",
        "###########",
        ".#########."
    ]

    function shift(rows, dx) { // slide a bitmap sideways (no wrap)
        return rows.map(r => dx > 0 ? ".".repeat(dx) + r.slice(0, r.length - dx) : dx < 0 ? r.slice(-dx) + ".".repeat(-dx) : r);
    }
    function pattern(offset, step, width) { // "..#..#.." with a moving phase
        let s = "";
        for (let c = 0; c < width; c++)
            s += (c + offset) % step === 0 ? "#" : ".";
        return s;
    }

    readonly property var still: ({
        clear: [".....#.....", ".#.......#.", "....###....", "...#####...", "#..#####..#", "...#####...", "....###....", ".#.......#.", ".....#....."],
        night: ["...####.#..", "..###......", ".###.....#.", ".###.......", ".###.......", ".###.......", ".####....##", "..########.", "...######.."],
        partly: [".###.......", "#####......", "####...###.", "###..######", "..#########", ".##########", "###########", ".#########.", blank],
        cloudy: [blank, blank].concat(cloud, [blank]),
        fog: [blank, "#########..", blank, "..#########", blank, "#########..", blank, "..#########", blank],
        rain: cloud.concat([blank, "..#..#..#..", ".#..#..#..."]),
        snow: cloud.concat([blank, ".#...#...#.", "...#...#..."]),
        storm: cloud.concat(["......#....", ".....##....", "....#......"])
    })

    function framed(k, f) {
        switch (k) {
        case "rain": // drops fall diagonally
            return cloud.concat([pattern(f % 3, 3, 11), pattern((f + 1) % 3, 3, 11), pattern((f + 2) % 3, 3, 11)]);
        case "snow": // flakes drift slower, sideways
            return cloud.concat([pattern(Math.floor(f / 2) % 4, 4, 11), blank, pattern((Math.floor(f / 2) + 2) % 4, 4, 11)]);
        case "storm": // bolt flickers, light rain
            return cloud.concat(f % 4 < 2 ? ["......#....", ".....##....", "....#......"]
                                          : [pattern(f % 3, 5, 11), blank, pattern((f + 2) % 3, 5, 11)]);
        case "clear": // rays pulse in and out
            return f % 2 === 0 ? still.clear
                : [blank, "..#.....#..", "....###....", "...#####...", ".#.#####.#.", "...#####...", "....###....", "..#.....#..", blank];
        case "night": { // stars twinkle
            const r = still.night.slice();
            if (f % 3 === 1) { r[0] = "...####...."; r[2] = ".###......#"; }
            if (f % 3 === 2) { r[6] = ".####....#."; }
            return r;
        }
        case "cloudy": // drift one dot left and right
            return shift(still.cloudy, [0, 1, 1, 0, -1, -1][f % 6]);
        case "partly": // cloud part drifts, sun stays
            return f % 4 < 2 ? still.partly : still.partly.map((row, i) => i >= 3 ? shift([row], i >= 4 ? 1 : 0)[0] : row);
        case "fog":
            return still.fog.map((row, i) => row === blank ? row : shift([row], (i + f) % 4 < 2 ? 1 : -1)[0]);
        }
        return still.cloudy;
    }

    rows: animated ? framed(kind, frame) : (still[kind] ?? still.cloudy)
    fade: animated ? 180 : 260
    dot: 3
    gap: 1.4

    Timer {
        interval: root.kind === "rain" || root.kind === "storm" ? 260 : 520
        running: root.animated && root.visible
        repeat: true
        onTriggered: root.frame = (root.frame + 1) % 12
    }
}
