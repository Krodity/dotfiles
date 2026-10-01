pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Tailscale through the CLI — your-user is tailscaled's OperatorUser, so up/down/set need no sudo.
// Polls `tailscale status --json` + `tailscale debug prefs` only while a panel is watching (setWatching).
Singleton {
    id: root

    property bool available: false     // tailscaled answered the last poll
    property string backendState: ""   // Running / Stopped / NeedsLogin / Starting …
    property string ip: ""
    property string exitNodeId: ""     // StableNodeID from prefs; "" = no exit node
    property bool autoExitNode: false  // --exit-node=auto:any
    property bool allowLan: false      // --exit-node-allow-lan-access
    property var ownNodes: []          // [{ id, name, ip, online }] — our own machines offering exit
    property var cities: []            // [{ key, city, country, code, nodes: [{ id, name, ip, online, priority }] }] — Mullvad
    property bool busy: false
    property string error: ""

    readonly property bool running: backendState === "Running"
    readonly property var exitNode: findNode(exitNodeId)
    readonly property string exitLabel: autoExitNode ? `Auto${exitNode ? " · " + nodeLabel(exitNode) : ""}`
        : exitNode ? nodeLabel(exitNode) : exitNodeId ? "Exit node" : ""
    readonly property string status: !available ? "Unavailable"
        : busy ? "…"
        : backendState === "NeedsLogin" ? "Needs login"
        : !running ? "Off"
        : exitLabel ? `Exit: ${exitLabel}${allowLan ? " · LAN" : ""}`
        : ip || "Connected"

    property int watchers: 0
    property string lastNodesJson: ""

    function setWatching(on) {
        watchers = Math.max(0, watchers + (on ? 1 : -1));
        if (on) refresh();
    }

    function refresh() {
        if (!poll.running) poll.running = true;
    }

    function findNode(id) {
        if (!id) return null;
        const own = ownNodes.find(n => n.id === id);
        if (own) return own;
        for (const c of cities) {
            const n = c.nodes.find(n => n.id === id);
            if (n) return Object.assign({ city: c.city, code: c.code }, n);
        }
        return null;
    }

    function nodeLabel(n) {
        return n.city ? `${n.city} (${n.name})` : n.name;
    }

    function run(args) {
        if (busy) return;
        busy = true;
        error = "";
        // Output and exit code come back on one stream, so there's no exit-vs-output ordering race.
        cmd.command = ["sh", "-c", 'out=$(timeout 20 tailscale "$@" 2>&1); c=$?; echo "$out"; echo "$c"', "sh", ...args];
        cmd.running = true;
    }

    function toggle() {
        run([running ? "down" : "up"]);
    }

    // node: an ownNodes entry, a city (→ its best online server), "auto", or null to stop using an exit node.
    function useExitNode(node) {
        if (node === "auto") return run(["set", "--exit-node=auto:any"]);
        if (!node) return run(["set", "--exit-node="]);
        if (node.nodes) {
            const best = node.nodes.filter(n => n.online).sort((a, b) => b.priority - a.priority)[0];
            if (!best) {
                error = `No online server in ${node.city}`;
                return;
            }
            node = best;
        }
        run(["set", `--exit-node=${node.ip}`]);
    }

    function setAllowLan(on) {
        run(["set", `--exit-node-allow-lan-access=${on}`]);
    }

    // Two JSON lines: slimmed status, then the prefs we care about. Either may be missing if tailscaled is down.
    Process {
        id: poll
        command: ["sh", "-c", `
            tailscale status --json 2>/dev/null | jq -c '{
                state: .BackendState,
                ip: (.Self.TailscaleIPs[0] // ""),
                nodes: [(.Peer // {})[] | select(.ExitNodeOption) | {
                    id: .ID, name: .HostName, ip: .TailscaleIPs[0], online: .Online,
                    city: (.Location.City // ""), country: (.Location.Country // ""),
                    code: (.Location.CountryCode // ""), priority: (.Location.Priority // 0)
                }] | sort_by(.id)
            }' || echo '{}'
            tailscale debug prefs 2>/dev/null | jq -c '{
                exit: (.ExitNodeID // ""), auto: ((.AutoExitNode // "") != ""), lan: (.ExitNodeAllowLANAccess // false)
            }' || echo '{}'`]
        stdout: StdioCollector {
            onStreamFinished: {
                let s = {}, p = {};
                try {
                    const lines = text.trim().split("\n");
                    s = JSON.parse(lines[0] || "{}");
                    p = JSON.parse(lines[1] || "{}");
                } catch (e) {}
                root.available = !!s.state;
                root.backendState = s.state ?? "";
                root.ip = s.ip ?? "";
                root.exitNodeId = p.exit ?? "";
                root.autoExitNode = p.auto ?? false;
                root.allowLan = p.lan ?? false;
                // Peers vanish while Stopped — keep the last list. Only rebuild when it changed, so the
                // panel's list isn't recreated (and scrolled) on every poll.
                const nodes = s.nodes ?? [];
                const json = JSON.stringify(nodes);
                if (nodes.length === 0 || json === root.lastNodesJson) return;
                root.lastNodesJson = json;
                const own = [], byCity = {};
                for (const n of nodes) {
                    if (!n.city) {
                        own.push({ id: n.id, name: n.name, ip: n.ip, online: n.online });
                        continue;
                    }
                    const key = `${n.code}|${n.city}`;
                    if (!byCity[key]) byCity[key] = { key, city: n.city, country: n.country, code: n.code, nodes: [] };
                    byCity[key].nodes.push({ id: n.id, name: n.name, ip: n.ip, online: n.online, priority: n.priority });
                }
                root.ownNodes = own.sort((a, b) => (b.online - a.online) || a.name.localeCompare(b.name));
                root.cities = Object.values(byCity).sort((a, b) => a.country.localeCompare(b.country) || a.city.localeCompare(b.city));
            }
        }
    }

    Process {
        id: cmd
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const code = Number(lines.pop());
                const msg = lines.filter(l => l.trim()).pop() ?? "";
                root.busy = false;
                if (code !== 0) root.error = msg || `tailscale exited ${code}`;
                root.refresh();
            }
        }
    }

    Timer {
        running: root.watchers > 0
        repeat: true
        interval: 3000
        onTriggered: root.refresh()
    }

    // One read at startup so the tile has a sublabel before the panel is first opened.
    Component.onCompleted: refresh()
}
