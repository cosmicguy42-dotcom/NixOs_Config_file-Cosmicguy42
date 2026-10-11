import QtQuick
import qs.services

OptText {
    required property string key
    visible: !HyprConf.ready || HyprConf.values[key] !== undefined
    text: HyprConf.values[key] ?? ""
    modified: HyprConf.isSet(key)
    onAccepted: t => HyprConf.set(key, t)
    onReset: HyprConf.reset(key)
}
