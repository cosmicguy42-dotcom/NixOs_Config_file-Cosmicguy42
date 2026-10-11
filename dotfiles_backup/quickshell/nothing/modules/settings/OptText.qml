import QtQuick
import qs.services
import qs.components

// Text field row; emits accepted(text) on Enter or focus loss.
OptRow {
    id: r

    property string text: ""
    property string placeholder: ""
    property int fieldWidth: 230
    signal accepted(string text)

    Rectangle {
        width: r.fieldWidth
        height: 34
        radius: Theme.r(17)
        color: Theme.raised
        border.width: input.activeFocus ? 1 : 0
        border.color: Theme.accent

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            verticalAlignment: TextInput.AlignVCenter
            text: r.text
            font.family: Theme.mono
            font.pixelSize: 12
            color: Theme.fg
            selectionColor: Theme.accent
            clip: true
            onEditingFinished: if (text !== r.text) r.accepted(text)
            Caption {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0 && !input.activeFocus
                text: r.placeholder
            }
        }
    }
}
