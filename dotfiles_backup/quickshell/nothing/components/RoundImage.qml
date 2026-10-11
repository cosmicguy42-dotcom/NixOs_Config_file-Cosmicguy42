import QtQuick
import QtQuick.Effects
import QtQuick.Window
import qs.services

// Image clipped to a rounded rect.
Item {
    id: root

    property alias source: img.source
    property alias status: img.status
    property real radius: 12
    property int thumb: 0 // decode size; 0 = full

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        // image://icon lookups aren't thread-safe; only files load async.
        asynchronous: !String(source).startsWith("image://")
        // thumb is in logical px; decode for the screen's pixel density
        sourceSize: root.thumb > 0 ? Qt.size(root.thumb * (Screen.devicePixelRatio || 1), root.thumb * (Screen.devicePixelRatio || 1)) : undefined
        visible: false
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: Theme.r(root.radius)
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
        opacity: img.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }
}
