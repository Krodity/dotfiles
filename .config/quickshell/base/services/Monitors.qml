pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Monitor layout for Settings → Display. `draft` is what the page edits; apply() pushes it to Hyprland live
// (hyprctl eval 'hl.monitor({…})'), then asks to keep it: nothing is kept unless confirmed within
// `confirmSeconds`, otherwise the previous layout comes back. keep() writes ~/.config/hypr/monitors.lua,
// which hyprland.lua loads after custom/general.lua, so its rules win.
Singleton {
    id: root

    readonly property string configPath: `${Quickshell.env("HOME")}/.config/hypr/monitors.lua`
    readonly property int confirmSeconds: 15

    // One entry per output (disabled ones too):
    // { name, match, label, w, h, rate, x, y, scale, transform, disabled, modes: [{ w, h, rate, text }] }
    property var live: []
    property var draft: []
    property var before: null       // layout before the pending apply; restored if not confirmed
    property int countdown: 0       // > 0 while waiting for "Keep"
    property bool busy: false
    property string error: ""
    property bool identify: false   // big labels on every screen

    readonly property bool dirty: JSON.stringify(strip(draft)) !== JSON.stringify(strip(live))

    function strip(list) {
        return list.map(m => [m.name, m.w, m.h, m.rate, Math.round(m.x), Math.round(m.y), m.scale, m.transform, m.disabled]);
    }

    function refresh() {
        if (!query.running) query.running = true;
    }

    // Logical size (what positions are measured in): pixels / scale, swapped when rotated 90°/270°.
    function logical(m) {
        const w = Math.round(m.w / m.scale), h = Math.round(m.h / m.scale);
        return m.transform % 2 === 1 ? { w: h, h: w } : { w, h };
    }

    function update(i, changes) {
        const copy = draft.slice();
        copy[i] = Object.assign({}, copy[i], changes);
        draft = copy;
    }

    readonly property var enabledIdx: draft.map((m, i) => i).filter(i => !draft[i].disabled)

    // Shift everything so the layout starts at 0,0 (Hyprland doesn't need it, but it keeps numbers readable).
    function normalize() {
        const on = enabledIdx.map(i => draft[i]);
        if (on.length === 0) return;
        const x0 = Math.min(...on.map(m => m.x)), y0 = Math.min(...on.map(m => m.y));
        if (x0 === 0 && y0 === 0) return;
        draft = draft.map(m => m.disabled ? m : Object.assign({}, m, { x: Math.round(m.x - x0), y: Math.round(m.y - y0) }));
    }

    // Side by side in their current left-to-right order, vertically centred on the tallest.
    function autoArrange() {
        const order = enabledIdx.slice().sort((a, b) => draft[a].x - draft[b].x);
        const maxH = Math.max(...order.map(i => logical(draft[i]).h));
        const copy = draft.slice();
        let x = 0;
        for (const i of order) {
            const sz = logical(copy[i]);
            copy[i] = Object.assign({}, copy[i], { x, y: Math.round((maxH - sz.h) / 2) });
            x += sz.w;
        }
        draft = copy;
    }

    // Problems with the draft layout, as a sentence ("" = fine).
    readonly property string layoutWarning: {
        const on = enabledIdx.map(i => ({ m: draft[i], s: logical(draft[i]) }));
        const overlap = (a, b) => a.m.x < b.m.x + b.s.w && b.m.x < a.m.x + a.s.w && a.m.y < b.m.y + b.s.h && b.m.y < a.m.y + a.s.h;
        const touch = (a, b) => {
            const xTouch = a.m.x + a.s.w === b.m.x || b.m.x + b.s.w === a.m.x;
            const yTouch = a.m.y + a.s.h === b.m.y || b.m.y + b.s.h === a.m.y;
            const yOver = a.m.y < b.m.y + b.s.h && b.m.y < a.m.y + a.s.h;
            const xOver = a.m.x < b.m.x + b.s.w && b.m.x < a.m.x + a.s.w;
            return (xTouch && yOver) || (yTouch && xOver);
        };
        for (let i = 0; i < on.length; i++)
            for (let j = i + 1; j < on.length; j++)
                if (overlap(on[i], on[j])) return `${on[i].m.label} and ${on[j].m.label} overlap.`;
        if (on.length > 1)
            for (let i = 0; i < on.length; i++)
                if (!on.some((o, j) => j !== i && touch(on[i], o)))
                    return `${on[i].m.label} doesn't touch another monitor, so the pointer can't reach it.`;
        return "";
    }

    function reset() {
        draft = JSON.parse(JSON.stringify(live));
    }

    function modeString(m) {
        return `${m.w}x${m.h}@${m.rate}`;
    }

    // Hyprland's "highrr" = the fastest mode. Persisted as "highrr" when that's what was chosen: if the link ever
    // offers fewer modes (the Samsung once came up 60 Hz-only), a hard-coded mode fails the atomic commit and takes
    // every monitor down with it; "highrr" just picks what's there.
    function isHighrr(m) {
        const best = m.modes.slice().sort((a, b) => (b.rate - a.rate) || (b.w * b.h - a.w * a.h))[0];
        return best && best.w === m.w && best.h === m.h && Math.abs(best.rate - m.rate) < 0.01;
    }

    function rule(m, forFile) {
        if (m.disabled) return `hl.monitor({ output = "${forFile ? m.match : m.name}", disabled = true })`;
        const mode = forFile && isHighrr(m) ? "highrr" : modeString(m);
        return `hl.monitor({ output = "${forFile ? m.match : m.name}", mode = "${mode}", position = "${Math.round(m.x)}x${Math.round(m.y)}", scale = ${m.scale}, transform = ${m.transform} })`;
    }

    function run(rules) {
        busy = true;
        error = "";
        applyProc.command = ["sh", "-c", 'for r in "$@"; do out=$(hyprctl eval "$r" 2>&1); [ "$out" = ok ] || echo "$out"; done', "sh", ...rules];
        applyProc.running = true;
    }

    function apply() {
        if (!dirty || busy) return;
        if (draft.every(m => m.disabled)) {
            error = "At least one monitor has to stay on.";
            return;
        }
        before = JSON.parse(JSON.stringify(live));
        // Enabled outputs first, so a monitor being switched off always has somewhere to send its workspaces.
        run(draft.slice().sort((a, b) => a.disabled - b.disabled).map(m => rule(m, false)));
        countdown = confirmSeconds;
    }

    function keep() {
        countdown = 0;
        before = null;
        save();
    }

    function revert() {
        countdown = 0;
        if (!before) return;
        const old = before;
        before = null;
        draft = JSON.parse(JSON.stringify(old));
        run(old.slice().sort((a, b) => a.disabled - b.disabled).map(m => rule(m, false)));
    }

    function save() {
        const stamp = new Date().toISOString().slice(0, 10);
        const lines = [
            `-- Written by the quickshell \`base\` Settings → Display page (${stamp}).`,
            "-- hyprland.lua loads this after custom/general.lua, so these rules win over the ones there.",
            "-- Delete this file to fall back to custom/general.lua. \"highrr\" = the monitor's fastest mode.",
            ...live.map(m => rule(m, true)),
            ""
        ];
        saveProc.command = ["sh", "-c", 'f="$1"; [ -f "$f" ] && cp "$f" "$f.bak.$(date +%s)"; printf "%s" "$2" > "$f"', "sh", configPath, lines.join("\n")];
        saveProc.running = true;
    }

    Process {
        id: query
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = [];
                try {
                    list = JSON.parse(text);
                } catch (e) {
                    return;
                }
                const parsed = list.map(o => {
                    const modes = (o.availableModes ?? []).map(s => {
                        const r = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(s);
                        return r ? { w: +r[1], h: +r[2], rate: +r[3], text: r[3] } : null;
                    }).filter(Boolean);
                    // Snap the live rate to the listed mode it came from (143.981 → "143.98").
                    const same = modes.filter(md => md.w === o.width && md.h === o.height);
                    const near = same.sort((a, b) => Math.abs(a.rate - o.refreshRate) - Math.abs(b.rate - o.refreshRate))[0];
                    return {
                        name: o.name,
                        // desc: prefix match. The Dell's full description (with its "#…" serial) doesn't match, so
                        // make + model it is — same as custom/general.lua.
                        match: `desc:${o.make} ${o.model}`,
                        label: o.model || o.name,
                        w: o.width,
                        h: o.height,
                        rate: near ? near.rate : Math.round(o.refreshRate * 100) / 100,
                        x: o.x,
                        y: o.y,
                        scale: o.scale,
                        transform: o.transform,
                        disabled: o.disabled,
                        modes
                    };
                }).sort((a, b) => (a.disabled - b.disabled) || (a.x - b.x));
                const wasClean = !root.dirty;
                root.live = parsed;
                if (wasClean || root.draft.length !== parsed.length) root.reset();
            }
        }
    }

    Process {
        id: applyProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                if (text.trim()) root.error = text.trim().split("\n").pop();
                settle.restart();
            }
        }
    }

    // Hyprland finishes the modeset (and may adjust an invalid scale) a moment after eval returns.
    Timer {
        id: settle
        interval: 700
        onTriggered: {
            root.draft = [];   // take whatever Hyprland ended up with
            root.refresh();
        }
    }

    Process {
        id: saveProc
        onExited: code => {
            if (code !== 0) root.error = `Couldn't write ${root.configPath}`;
        }
    }

    Timer {
        running: root.countdown > 0
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--;
            if (root.countdown === 0) root.revert();
        }
    }

    Timer {
        running: root.identify
        interval: 2500
        onTriggered: root.identify = false
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2", "configreloaded"].includes(event.name))
                root.refresh();
        }
    }

    Component.onCompleted: refresh()
}
