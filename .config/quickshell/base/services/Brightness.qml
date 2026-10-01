pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// External-monitor brightness over DDC/CI (ddcutil). One slider value (0..1) applied to every DDC display,
// each scaled to its own max — monitors differ (the Dell AW3821DW reports 0..450, the Samsung 0..100).
Singleton {
    id: root

    property var displays: []  // [{ bus, max }]
    property real value: 0.5
    readonly property bool available: displays.length > 0
    readonly property string icon: value < 0.34 ? "brightness_low" : value < 0.67 ? "brightness_medium" : "brightness_high"

    property bool pending: false

    signal userChanged  // a set() call (slider, IPC) — the OSD listens; the startup read doesn't fire it

    function set(v) {
        value = Math.max(0, Math.min(1, v));
        userChanged();
        debounce.restart();
    }

    function apply() {
        if (setProc.running) {
            pending = true;
            return;
        }
        setProc.command = ["sh", "-c", displays.map(d => `ddcutil -b ${d.bus} --noverify setvcp 10 ${Math.round(value * d.max)}`).join(" & ") + "; wait"];
        setProc.running = true;
    }

    // Find DDC buses ("Invalid display" blocks have no DDC), then read each one's current/max.
    // Output per bus: "<bus> VCP 10 C <current> <max>"
    Process {
        running: true
        command: ["sh", "-c", `
            for b in $(ddcutil detect --brief 2>/dev/null | awk '/^Display/{d=1} /^Invalid/{d=0} d && /I2C bus/{sub(".*i2c-","");print}'); do
                echo "$b $(ddcutil -b $b getvcp 10 --brief 2>/dev/null | grep '^VCP')"
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                let first = -1;
                for (const line of text.trim().split("\n")) {
                    const p = line.trim().split(/\s+/);
                    if (p.length < 6 || !(Number(p[5]) > 0)) continue;
                    found.push({ bus: p[0], max: Number(p[5]) });
                    if (first < 0) first = Number(p[4]) / Number(p[5]);
                }
                root.displays = found;
                if (first >= 0) root.value = first;
            }
        }
    }

    Process {
        id: setProc
        onExited: if (root.pending) {
            root.pending = false;
            root.apply();
        }
    }

    Timer {
        id: debounce
        interval: 200
        onTriggered: root.apply()
    }
}
