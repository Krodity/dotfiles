import QtQuick
import QtQuick.Layouts
import qs.config

// Text button (optional icon). `primary` = accent-filled.
HoverRect {
    id: root

    property string text
    property string icon
    property bool primary

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 34
    radius: 12
    opacity: enabled ? 1 : 0.4
    baseColor: primary ? Appearance.colors.accent : Appearance.colors.surface
    hoverColor: primary ? Qt.lighter(Appearance.colors.accent, 1.1) : Appearance.colors.surfaceHover

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        MaterialIcon {
            visible: root.icon !== ""
            icon: root.icon
            size: 16
            color: root.primary ? Appearance.colors.accentText : Appearance.colors.fg
        }
        StyledText {
            text: root.text
            font.bold: root.primary
            color: root.primary ? Appearance.colors.accentText : Appearance.colors.fg
        }
    }
}
