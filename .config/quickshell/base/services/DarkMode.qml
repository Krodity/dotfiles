pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// System-wide light/dark preference for apps (GTK, libadwaita, portal-aware apps like browsers).
// Same gsettings keys end4-pC's switchwall.sh sets. Also flips the shell's own colours (Theme.dark) — bg ↔ text.
Singleton {
    id: root

    property bool dark: true
    onDarkChanged: Theme.dark = dark

    function refresh() {
        if (!query.running) query.running = true;
    }

    function toggle() {
        dark = !dark;
        Quickshell.execDetached(["sh", "-c",
            `gsettings set org.gnome.desktop.interface color-scheme ${dark ? "prefer-dark" : "prefer-light"}; `
            + `gsettings set org.gnome.desktop.interface gtk-theme ${dark ? "adw-gtk3-dark" : "adw-gtk3"}`]);
    }

    Process {
        id: query
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        stdout: StdioCollector {
            onStreamFinished: root.dark = !text.includes("prefer-light")
        }
    }

    Component.onCompleted: refresh()
}
