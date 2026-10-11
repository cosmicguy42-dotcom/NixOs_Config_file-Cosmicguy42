import QtQuick
import qs.services

// Switch bound to a Hyprland option.
OptSwitch {
    required property string key
    visible: !HyprConf.ready || HyprConf.values[key] !== undefined
    checked: HyprConf.values[key] === true || HyprConf.values[key] === 1
    modified: HyprConf.isSet(key)
    onToggled: on => HyprConf.set(key, on)
    onReset: HyprConf.reset(key)
}
