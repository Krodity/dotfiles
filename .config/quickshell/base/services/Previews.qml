pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Window snapshots for the overview. Only windows on visible workspaces can be captured, so each
// workspace switch re-snaps what's on screen; hidden workspaces keep the last picture taken
// Pictures live in $XDG_RUNTIME_DIR (tmpfs): they survive shell reloads but are gone at logout/reboot.
// Throttled: event-driven snaps skip windows captured in the last `eventMaxAge` seconds.
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/quickshell-base/previews`
    readonly property int eventMaxAge: 60   // workspace/window events
    readonly property int openMaxAge: 10    // opening the overview
    property int maxAge: 0                  // age limit for the snap in flight
    property int nextMaxAge: -1             // queued snap's limit (-1 = none queued)
    property var stamps: ({})   // address (no 0x) → capture counter; appended to the URL to bust Qt's image cache
    property int counter: 0
    property var pending: []    // callbacks to run after the capture in flight
    property bool again: false

    function key(address) {
        return String(address ?? "").replace(/^0x/, "");
    }

    function sourceFor(address) {
        const k = key(address);
        return stamps[k] ? `file://${dir}/${k}.jpg?v=${stamps[k]}` : "";
    }

    // Snap now, skipping windows whose picture is younger than `age` seconds (0 = re-snap all);
    // run `then` (optional) once done.
    function capture(then, age) {
        age = age ?? 0;
        if (then) pending.push(then);
        if (snap.running) {
            again = true;
            nextMaxAge = nextMaxAge < 0 ? age : Math.min(nextMaxAge, age);
        } else {
            maxAge = age;
            snap.running = true;
        }
    }

    Process {
        id: snap
        command: [Quickshell.shellPath("scripts/snap-windows.sh"), root.dir, String(root.maxAge)]
        stdout: SplitParser {
            onRead: address => {
                root.counter++;
                root.stamps = Object.assign({}, root.stamps, { [address]: root.counter });
            }
        }
        onExited: {
            if (root.again) {
                root.again = false;
                root.maxAge = root.nextMaxAge;
                root.nextMaxAge = -1;
                running = true;
                return;
            }
            const callbacks = root.pending;
            root.pending = [];
            callbacks.forEach(f => f());
        }
    }

    // Let the switch animation finish before snapping.
    Timer {
        id: settle
        interval: 1500
        onTriggered: root.capture(null, root.eventMaxAge)
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["workspacev2", "focusedmonv2", "openwindow", "movewindowv2", "closewindow"].includes(event.name))
                settle.restart();
        }
    }

    // Pick up snapshots from earlier runs (stamps only live in memory, so a reload/restart would
    // otherwise leave every hidden workspace showing icons until it's visited again).
    Process {
        id: seed
        command: ["find", root.dir, "-maxdepth", "1", "-name", "*.jpg", "-printf", "%f\\n"]
        stdout: SplitParser {
            onRead: name => {
                const k = name.replace(/\.jpg$/, "");
                if (root.stamps[k]) return;
                root.counter++;
                root.stamps = Object.assign({}, root.stamps, { [k]: root.counter });
            }
        }
        onExited: root.capture(null, root.eventMaxAge)
    }

    Component.onCompleted: seed.running = true
}
