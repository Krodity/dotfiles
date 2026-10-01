import QtQuick
import QtQuick.Layouts
import qs.config

// Quick-settings tile: left part toggles, chevron expands a detail list (hidden when !expandable).
Rectangle {
    id: root

    property string icon
    property string label
    property string sublabel
    property bool checked
    property bool expanded
    property bool expandable: true
    signal toggled
    signal expandToggled

    implicitHeight: 56
    radius: 18
    color: checked ? Appearance.colors.accent : Appearance.colors.surface
    Behavior on color {
        ColorAnimation { duration: Appearance.anim.normal }
    }

    readonly property color contentColor: checked ? Appearance.colors.accentText : Appearance.colors.fg

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 6
        spacing: 10

        MouseArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()

            RowLayout {
                anchors.fill: parent
                spacing: 10

                MaterialIcon {
                    icon: root.icon
                    fill: root.checked
                    color: root.contentColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.label
                        font.bold: true
                        color: root.contentColor
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.sublabel
                        font.pixelSize: Appearance.font.small
                        color: root.contentColor
                        opacity: 0.8
                        elide: Text.ElideRight
                    }
                }
            }
        }

        HoverRect {
            visible: root.expandable
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            hoverColor: Qt.rgba(0, 0, 0, 0.15)
            onClicked: root.expandToggled()

            MaterialIcon {
                anchors.centerIn: parent
                icon: "chevron_right"
                color: root.contentColor
                rotation: root.expanded ? 90 : 0
                Behavior on rotation {
                    NumberAnimation { duration: Appearance.anim.normal }
                }
            }
        }
    }
}
