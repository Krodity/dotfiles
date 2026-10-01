pragma Singleton

import Quickshell
import QtQuick

// Icons for windows (HyprlandToplevel). Tries the desktop entry's icon, then the raw app id, then generic.
Singleton {
    function appId(toplevel) {
        return toplevel?.wayland?.appId || toplevel?.lastIpcObject?.class || "";
    }

    // Touching applications.values re-runs callers once the desktop entry scan finishes.
    function iconFor(toplevel) {
        const id = appId(toplevel);
        const entry = DesktopEntries.applications.values.length >= 0 ? DesktopEntries.heuristicLookup(id) : null;
        for (const name of [entry?.icon, id, id.toLowerCase(), id.split(".").pop().toLowerCase()]) {
            if (!name) continue;
            if (name.startsWith("/")) return `file://${name}`;
            const path = Quickshell.iconPath(name, true);
            if (path) return path;
        }
        return Quickshell.iconPath("application-x-executable");
    }
}
