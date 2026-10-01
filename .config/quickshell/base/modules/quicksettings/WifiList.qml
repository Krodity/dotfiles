import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Nearby networks. Click: connected → disconnect, saved/open → connect, secured → ask for password.
ColumnLayout {
    id: root

    property var pskTarget: null

    spacing: 6

    StyledText {
        visible: !Net.enabled || Net.networks.length === 0
        Layout.leftMargin: 6
        text: !Net.wifiDevice ? "No Wi-Fi adapter" : !Net.enabled ? "Wi-Fi is off" : "Scanning…"
        color: Appearance.colors.muted
    }

    // Password prompt lives outside the list: list delegates are rebuilt on every scan update.
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
            background: Rectangle {
                radius: 12
                color: Appearance.colors.surface
                border.width: psk.activeFocus ? 1 : 0
                border.color: Appearance.colors.accent
            }
            onVisibleChanged: if (visible) forceActiveFocus()
            onAccepted: connectBtn.clicked()
            Keys.onEscapePressed: root.pskTarget = null
        }

        HoverRect {
            id: connectBtn
            implicitWidth: 36
            implicitHeight: 36
            radius: 12
            baseColor: Appearance.colors.accent
            hoverColor: Qt.lighter(Appearance.colors.accent, 1.1)
            onClicked: {
                if (psk.text.length > 0) root.pskTarget?.connectWithPsk(psk.text);
                psk.text = "";
                root.pskTarget = null;
            }

            MaterialIcon {
                anchors.centerIn: parent
                icon: "arrow_forward"
                color: Appearance.colors.accentText
            }
        }
    }

    Flickable {
        visible: Net.enabled && Net.networks.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, 220)
        contentHeight: list.implicitHeight
        clip: true

        Column {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: Net.networks

                ListRow {
                    required property var modelData

                    width: list.width
                    icon: Net.strengthIcon(modelData.signalStrength)
                    text: modelData.name
                    highlighted: modelData.connected
                    trailing: modelData.stateChanging ? "…"
                        : modelData.connected ? "Connected"
                        : modelData.known ? "Saved"
                        : Net.isOpen(modelData) ? "Open" : "Secured"
                    onClicked: {
                        if (modelData.connected) modelData.disconnect();
                        else if (modelData.known || Net.isOpen(modelData)) modelData.connect();
                        else root.pskTarget = modelData;
                    }
                }
            }
        }
    }
}
