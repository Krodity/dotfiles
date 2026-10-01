import QtQuick
import QtQuick.Layouts
import qs.config

// One settings line: label (+ optional hint underneath) on the left, the control (children) on the right.
RowLayout {
    id: root

    property string label
    property string hint
    default property alias control: slot.data

    Layout.fillWidth: true
    spacing: 16

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        StyledText {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
        }
        StyledText {
            visible: root.hint !== ""
            Layout.fillWidth: true
            text: root.hint
            font.pixelSize: Appearance.font.small
            color: Appearance.colors.muted
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: slot
        implicitWidth: childrenRect.width
        implicitHeight: Math.max(28, childrenRect.height)
    }
}
