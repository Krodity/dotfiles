import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Settings → Network: Wi-Fi on/off + networks (connect / disconnect / forget / password), wired link, and every
// interface's addresses (from `ip -j addr`). NetworkManager only manages wlan0 on this box; the rest is read-only.
ColumnLayout {
    id: root

    property var pskTarget: null
    property var interfaces: []   // [{ name, state, addrs: [..] }]

    spacing: 18
    Component.onCompleted: Net.setScanning(true)
    Component.onDestruction: Net.setScanning(false)

    Card {
        title: "Wi-Fi"

        SettingRow {
            label: "Wi-Fi"
            hint: !Net.wifiDevice ? "No Wi-Fi adapter" : Net.active ? `Connected to ${Net.active.name}` : Net.enabled ? "Not connected" : "Off"

            Switch {
                checked: Net.enabled
                onToggled: Net.toggle()
            }
        }

        // Password prompt (outside the list: list rows are rebuilt on every scan).
        RowLayout {
            visible: root.pskTarget !== null
            Layout.fillWidth: true
            spacing: 6

            TextField {
                id: psk
                Layout.fillWidth: true
                placeholderText: `Password for ${root.pskTarget?.name ?? ""}`
                echoMode: TextInput.Password
                color: Appearance.colors.fg
                placeholderTextColor: Appearance.colors.muted
                font.pixelSize: Appearance.font.size
                leftPadding: 12
                background: Rectangle {
                    radius: 12
                    color: Appearance.colors.surface
                    border.width: psk.activeFocus ? 1 : 0
                    border.color: Appearance.colors.accent
                }
                onVisibleChanged: if (visible) forceActiveFocus()
                onAccepted: join.clicked()
                Keys.onEscapePressed: root.pskTarget = null
            }
            PillButton {
                id: join
                primary: true
                text: "Connect"
                onClicked: {
                    if (psk.text.length > 0) root.pskTarget?.connectWithPsk(psk.text);
                    psk.text = "";
                    root.pskTarget = null;
                }
            }
            PillButton {
                text: "Cancel"
                onClicked: root.pskTarget = null
            }
        }

        StyledText {
            visible: Net.enabled && Net.networks.length === 0
            text: "Scanning…"
            color: Appearance.colors.muted
        }

        Repeater {
            model: Net.enabled ? Net.networks : []

            RowLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                MaterialIcon {
                    icon: Net.strengthIcon(row.modelData.signalStrength)
                    color: row.modelData.connected ? Appearance.colors.accent : Appearance.colors.fg
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        font.bold: row.modelData.connected
                        elide: Text.ElideRight
                    }
                    StyledText {
                        text: [
                            row.modelData.stateChanging ? "Working…" : row.modelData.connected ? "Connected" : row.modelData.known ? "Saved" : "",
                            Net.isOpen(row.modelData) ? "Open" : "Secured",
                            `${Math.round(Net.strength(row.modelData.signalStrength) * 100)}%`
                        ].filter(Boolean).join(" · ")
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }
                }
                PillButton {
                    visible: row.modelData.known
                    text: "Forget"
                    onClicked: row.modelData.forget()
                }
                PillButton {
                    primary: !row.modelData.connected
                    text: row.modelData.connected ? "Disconnect" : "Connect"
                    onClicked: {
                        if (row.modelData.connected) row.modelData.disconnect();
                        else if (row.modelData.known || Net.isOpen(row.modelData)) row.modelData.connect();
                        else root.pskTarget = row.modelData;
                    }
                }
            }
        }
    }

    Card {
        title: "Interfaces"

        Repeater {
            model: root.interfaces

            RowLayout {
                id: iface
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                MaterialIcon {
                    icon: iface.modelData.name.startsWith("wl") ? "wifi"
                        : iface.modelData.name.startsWith("tailscale") ? "hub"
                        : iface.modelData.name.startsWith("en") || iface.modelData.name.startsWith("eth") ? "lan"
                        : "settings_ethernet"
                    color: iface.modelData.up ? Appearance.colors.accent : Appearance.colors.muted
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: iface.modelData.name
                        font.bold: true
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: iface.modelData.addrs.join("   ") || "No address"
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                        wrapMode: Text.WrapAnywhere
                    }
                }
                StyledText {
                    text: iface.modelData.state
                    font.pixelSize: Appearance.font.small
                    color: iface.modelData.up ? Appearance.colors.fg : Appearance.colors.muted
                }
            }
        }
    }

    Process {
        id: ipAddr
        running: true
        command: ["ip", "-j", "addr"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.interfaces = JSON.parse(text)
                        .filter(i => i.ifname !== "lo" && !i.ifname.startsWith("veth"))
                        .map(i => ({
                            name: i.ifname,
                            state: i.operstate === "UNKNOWN" && (i.flags ?? []).includes("UP") ? "UP" : i.operstate,
                            up: (i.flags ?? []).includes("UP") && i.operstate !== "DOWN",
                            addrs: (i.addr_info ?? []).filter(a => a.scope !== "link").map(a => `${a.local}/${a.prefixlen}`)
                        }))
                        .sort((a, b) => (b.up - a.up) || a.name.localeCompare(b.name));
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: ipAddr.running = true
    }
}
