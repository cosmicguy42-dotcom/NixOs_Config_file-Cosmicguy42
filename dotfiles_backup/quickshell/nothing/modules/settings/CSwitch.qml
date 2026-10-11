import QtQuick
import qs.services

// Switch bound to a shell option in config.json.
OptSwitch {
    required property string path
    checked: Config.get(path) === true
    onToggled: on => Config.set(path, on)
}
