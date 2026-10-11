import QtQuick
import qs.services

OptChoice {
    required property string key
    visible: !HyprConf.ready || HyprConf.values[key] !== undefined
    current: HyprConf.values[key]
    modified: HyprConf.isSet(key)
    onPicked: v => HyprConf.set(key, v)
    onReset: HyprConf.reset(key)
}
