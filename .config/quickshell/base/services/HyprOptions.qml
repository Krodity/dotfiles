pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Hyprland options for Settings → Hyprland. set() applies live (hyprctl eval 'hl.config({…})') and persists the
// value as one line in ~/.config/hypr/hyprland/shellOverrides/main.lua — the file hyprland.lua loads LAST, in the
// same one-option-per-line format end4-pC writes, so both shells can keep editing it.
Singleton {
    id: root

    readonly property string overridesPath: `${Quickshell.env("HOME")}/.config/hypr/hyprland/shellOverrides/main.lua`

    // key → "str" | "int" | "float" | "bool" | "gap" (css gap, edited as one number)
    readonly property var types: ({
        "general:layout": "str",
        "general:gaps_in": "gap",
        "general:gaps_out": "gap",
        "general:border_size": "int",
        "general:resize_on_border": "bool",
        "decoration:rounding": "int",
        "decoration:active_opacity": "float",
        "decoration:inactive_opacity": "float",
        "decoration:dim_inactive": "bool",
        "decoration:dim_strength": "float",
        "decoration:blur:enabled": "bool",
        "decoration:blur:size": "int",
        "decoration:blur:passes": "int",
        "decoration:shadow:enabled": "bool",
        "animations:enabled": "bool",
        "dwindle:preserve_split": "bool",
        "master:orientation": "str",
        "master:new_status": "str",
        "scrolling:column_width": "float",
        "input:follow_mouse": "int",
        "input:sensitivity": "float",
        "input:repeat_rate": "int",
        "input:repeat_delay": "int",
        "input:natural_scroll": "bool",
        "misc:vrr": "int"
    })

    property var values: ({})
    property var pending: ({})   // key → value waiting for the debounced live apply + save
    property string error: ""

    function get(key, fallback) {
        return values[key] ?? fallback;
    }

    function set(key, value) {
        if (types[key] === "int" || types[key] === "gap") value = Math.round(value);
        if (types[key] === "float") value = Math.round(value * 1000) / 1000;
        const v = Object.assign({}, values);
        v[key] = value;
        values = v;
        const p = Object.assign({}, pending);
        p[key] = value;
        pending = p;
        flush.restart();
    }

    function refresh() {
        if (!query.running) query.running = true;
    }

    // "decoration:blur:enabled", true → "decoration = { blur = { enabled = true } }"
    function luaTable(key, value) {
        const parts = key.split(":");
        const lit = typeof value === "string" ? `"${value}"` : String(value);
        let out = `${parts[parts.length - 1]} = ${lit}`;
        for (let i = parts.length - 2; i >= 0; i--) out = `${parts[i]} = { ${out} }`;
        return out;
    }

    function line(key, value) {
        return `hl.config({ ${luaTable(key, value)} })`;
    }

    // Same line minus the value: used to find an existing line for that key.
    function linePrefix(key) {
        const t = luaTable(key, "\u0000");
        return `hl.config({ ${t.slice(0, t.indexOf('"\u0000"'))}`;
    }

    Timer {
        id: flush
        interval: 250
        onTriggered: {
            const p = root.pending;
            root.pending = {};
            const keys = Object.keys(p);
            if (keys.length === 0) return;
            applyProc.command = ["sh", "-c", 'for r in "$@"; do out=$(hyprctl eval "$r" 2>&1); [ "$out" = ok ] || echo "$out"; done', "sh",
                ...keys.map(k => line(k, p[k]))];
            applyProc.running = true;
            // Persist: replace the key's line or append it.
            let lines = (file.text() || "").split("\n");
            if (lines.length && lines[lines.length - 1] === "") lines.pop();
            for (const k of keys) {
                const prefix = root.linePrefix(k), l = root.line(k, p[k]);
                const i = lines.findIndex(x => x.startsWith(prefix));
                if (i >= 0) lines[i] = l;
                else lines.push(l);
            }
            file.setText(lines.join("\n") + "\n");
        }
    }

    FileView {
        id: file
        path: root.overridesPath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    Process {
        id: applyProc
        stdout: StdioCollector {
            onStreamFinished: root.error = text.trim().split("\n").filter(Boolean).pop() ?? ""
        }
    }

    Process {
        id: query
        command: ["sh", "-c", 'for o in "$@"; do hyprctl -j getoption "$o" | tr -d "\\n"; echo; done', "sh", ...Object.keys(root.types)]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = {};
                for (const l of text.split("\n")) {
                    let o;
                    try {
                        o = JSON.parse(l);
                    } catch (e) {
                        continue;
                    }
                    if (!o.option) continue;
                    if ("css" in o) v[o.option] = Number(String(o.css).split(" ")[0]);
                    else if ("bool" in o) v[o.option] = o.bool;
                    else if ("int" in o) v[o.option] = o.int;
                    else if ("float" in o) v[o.option] = o.float;
                    else if ("str" in o) v[o.option] = o.str === "[[EMPTY]]" ? "" : o.str;
                }
                root.values = v;
            }
        }
    }
}
