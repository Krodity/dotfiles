import QtQuick
import QtQuick.Layouts
import qs.config

// One row in a detail list: [icon] name .......... trailing
HoverRect {
    id: root

    property string icon
    property string text
    property string trailing
    property bool highlighted
    property real trailingPad: 0   // room kept free at the right for a button laid over the row

    implicitHeight: 40
    radius: 12
    baseColor: highlighted ? Qt.alpha(Appearance.colors.accent, 0.18) : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12 + root.trailingPad
        spacing: 10

        MaterialIcon {
            icon: root.icon
            color: root.highlighted ? Appearance.colors.accent : Appearance.colors.fg
        }
        StyledText {
            Layout.fillWidth: true
            text: root.text
            elide: Text.ElideRight
        }
        StyledText {
            text: root.trailing
            font.pixelSize: Appearance.font.small
            color: Appearance.colors.muted
        }
    }
}
