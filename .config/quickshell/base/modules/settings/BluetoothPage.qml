import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Settings → Bluetooth: adapter power + visibility, paired devices (connect / trust / forget), and a scan for new
// devices to pair. Scanning runs only while this page is open.
ColumnLayout {
    id: root

    readonly property var adapter: Bt.adapter
    readonly property var nearby: adapter
        ? [...adapter.devices.values].filter(d => !d.paired && !d.connected && (d.name || d.deviceName))
            .sort((a, b) => Bt.displayName(a).localeCompare(Bt.displayName(b)))
        : []

    spacing: 18
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    function stateText(d) {
        if (d.pairing) return "Pairing…";
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…";
        if (!d.connected) return d.trusted ? "Trusted" : "Paired";
        return d.batteryAvailable ? `Connected · ${Math.round(d.battery * 100)}%` : "Connected";
    }

    Card {
        title: "Adapter"

        SettingRow {
            label: "Bluetooth"
            hint: !root.adapter ? "No adapter found" : `${root.adapter.name} · ${Bt.status}`

            Switch {
                enabled: root.adapter !== null
                checked: Bt.enabled
                onToggled: Bt.toggle()
            }
        }

        SettingRow {
            label: "Visible to other devices"
            enabled: Bt.enabled
            opacity: enabled ? 1 : 0.4

            Switch {
                checked: root.adapter?.discoverable ?? false
                onToggled: root.adapter.discoverable = !root.adapter.discoverable
            }
        }
    }

    Card {
        title: "My devices"

        StyledText {
            visible: Bt.devices.length === 0
            text: Bt.enabled ? "No paired devices" : "Bluetooth is off"
            color: Appearance.colors.muted
        }

        Repeater {
            model: Bt.devices

            RowLayout {
                id: dev
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                MaterialIcon {
                    icon: Bt.deviceIcon(dev.modelData)
                    color: dev.modelData.connected ? Appearance.colors.accent : Appearance.colors.fg
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Bt.displayName(dev.modelData)
                        font.bold: dev.modelData.connected
                        elide: Text.ElideRight
                    }
                    StyledText {
                        text: `${root.stateText(dev.modelData)} · ${dev.modelData.address}`
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }
                }
                PillButton {
                    text: dev.modelData.trusted ? "Untrust" : "Trust"
                    onClicked: dev.modelData.trusted = !dev.modelData.trusted
                }
                PillButton {
                    text: "Forget"
                    onClicked: dev.modelData.forget()
                }
                PillButton {
                    enabled: Bt.enabled
                    primary: !dev.modelData.connected
                    text: dev.modelData.connected ? "Disconnect" : "Connect"
                    onClicked: dev.modelData.connected ? dev.modelData.disconnect() : dev.modelData.connect()
                }
            }
        }
    }

    Card {
        title: "Add a device"
        enabled: Bt.enabled
        opacity: enabled ? 1 : 0.4

        SettingRow {
            label: root.adapter?.discovering ? "Searching…" : "Search for devices"
            hint: "Put the device in pairing mode first."

            PillButton {
                icon: root.adapter?.discovering ? "stop" : "search"
                text: root.adapter?.discovering ? "Stop" : "Scan"
                onClicked: root.adapter.discovering = !root.adapter.discovering
            }
        }

        Repeater {
            model: root.nearby

            RowLayout {
                id: near
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                MaterialIcon {
                    icon: Bt.deviceIcon(near.modelData)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Bt.displayName(near.modelData)
                        elide: Text.ElideRight
                    }
                    StyledText {
                        text: near.modelData.pairing ? "Pairing…" : near.modelData.address
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }
                }
                PillButton {
                    primary: true
                    text: near.modelData.pairing ? "Cancel" : "Pair"
                    onClicked: {
                        const d = near.modelData;
                        if (d.pairing) {
                            d.cancelPair();
                            return;
                        }
                        d.trusted = true;   // so it reconnects on its own later
                        d.pair();
                    }
                }
            }
        }
    }
}
