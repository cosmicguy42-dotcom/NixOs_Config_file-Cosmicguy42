import QtQuick
import qs.services

// Dot-matrix audio waveform, mirrored around the middle row like Nothing's
// Glyph visualiser. Resamples Visualizer.levels to `columns`.
DotMatrix {
    id: root

    property int columns: 16
    property int lines: 5
    property real level: 1 // scale

    readonly property var values: {
        const src = Visualizer.levels, out = [];
        for (let c = 0; c < columns; c++) {
            const i = Math.floor(c / columns * src.length);
            out.push(Math.min(1, (src[i] ?? 0) * level));
        }
        return out;
    }

    rows: {
        const mid = (lines - 1) / 2, out = [];
        for (let r = 0; r < lines; r++) {
            let row = "";
            for (let c = 0; c < columns; c++)
                row += Math.abs(r - mid) <= values[c] * (mid + 0.5) - 0.25 || (r === Math.round(mid) && values[c] > 0.02) ? "#" : ".";
            out.push(row);
        }
        return out;
    }
    fade: 70
}
