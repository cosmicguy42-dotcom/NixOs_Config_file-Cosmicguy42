import QtQuick
import qs.services

OptChoice {
    required property string path
    current: Config.get(path)
    onPicked: v => Config.set(path, v)
}
