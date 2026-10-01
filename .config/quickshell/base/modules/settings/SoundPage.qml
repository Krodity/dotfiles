import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Settings → Sound: output volume + device, input (microphone) volume + device.
ColumnLayout {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sources: Pipewire.nodes.values
        .filter(n => !n.isSink && !n.isStream && n.audio && !(n.name ?? "").endsWith(".monitor"))
        .sort((a, b) => (b === source) - (a === source) || Audio.sinkName(a).localeCompare(Audio.sinkName(b)))

    spacing: 18

    PwObjectTracker {
        objects: [root.source]
    }

    Card {
        title: "Output"

        IconSlider {
            Layout.fillWidth: true
            icon: Audio.icon
            value: Audio.volume
            active: Audio.ready
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }

        Repeater {
            model: Audio.sinks

            ListRow {
                required property var modelData
                Layout.fillWidth: true
                icon: Audio.sinkIcon(modelData)
                text: Audio.sinkName(modelData)
                highlighted: modelData === Audio.sink
                trailing: modelData === Audio.sink ? "Active" : ""
                onClicked: Audio.setSink(modelData)
            }
        }
    }

    Card {
        title: "Input"

        IconSlider {
            Layout.fillWidth: true
            icon: root.source?.audio?.muted ? "mic_off" : "mic"
            value: root.source?.audio?.volume ?? 0
            active: root.source?.ready ?? false
            onMoved: v => {
                if (!root.source?.audio) return;
                root.source.audio.muted = false;
                root.source.audio.volume = v;
            }
            onIconClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
        }

        Repeater {
            model: root.sources

            ListRow {
                required property var modelData
                Layout.fillWidth: true
                icon: "mic"
                text: Audio.sinkName(modelData)
                highlighted: modelData === root.source
                trailing: modelData === root.source ? "Active" : ""
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }
}
