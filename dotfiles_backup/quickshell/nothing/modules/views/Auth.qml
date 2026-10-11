import QtQuick
import qs.services
import qs.components

// Polkit prompt. Enter submits, Escape cancels.
Column {
    id: root

    required property var flow
    width: 380
    spacing: 14

    function submit() {
        if (field.text.length === 0)
            return;
        root.flow.submit(field.text);
        field.text = "";
    }

    Row {
        spacing: 10
        Icon { text: "lock"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Heading { text: "Authenticate"; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
    }
    Label {
        width: parent.width
        text: root.flow?.message ?? ""
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        maximumLineCount: 4
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: Theme.r(height / 2)
        color: Theme.raised
        border.width: field.activeFocus ? 1 : 0
        border.color: Theme.accent

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            verticalAlignment: TextInput.AlignVCenter
            echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            font.family: Theme.mono
            font.pixelSize: 14
            color: Theme.fg
            selectionColor: Theme.accent
            focus: true
            Component.onCompleted: forceActiveFocus()
            Keys.onReturnPressed: root.submit()
            Keys.onEnterPressed: root.submit()
            Keys.onEscapePressed: root.flow.cancelAuthenticationRequest()

            Caption {
                anchors.verticalCenter: parent.verticalCenter
                visible: field.text.length === 0
                text: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
            }
        }
    }

    Caption {
        visible: text !== ""
        width: parent.width
        wrapMode: Text.Wrap
        text: root.flow?.supplementaryMessage ?? ""
        color: root.flow?.supplementaryIsError ? Theme.error : Theme.dim
    }

    Row {
        anchors.right: parent.right
        spacing: 10
        CircleButton { icon: "close"; onClicked: root.flow.cancelAuthenticationRequest() }
        CircleButton { icon: "check"; active: true; onClicked: root.submit() }
    }
}
