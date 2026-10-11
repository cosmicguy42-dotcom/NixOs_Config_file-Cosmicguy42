import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.components

Page {
    id: page
    title: "Sound"

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var apps: nodes.filter(n => n.isSink && n.isStream)

    PwObjectTracker {
        objects: page.nodes
    }

    component Device: OptRow {
        id: dev
        required property var node
        property bool current: false
        signal choose
        label: node.description || node.nickname || node.name
        Icon {
            text: dev.current ? "radio_button_checked" : "radio_button_unchecked"
            size: 20
            color: dev.current ? Theme.accent : Theme.dim
        }
        MouseArea {
            parent: dev
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: dev.choose()
        }
    }

    Section {
        title: "Output"
        OptSlider {
            label: "Volume"
            sub: Audio.muted ? "Muted" : ""
            from: 0
            to: 100
            suffix: "%"
            value: Math.round(Audio.volume * 100)
            onCommitted: v => Audio.setVolume(v / 100)
        }
        OptSwitch { label: "Mute"; checked: Audio.muted; onToggled: Audio.toggleMute() }
        Repeater {
            model: page.sinks
            Device {
                required property var modelData
                node: modelData
                current: Pipewire.defaultAudioSink === modelData
                onChoose: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
    }

    Section {
        title: "Input"
        OptSwitch { label: "Microphone"; sub: Audio.micMuted ? "Muted" : "Live"; checked: !Audio.micMuted; onToggled: Audio.toggleMic() }
        OptSlider {
            label: "Input volume"
            from: 0
            to: 100
            suffix: "%"
            value: Math.round((Audio.source?.audio?.volume ?? 0) * 100)
            onCommitted: v => { if (Audio.source?.audio) Audio.source.audio.volume = v / 100; }
        }
        Repeater {
            model: page.sources
            Device {
                required property var modelData
                node: modelData
                current: Pipewire.defaultAudioSource === modelData
                onChoose: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    Section {
        title: "Apps"
        OptRow {
            visible: page.apps.length === 0
            label: "Nothing is playing audio"
        }
        Repeater {
            model: page.apps
            OptSlider {
                required property var modelData
                label: modelData.properties["application.name"] ?? modelData.description ?? modelData.name
                sub: modelData.properties["media.name"] ?? ""
                from: 0
                to: 100
                suffix: "%"
                value: Math.round((modelData.audio?.volume ?? 0) * 100)
                onCommitted: v => modelData.audio.volume = v / 100
            }
        }
    }
}
