import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets
import qs.modules.quicksettings

// Settings → Tailscale: connection on/off + status, then the same exit-node picker as quick settings, taller.
ColumnLayout {
    id: root

    spacing: 18
    Component.onCompleted: Tailscale.setWatching(true)
    Component.onDestruction: Tailscale.setWatching(false)

    Card {
        title: "Connection"

        SettingRow {
            label: "Tailscale"
            hint: Tailscale.status

            Switch {
                enabled: Tailscale.available && !Tailscale.busy
                checked: Tailscale.running
                onToggled: Tailscale.toggle()
            }
        }

        SettingRow {
            visible: Tailscale.ip !== ""
            label: "This machine"
            hint: "Tailnet address"

            StyledText {
                text: Tailscale.ip
                font.family: "monospace"
            }
        }
    }

    Card {
        title: "Exit node"

        TailscalePanel {
            Layout.fillWidth: true
            listHeight: 420
        }
    }
}
