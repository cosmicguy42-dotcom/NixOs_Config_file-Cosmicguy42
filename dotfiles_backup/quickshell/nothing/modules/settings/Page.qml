import QtQuick
import qs.services
import qs.components

// Scrollable settings page with a serif title.
Flickable {
    id: page

    property string title
    property string subtitle: ""
    default property alias content: col.data

    contentHeight: col.height + 70
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        x: 40
        y: 34
        width: page.width - 80
        spacing: 26

        Column {
            width: parent.width
            spacing: 4
            Heading {
                text: page.title
                font.pixelSize: 44
            }
            Caption {
                visible: text !== ""
                width: parent.width
                wrapMode: Text.Wrap
                text: page.subtitle
                font.pixelSize: 11
            }
        }
    }

    // Thin scroll indicator
    Rectangle {
        visible: page.contentHeight > page.height
        x: page.width - 6
        y: page.visibleArea.yPosition * page.height + 4
        width: 3
        height: Math.max(30, page.visibleArea.heightRatio * page.height - 8)
        radius: Theme.r(1.5)
        color: Theme.faint
    }
}
