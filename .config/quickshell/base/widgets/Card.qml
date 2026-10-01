import QtQuick
import QtQuick.Layouts
import qs.config

// Settings section: optional title over a softly filled card holding a column of rows.
ColumnLayout {
    id: root

    property string title
    default property alias content: inner.data

    Layout.fillWidth: true
    spacing: 8

    StyledText {
        visible: root.title !== ""
        Layout.leftMargin: 4
        text: root.title
        font.bold: true
        color: Appearance.colors.muted
        font.pixelSize: Appearance.font.small
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 28
        radius: 18
        color: Qt.alpha(Appearance.colors.surface, 0.55)

        ColumnLayout {
            id: inner
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 14
            }
            spacing: 12
        }
    }
}
