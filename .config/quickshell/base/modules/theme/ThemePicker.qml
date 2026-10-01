import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Presets + exact per-role colours for the whole shell. Everything updates live and is saved.
BarPopup {
    id: root

    property string role: "accent"

    name: "theme"
    cardWidth: Math.min(760, screen.width - Appearance.bar.margin * 2)

    component IconButton: HoverRect {
        property string icon

        implicitWidth: 32
        implicitHeight: 32
        radius: 16

        MaterialIcon {
            anchors.centerIn: parent
            icon: parent.icon
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        IconButton {
            icon: "arrow_back"
            onClicked: Panels.toggle("dashboard", Panels.screen)
        }
        StyledText {
            text: "Theme"
            font.bold: true
            font.pixelSize: 15
        }
        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: Theme.current.preset
            font.pixelSize: Appearance.font.small
            color: Appearance.colors.muted
        }
        IconButton {
            icon: "close"
            onClicked: root.closeRequested()
        }
    }

    StyledText {
        Layout.leftMargin: 4
        text: "Presets"
        font.bold: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 5
        uniformCellWidths: true
        columnSpacing: 8
        rowSpacing: 8

        PresetChip {
            Layout.fillWidth: true
            visible: Theme.wallpaperPreset !== null
            palette: Theme.wallpaperPreset ?? Theme.presets[0]
            selected: Theme.current.preset === "From wallpaper"
            onClicked: Theme.applyPreset(Theme.wallpaperPreset)

            MaterialIcon {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                icon: "wallpaper"
                size: 16
                color: parent.palette.fg
            }
        }

        Repeater {
            model: Theme.presets

            PresetChip {
                required property var modelData
                Layout.fillWidth: true
                palette: modelData
                selected: Theme.current.preset === modelData.name
                onClicked: Theme.applyPreset(modelData)
            }
        }
    }

    StyledText {
        Layout.leftMargin: 4
        Layout.topMargin: 4
        text: "Colors"
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        // Role list — pick which colour the editor changes.
        ColumnLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: 300
            Layout.alignment: Qt.AlignTop
            spacing: 2

            Repeater {
                model: Theme.roles

                HoverRect {
                    required property var modelData
                    readonly property bool selected: root.role === modelData.key

                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 10
                    baseColor: selected ? Appearance.colors.surface : "transparent"
                    onClicked: root.role = modelData.key

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: Theme.current[modelData.key]
                            border.width: 1
                            border.color: Appearance.colors.border
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.bold: selected
                        }
                        StyledText {
                            text: Theme.current[modelData.key]
                            font.family: "monospace"
                            font.pixelSize: Appearance.font.small
                            color: Appearance.colors.muted
                        }
                    }
                }
            }
        }

        ColorEditor {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            value: Theme.current[root.role]
            onPicked: c => Theme.setRole(root.role, Theme.hex(c))
        }
    }
}
