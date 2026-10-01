pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// On-screen display for volume and brightness: pops up on the focused monitor whenever either changes
// (media keys via wpctl, bar scroll, IPC, anything), then hides after a moment. Hover keeps it up.
//   qs -c base ipc call osd popup volume|brightness
//   qs -c base ipc call brightness increment|decrement     (5% steps, same names end4-pC used)
Singleton {
    id: root

    property string kind: "volume"   // or "brightness"
    property bool shown: false
    property bool hovered: false
    // Quick settings already shows the same sliders.
    readonly property bool suppressed: Panels.popup === "quicksettings"

    function show(k) {
        if (suppressed) return;
        kind = k;
        shown = true;
        hideTimer.restart();
    }

    onHoveredChanged: if (!hovered && shown) hideTimer.restart()

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: if (!root.hovered) root.shown = false
    }

    // Volume: ignore the burst of changes while PipeWire first reports the sink, or when the default
    // output switches (the new device's volume isn't a user change).
    property bool armed: false
    Timer {
        id: rearm
        running: true
        interval: 1500
        onTriggered: root.armed = true
    }
    Connections {
        target: Audio
        function onSinkChanged() {
            root.armed = false;
            rearm.restart();
        }
        function onVolumeChanged() { if (root.armed && Audio.ready) root.show("volume"); }
        function onMutedChanged() { if (root.armed && Audio.ready) root.show("volume"); }
    }

    // Brightness only changes through the shell (DDC isn't polled), so it signals user changes itself.
    Connections {
        target: Brightness
        function onUserChanged() { root.show("brightness"); }
    }

    IpcHandler {
        target: "osd"
        function popup(kind: string): void {
            root.show(kind === "brightness" ? "brightness" : "volume");
        }
    }

    IpcHandler {
        target: "brightness"
        function increment(): void { Brightness.set(Brightness.value + 0.05); }
        function decrement(): void { Brightness.set(Brightness.value - 0.05); }
    }
}
