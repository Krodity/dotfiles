pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Default PipeWire output (speakers/headphones).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string icon: muted || volume === 0 ? "volume_off"
        : volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up"

    function setVolume(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    // Real output devices (no app streams), current one first.
    readonly property var sinks: Pipewire.nodes.values
        .filter(n => n.isSink && !n.isStream && n.audio)
        .sort((a, b) => (b === sink) - (a === sink) || sinkName(a).localeCompare(sinkName(b)))

    function setSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function sinkName(node) {
        return node?.description || node?.nickname || node?.name || "Unknown device";
    }

    function sinkIcon(node) {
        const n = `${node?.name ?? ""} ${sinkName(node)}`.toLowerCase();
        if (n.includes("bluez")) return "bluetooth";
        if (n.includes("headphone") || n.includes("headset") || n.includes("arctis")) return "headphones";
        if (n.includes("hdmi") || n.includes("displayport")) return "tv";
        if (n.includes("virtual") || n.includes("null")) return "cable";
        return "speaker";
    }

    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }

    // Nodes must be tracked before their audio properties are live.
    PwObjectTracker {
        objects: [root.sink]
    }
}
