pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Which bar popup is open, and on which monitor. Only one at a time. Also exposed over IPC:
//   qs -c base ipc call quicksettings toggle
//   qs -c base ipc call dashboard toggle
//   qs -c base ipc call wallpapers toggle
//   qs -c base ipc call windows toggle
//   qs -c base ipc call theme toggle
//   qs -c base ipc call launcher toggle   (bound to a lone Super tap)
//   qs -c base ipc call carousel toggle   (wallpaper carousel, SUPER+ALT+W)
//   qs -c base ipc call bar toggle|show|hide   (SUPER+J / SUPER+ALT+B)
Singleton {
    id: root

    // Bar shown/hidden on every monitor. Popups are their own windows, so they still open while it's hidden.
    property bool barVisible: true

    property string popup: ""   // "", "quicksettings", "dashboard", "wallpapers", "theme", "windows", "launcher" or "carousel"
    property string screen: ""  // monitor name the popup is on

    // The Settings window is a real (floating) window, not a bar popup, so it's tracked separately and can
    // stay open alongside popups.
    property bool settingsOpen: false
    property string settingsPage: "network"

    function openSettings(page) {
        if (page) settingsPage = page;
        close();
        settingsOpen = true;
    }

    function isOpen(name, screenName) {
        return popup === name && screen === screenName;
    }

    function toggle(name, screenName) {
        if (isOpen(name, screenName)) {
            close();
        } else {
            popup = name;
            screen = screenName;
        }
    }

    function close() {
        popup = "";
    }

    // The window overview shows screenshots, so snap first (with every popup gone, so none of
    // them end up in the pictures), then open.
    function toggleWindows(screenName) {
        if (isOpen("windows", screenName)) {
            close();
            return;
        }
        const wasOpen = popup !== "";
        close();
        snapDelay.screenName = screenName;
        if (wasOpen) snapDelay.restart();
        else snapDelay.triggered();
    }

    Timer {
        id: snapDelay
        property string screenName
        interval: 260 // popup fade-out
        onTriggered: Previews.capture(() => root.toggle("windows", screenName), Previews.openMaxAge)
    }

    component PopupIpc: IpcHandler {
        function toggle(): void {
            const screenName = Hyprland.focusedMonitor?.name ?? "";
            if (target === "windows") root.toggleWindows(screenName);
            else root.toggle(target, screenName);
        }
        function close(): void {
            root.close();
        }
    }

    // qs -c base ipc call settings toggle | open <page> | close
    //   pages: network bluetooth tailscale display sound hyprland appearance
    IpcHandler {
        target: "settings"

        function toggle(): void {
            if (root.settingsOpen) root.settingsOpen = false;
            else root.openSettings("");
        }
        function open(page: string): void {
            root.openSettings(page);
        }
        function close(): void {
            root.settingsOpen = false;
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.barVisible = !root.barVisible;
        }
        function show(): void {
            root.barVisible = true;
        }
        function hide(): void {
            root.barVisible = false;
        }
    }

    PopupIpc {
        target: "quicksettings"
    }
    PopupIpc {
        target: "dashboard"
    }
    PopupIpc {
        target: "wallpapers"
    }
    PopupIpc {
        target: "windows"
    }
    PopupIpc {
        target: "theme"
    }
    PopupIpc {
        target: "launcher"
    }
    PopupIpc {
        target: "carousel"
    }
}
