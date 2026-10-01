pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// App list + search for the launcher. Ranks by match quality, then by how often you launch it.
// Launch counts live in ~/.local/state/quickshell-base/launcher.json.
Singleton {
    id: root

    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    function iconFor(entry) {
        const name = entry?.icon ?? "";
        if (name.startsWith("/")) return `file://${name}`;
        return Quickshell.iconPath(name, true) || Quickshell.iconPath("application-x-executable");
    }

    // Letters of q appear in s in order. Tighter runs score higher; 0 = no match.
    function subsequence(s, q) {
        let si = 0, score = 0, run = 0;
        for (const ch of q) {
            const at = s.indexOf(ch, si);
            if (at < 0) return 0;
            run = at === si ? run + 1 : 0;
            score += 1 + run * 2;
            si = at + 1;
        }
        return score;
    }

    function score(entry, q) {
        const name = entry.name.toLowerCase();
        if (name === q) return 1000;
        if (name.startsWith(q)) return 800;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 600;
        if (name.includes(q)) return 400;
        const extra = [entry.genericName, entry.comment, entry.id, ...(entry.keywords ?? [])].join(" ").toLowerCase();
        if (extra.includes(q)) return 250;
        const fuzzy = subsequence(name, q);
        return fuzzy >= q.length * 2 ? 100 + fuzzy : 0;
    }

    function search(text) {
        const q = text.trim().toLowerCase();
        const uses = counts.uses;
        const bonus = e => Math.min(uses[e.id] ?? 0, 50) * 4;
        if (!q) return apps.slice().sort((a, b) => bonus(b) - bonus(a) || a.name.localeCompare(b.name));
        return apps
            .map(e => ({ e, s: score(e, q) }))
            .filter(r => r.s > 0)
            .sort((a, b) => (b.s + bonus(b.e)) - (a.s + bonus(a.e)) || a.e.name.localeCompare(b.e.name))
            .map(r => r.e);
    }

    // Through uwsm-app so each app gets its own systemd scope (and Terminal=true entries get a terminal).
    function launch(entry) {
        if (!entry) return;
        Quickshell.execDetached(["uwsm-app", "--", `${entry.id}.desktop`]);
        const uses = Object.assign({}, counts.uses);
        uses[entry.id] = (uses[entry.id] ?? 0) + 1;
        counts.uses = uses;
    }

    FileView {
        path: `${Quickshell.env("HOME")}/.local/state/quickshell-base/launcher.json`
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: counts
            property var uses: ({})
        }
    }
}
