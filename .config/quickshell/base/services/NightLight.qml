pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Blue-light filter through hyprsunset's hyprctl IPC. Starts hyprsunset if it isn't running.
// "On" = `temperature` is applied; "off" = identity (no tint). The temperature is saved in
// ~/.local/state/quickshell-base/nightlight.json.
Singleton {
    id: root

    property bool active: false
    readonly property int temperature: settings.temperature
    readonly property int minTemp: 2500
    readonly property int maxTemp: 5500
    readonly property string status: active ? `${temperature}K` : "Off"

    function refresh() {
        if (!query.running) query.running = true;
    }

    function toggle() {
        active = !active;
        apply();
    }

    readonly property int step: 250 // K per Warmer/Cooler press

    // dir = -1 warmer, +1 cooler.
    function adjust(dir) {
        setTemperature(temperature + dir * step);
    }

    // Store it, and turn the filter on so the change is visible.
    function setTemperature(k) {
        settings.temperature = Math.round(Math.max(minTemp, Math.min(maxTemp, k)) / 50) * 50;
        active = true;
        applyDelay.restart();
    }

    function apply() {
        const cmd = active ? `temperature ${temperature}` : "identity";
        Quickshell.execDetached(["sh", "-c",
            `pidof hyprsunset >/dev/null || { hyprsunset >/dev/null 2>&1 & sleep 0.4; }; hyprctl hyprsunset ${cmd}`]);
    }

    // Held buttons repeat quickly; apply at most every 80 ms.
    Timer {
        id: applyDelay
        interval: 80
        onTriggered: root.apply()
    }

    // hyprsunset reports 6000 when on identity; anything warmer means the filter is on.
    Process {
        id: query
        command: ["sh", "-c", "pidof hyprsunset >/dev/null && hyprctl hyprsunset temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseInt(text);
                root.active = !isNaN(t) && t < 6000;
            }
        }
    }

    FileView {
        path: `${Quickshell.env("HOME")}/.local/state/quickshell-base/nightlight.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: settings
            property int temperature: 4500
        }
    }

    Component.onCompleted: refresh()
}
