pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Per-tab media inside browsers. A browser has ONE MPRIS player for all its tabs (it follows whichever
// played last), so the tabs come from the Beam extension via scripts/browser-tabs.py instead.
// Starting a tab pauses that browser's other tabs, so its MPRIS player (and the media card) moves to it.
Singleton {
    id: root

    property var hosts: []       // [{ id, name, brand, tabs: [{ id, pageTitle, site, title, artist, playing, … }] }]
    property int watchers: 0     // > 0 while something shows the tabs → poll
    property string error: ""

    readonly property string script: Quickshell.shellPath("scripts/browser-tabs.py")

    // The Beam host for an MPRIS player, matched by name: identity "Chrome" ↔ brand "Google Chrome",
    // "Chromium" ↔ "Chromium". null for non-browsers or a browser without the extension.
    function hostFor(player) {
        const id = (player?.identity ?? "").toLowerCase();
        if (!id) return null;
        return hosts.find(h => h.brand.toLowerCase().includes(id)) ?? null;
    }

    function tabsFor(player) {
        return hostFor(player)?.tabs ?? [];
    }

    function refresh() {
        if (!lister.running) lister.running = true;
    }

    function play(hostId, tabId) { run("play", hostId, tabId); }
    function pause(hostId, tabId) { run("pause", hostId, tabId); }
    function show(hostId, tabId) { run("show", hostId, tabId); }

    function run(cmd, hostId, tabId) {
        actor.running = false;
        actor.command = [script, cmd, hostId, String(tabId)];
        actor.running = true;
    }

    Process {
        id: lister
        command: [root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    root.hosts = r.hosts ?? [];
                    root.error = r.error ?? "";
                } catch (e) {
                    root.hosts = [];
                }
            }
        }
    }

    Process {
        id: actor
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.error = JSON.parse(text).error ?? ""; } catch (e) {}
                settle.restart();
            }
        }
    }

    // Re-read shortly after an action so play/pause icons catch up.
    Timer {
        id: settle
        interval: 500
        onTriggered: root.refresh()
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.watchers > 0
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
