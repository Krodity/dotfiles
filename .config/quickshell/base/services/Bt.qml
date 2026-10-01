pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// BlueZ adapter + paired devices. Named Bt to avoid clashing with the Bluetooth singleton.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: adapter
        ? [...adapter.devices.values].filter(d => d.paired || d.connected).sort((a, b) => (b.connected - a.connected) || displayName(a).localeCompare(displayName(b)))
        : []
    readonly property var connected: devices.filter(d => d.connected)

    readonly property string status: !adapter ? "No adapter" : !enabled ? "Off"
        : connected.length === 1 ? displayName(connected[0])
        : connected.length > 1 ? `${connected.length} devices` : "On"

    function displayName(d) {
        return d.name || d.deviceName || d.address;
    }

    // Map freedesktop icon names (audio-headset, input-mouse, ...) to Material Symbols.
    function deviceIcon(d) {
        const i = d.icon ?? "";
        if (i.includes("headset") || i.includes("headphone")) return "headphones";
        if (i.includes("audio") || i.includes("speaker")) return "speaker";
        if (i.includes("mouse")) return "mouse";
        if (i.includes("keyboard")) return "keyboard";
        if (i.includes("gaming") || i.includes("joystick")) return "sports_esports";
        if (i.includes("phone")) return "smartphone";
        return "bluetooth";
    }

    function toggle() {
        if (adapter) adapter.enabled = !adapter.enabled;
    }
}
