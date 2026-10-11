import QtQuick
import qs.services

OptText {
    required property string path
    text: Config.get(path) ?? ""
    onAccepted: t => Config.set(path, t)
}
