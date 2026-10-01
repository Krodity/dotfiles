pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

// Wi-Fi via NetworkManager (Quickshell.Networking). Named Net to avoid clashing with its Network type.
Singleton {
    id: root

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool enabled: Networking.wifiEnabled
    readonly property var networks: wifiDevice
        ? [...wifiDevice.networks.values].filter(n => n.name).sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
        : []
    readonly property var active: networks.find(n => n.connected) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.hasLink)

    readonly property string icon: !enabled ? (wired ? "lan" : "wifi_off")
        : active ? strengthIcon(active.signalStrength)
        : wired ? "lan" : "signal_wifi_0_bar"

    // signalStrength is 0..1 (normalised defensively in case a backend reports 0..100).
    function strength(s) {
        return s > 1 ? s / 100 : s;
    }

    function strengthIcon(s) {
        const v = strength(s);
        return v > 0.75 ? "network_wifi" : v > 0.5 ? "network_wifi_3_bar" : v > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }

    function toggle() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // Scan only while someone is looking at the list.
    function setScanning(on) {
        if (wifiDevice) wifiDevice.scannerEnabled = on;
    }
}
