import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Wi-Fi / Bluetooth / Tailscale / night light / dark mode / volume / brightness, hanging under the Wi-Fi island.
BarPopup {
    id: root

    property string section: "" // "", "wifi", "bt", "night", "ts" or "audio" — which detail list is expanded

    name: "quicksettings"
    onOpenChanged: {
        if (!open) section = "";
        Tailscale.setWatching(open);
        if (open) {
            NightLight.refresh();
            DarkMode.refresh();
        }
    }
    onSectionChanged: Net.setScanning(section === "wifi")

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4

        StyledText {
            Layout.fillWidth: true
            text: "Quick settings"
            font.bold: true
            font.pixelSize: 15
        }
        StyledText {
            text: Time.date
            color: Appearance.colors.muted
        }
        HoverRect {
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            onClicked: Panels.openSettings("")

            MaterialIcon {
                anchors.centerIn: parent
                icon: "settings"
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        uniformCellSizes: true
        spacing: 8

        ToggleTile {
            Layout.fillWidth: true
            icon: Net.enabled ? "wifi" : "wifi_off"
            label: "Wi-Fi"
            sublabel: !Net.enabled ? "Off" : Net.active?.name ?? "Not connected"
            checked: Net.enabled
            expanded: root.section === "wifi"
            onToggled: Net.toggle()
            onExpandToggled: root.section = root.section === "wifi" ? "" : "wifi"
        }

        ToggleTile {
            Layout.fillWidth: true
            icon: Bt.enabled ? "bluetooth" : "bluetooth_disabled"
            label: "Bluetooth"
            sublabel: Bt.status
            checked: Bt.enabled
            expanded: root.section === "bt"
            onToggled: Bt.toggle()
            onExpandToggled: root.section = root.section === "bt" ? "" : "bt"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        uniformCellSizes: true
        spacing: 8

        ToggleTile {
            id: nightTile
            Layout.fillWidth: true
            icon: "nightlight"
            label: "Night light"
            sublabel: NightLight.status
            checked: NightLight.active
            expanded: root.section === "night"
            onToggled: NightLight.toggle()
            onExpandToggled: root.section = root.section === "night" ? "" : "night"
        }

        ToggleTile {
            Layout.fillWidth: true
            icon: DarkMode.dark ? "dark_mode" : "light_mode"
            label: "Dark mode"
            sublabel: DarkMode.dark ? "On" : "Off"
            checked: DarkMode.dark
            expandable: false
            onToggled: DarkMode.toggle()
        }
    }

    ToggleTile {
        Layout.fillWidth: true
        icon: !Tailscale.running ? "vpn_lock" : Tailscale.exitLabel ? "vpn_key" : "hub"
        label: "Tailscale"
        sublabel: Tailscale.status
        checked: Tailscale.running
        expanded: root.section === "ts"
        onToggled: Tailscale.toggle()
        onExpandToggled: root.section = root.section === "ts" ? "" : "ts"
    }

    WifiList {
        Layout.fillWidth: true
        visible: root.section === "wifi"
    }

    BluetoothList {
        Layout.fillWidth: true
        visible: root.section === "bt"
    }

    TailscalePanel {
        Layout.fillWidth: true
        visible: root.section === "ts"
    }

    IconSlider {
        Layout.fillWidth: true
        icon: Audio.icon
        value: Audio.volume
        active: Audio.ready
        onMoved: v => Audio.setVolume(v)
        onIconClicked: Audio.toggleMute()
    }

    AudioOutput {
        Layout.fillWidth: true
        Layout.topMargin: -6
        expanded: root.section === "audio"
        onExpandToggled: root.section = root.section === "audio" ? "" : "audio"
    }

    IconSlider {
        Layout.fillWidth: true
        icon: Brightness.icon
        value: Brightness.value
        active: Brightness.available
        onMoved: v => Brightness.set(v)
    }

    // The night-light dropdown hangs from its tile, over the rows below. It lives in the card's overlay layer:
    // as a child of the tile it painted fine but got no clicks outside the tile's own bounds.
    overlayData: Item {
        id: overlay
        anchors.fill: parent

        NightLightPanel {
            readonly property point at: {
                root.section; nightTile.width; nightTile.height; // re-map when the layout could have moved
                return nightTile.mapToItem(overlay, 0, 0);
            }
            x: at.x
            y: at.y + nightTile.height + 6
            width: nightTile.width
            open: root.section === "night"
        }
    }
}
