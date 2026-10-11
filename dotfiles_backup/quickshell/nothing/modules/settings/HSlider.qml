import QtQuick
import qs.services

OptSlider {
    required property string key
    visible: !HyprConf.ready || HyprConf.values[key] !== undefined
    value: HyprConf.values[key] ?? from
    modified: HyprConf.isSet(key)
    onCommitted: v => HyprConf.set(key, decimals === 0 ? Math.round(v) : Number(v.toFixed(decimals)))
    onReset: HyprConf.reset(key)
}
