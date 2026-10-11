import QtQuick
import qs.services

OptSlider {
    required property string path
    value: Config.get(path) ?? from
    onCommitted: v => Config.set(path, decimals === 0 ? Math.round(v) : Number(v.toFixed(decimals)))
}
