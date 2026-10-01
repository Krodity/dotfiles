pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// File search for the launcher: `fd` over $HOME, live (no index). Skips hidden files and anything
// .gitignore'd, like fd does by default. Queries under 2 chars don't search. Debounced; a new query
// kills the one still running. Enter opens with xdg-open, Shift+Enter opens the containing folder.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property int maxShown: 20
    property var results: []
    property string pending: ""

    function search(text) {
        const q = text.trim();
        pending = q;
        if (q.length < 2) {
            debounce.stop();
            results = [];
            return;
        }
        debounce.restart();
    }

    function words(s) {
        return s.split(/[\s\-_.]+/);
    }

    function rank(lines, q) {
        const lq = q.toLowerCase();
        const out = [];
        for (const line of lines) {
            if (!line) continue;
            const isDir = line.endsWith("/");
            const path = isDir ? line.slice(0, -1) : line;
            const slash = path.lastIndexOf("/");
            const name = path.slice(slash + 1);
            const ln = name.toLowerCase();
            // fd matched it for the query that was running; drop leftovers from an older query.
            if (!ln.includes(lq)) continue;
            let s = ln === lq ? 1000 : ln.startsWith(lq) ? 800 : words(ln).some(w => w.startsWith(lq)) ? 600 : 400;
            s -= path.split("/").length * 10; // shallower first
            out.push({ kind: "file", path, name, isDir, dir: path.slice(0, slash).replace(root.home, "~"), s });
        }
        return out.sort((a, b) => b.s - a.s || a.name.length - b.name.length).slice(0, maxShown);
    }

    // Papirus mimetype icon from the extension; good enough without a mime lookup per row.
    function iconFor(item) {
        if (item.isDir) return Quickshell.iconPath("folder");
        const ext = item.name.includes(".") ? item.name.split(".").pop().toLowerCase() : "";
        const map = {
            png: "image-x-generic", jpg: "image-x-generic", jpeg: "image-x-generic", gif: "image-x-generic",
            webp: "image-x-generic", svg: "image-x-generic", avif: "image-x-generic",
            mp4: "video-x-generic", mkv: "video-x-generic", webm: "video-x-generic", mov: "video-x-generic", avi: "video-x-generic",
            mp3: "audio-x-generic", flac: "audio-x-generic", ogg: "audio-x-generic", wav: "audio-x-generic", m4a: "audio-x-generic", opus: "audio-x-generic",
            pdf: "application-pdf", zip: "application-zip", "7z": "package-x-generic", tar: "package-x-generic",
            gz: "package-x-generic", xz: "package-x-generic", zst: "package-x-generic", rar: "package-x-generic",
            apk: "application-vnd.android.package-archive", json: "application-json", html: "text-html",
            md: "text-markdown", py: "text-x-python", sh: "text-x-script", lua: "text-x-script",
            doc: "x-office-document", docx: "x-office-document", odt: "x-office-document",
            xls: "x-office-spreadsheet", xlsx: "x-office-spreadsheet", ods: "x-office-spreadsheet", csv: "x-office-spreadsheet",
            ppt: "x-office-presentation", pptx: "x-office-presentation", odp: "x-office-presentation"
        };
        return Quickshell.iconPath(map[ext] ?? "text-x-generic", true) || Quickshell.iconPath("unknown");
    }

    function open(item, inFolder) {
        if (!item) return;
        const target = inFolder ? item.path.slice(0, item.path.lastIndexOf("/")) || "/" : item.path;
        Quickshell.execDetached(["uwsm-app", "--", "xdg-open", target]);
    }

    Timer {
        id: debounce

        interval: 120
        onTriggered: {
            proc.query = root.pending;
            proc.exec(["fd", "--ignore-case", "--fixed-strings", "--max-results", "300",
                "--exclude", "node_modules", "--", root.pending, root.home]);
        }
    }

    Process {
        id: proc

        property string query

        stdout: StdioCollector {
            onStreamFinished: {
                if (proc.query === root.pending) root.results = root.rank(text.split("\n"), proc.query);
            }
        }
    }
}
