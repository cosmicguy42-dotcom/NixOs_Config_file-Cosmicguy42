import QtQuick
import qs.services
import qs.components

// Titled card that groups settings rows.
Column {
    id: section

    property string title
    default property alias content: body.data

    width: parent.width
    spacing: 10

    Overline {
        x: 4
        text: section.title
    }
    Rectangle {
        width: parent.width
        height: body.height
        radius: Theme.radius
        color: Theme.card
        clip: true
        Column {
            id: body
            width: parent.width
        }
    }
}
