import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Dashboard card: the current palette as colour stripes. Click opens the theme picker.
HoverRect {
    id: root

    implicitHeight: 136
    radius: 18
    baseColor: Appearance.colors.surface
    onClicked: Panels.toggle("theme", Panels.screen)

    Rectangle {
        x: 8
        y: 8
        width: parent.width - 16
        height: 84
        radius: 12
        color: Appearance.colors.bg
        clip: true

        Row {
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: ["accent", "surface", "surfaceHover", "fg", "muted"]

                Rectangle {
                    required property string modelData
                    width: 26
                    height: 52
                    radius: 13
                    color: Theme.current[modelData]
                    border.width: 1
                    border.color: Appearance.colors.border
                }
            }
        }
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 12
            bottomMargin: 10
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: "Theme"
                font.bold: true
            }
            StyledText {
                Layout.fillWidth: true
                text: Theme.current.preset
                font.pixelSize: Appearance.font.small
                color: Appearance.colors.muted
                elide: Text.ElideRight
            }
        }
        MaterialIcon {
            icon: "chevron_right"
            color: Appearance.colors.muted
        }
    }
}
