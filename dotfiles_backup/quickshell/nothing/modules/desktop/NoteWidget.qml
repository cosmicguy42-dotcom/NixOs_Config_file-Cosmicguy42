import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// Sticky note, saved to ~/.local/state/nothing/note.txt as you type.
Glass {
    width: 300
    height: 220

    FileView {
        id: file
        path: Theme.stateDir + "/note.txt"
        onLoaded: edit.text = text()
        printErrors: false
    }
    Timer {
        id: saveLater
        interval: 600
        onTriggered: file.setText(edit.text)
    }

    Caption {
        x: 22
        y: 18
        text: "Note"
        color: Theme.accent
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 2
    }
    Flickable {
        x: 22
        y: 44
        width: parent.width - 44
        height: parent.height - 64
        contentHeight: edit.contentHeight
        clip: true
        TextEdit {
            id: edit
            width: parent.width
            wrapMode: TextEdit.Wrap
            font.family: Theme.mono
            font.pixelSize: 13
            color: Theme.fg
            selectionColor: Theme.accent
            onTextChanged: saveLater.restart()
            Caption {
                visible: edit.text.length === 0 && !edit.activeFocus
                text: "Click to write something…"
            }
        }
    }
}
