import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// "Output: <device> ›" row under the volume slider; expands to every sink. Click one to make it default.
ColumnLayout {
    id: root

    property bool expanded
    signal expandToggled

    spacing: 4

    HoverRect {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 12
        onClicked: root.expandToggled()

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 6
            spacing: 10

            MaterialIcon {
                icon: Audio.sinkIcon(Audio.sink)
                color: Appearance.colors.muted
            }
            StyledText {
                Layout.fillWidth: true
                text: Audio.sink ? Audio.sinkName(Audio.sink) : "No output device"
                color: Appearance.colors.muted
                elide: Text.ElideRight
            }
            MaterialIcon {
                icon: "chevron_right"
                color: Appearance.colors.muted
                rotation: root.expanded ? 90 : 0
                Behavior on rotation {
                    NumberAnimation { duration: Appearance.anim.normal }
                }
            }
        }
    }

    Flickable {
        visible: root.expanded
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, 220)
        contentHeight: list.implicitHeight
        clip: true

        Column {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: Audio.sinks

                ListRow {
                    required property var modelData

                    width: list.width
                    icon: Audio.sinkIcon(modelData)
                    text: Audio.sinkName(modelData)
                    highlighted: modelData === Audio.sink
                    trailing: modelData === Audio.sink ? "Active" : ""
                    onClicked: Audio.setSink(modelData)
                }
            }
        }
    }
}
