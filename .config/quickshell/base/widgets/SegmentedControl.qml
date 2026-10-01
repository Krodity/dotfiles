import QtQuick
import QtQuick.Layouts
import qs.config

// Row of mutually exclusive buttons. options: [{ value, label, icon? }]; emits selected(value).
Rectangle {
    id: root

    property var options: []
    property string current
    signal selected(string value)

    implicitHeight: 40
    radius: 14
    color: Appearance.colors.surface

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4
        uniformCellSizes: true

        Repeater {
            model: root.options

            HoverRect {
                required property var modelData
                readonly property bool active: root.current === modelData.value

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                baseColor: active ? Appearance.colors.accent : "transparent"
                hoverColor: active ? Appearance.colors.accent : Appearance.colors.surfaceHover
                onClicked: root.selected(modelData.value)

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!parent.parent.modelData.icon
                        icon: parent.parent.modelData.icon ?? ""
                        size: 16
                        color: parent.parent.active ? Appearance.colors.accentText : Appearance.colors.fg
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.parent.modelData.label
                        font.pixelSize: Appearance.font.small
                        font.bold: parent.parent.active
                        color: parent.parent.active ? Appearance.colors.accentText : Appearance.colors.fg
                    }
                }
            }
        }
    }
}
