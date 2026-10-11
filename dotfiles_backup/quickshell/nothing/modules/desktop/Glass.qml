import QtQuick
import qs.services

// Frosted desktop widget surface (Hyprland blurs behind it).
Rectangle {
    radius: Theme.radius
    color: Theme.glass
    border.width: Config.get("pill.border") ? 1 : 0
    border.color: Qt.alpha(Theme.faint, 0.5)
}
