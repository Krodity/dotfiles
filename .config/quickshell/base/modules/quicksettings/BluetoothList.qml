import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Paired devices. Click to connect / disconnect. (Pair new devices with `bluetoothctl`.)
ColumnLayout {
    id: root

    spacing: 6

    StyledText {
        visible: !Bt.enabled || Bt.devices.length === 0
        Layout.leftMargin: 6
        text: !Bt.adapter ? "No Bluetooth adapter" : !Bt.enabled ? "Bluetooth is off" : "No paired devices"
        color: Appearance.colors.muted
    }

    Flickable {
        visible: Bt.enabled && Bt.devices.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, 220)
        contentHeight: list.implicitHeight
        clip: true

        Column {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: Bt.devices

                ListRow {
                    required property var modelData

                    width: list.width
                    icon: Bt.deviceIcon(modelData)
                    text: Bt.displayName(modelData)
                    highlighted: modelData.connected
                    trailing: modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                        : modelData.state === BluetoothDeviceState.Disconnecting ? "…"
                        : !modelData.connected ? ""
                        : modelData.batteryAvailable ? `${Math.round(modelData.battery * 100)}%` : "Connected"
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
        }
    }
}
