import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets

// One palette: four swatches + name. `palette` is an entry of Theme.presets.
HoverRect {
    id: root

    required property var palette
    property bool selected

    implicitHeight: 58
    radius: 14
    baseColor: palette.bg
    hoverColor: palette.surface
    border.width: selected ? 2 : 1
    border.color: selected ? Appearance.colors.accent : Appearance.colors.border

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Row {
            spacing: 4
            Repeater {
                model: ["surface", "accent", "fg", "muted"]
                Rectangle {
                    required property string modelData
                    width: 14
                    height: 14
                    radius: 7
                    color: root.palette[modelData]
                }
            }
        }
        StyledText {
            Layout.fillWidth: true
            text: root.palette.name
            color: root.palette.fg
            font.pixelSize: Appearance.font.small
            font.bold: true
            elide: Text.ElideRight
        }
    }
}
