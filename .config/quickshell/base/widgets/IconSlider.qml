import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

// [icon]  ───────●──────  42%    Icon click emits iconClicked(); drag emits moved(value 0..1).
RowLayout {
    id: root

    property string icon
    property real value
    property bool active: true
    signal moved(real value)
    signal iconClicked

    spacing: 10
    opacity: active ? 1 : 0.4

    // Assigned, not bound: a drag would break a binding, and outside changes (media keys) must still show.
    onValueChanged: if (!slider.pressed) slider.value = value
    Component.onCompleted: slider.value = value

    HoverRect {
        implicitWidth: 36
        implicitHeight: 36
        radius: 18
        baseColor: Appearance.colors.surface
        onClicked: root.iconClicked()

        MaterialIcon {
            anchors.centerIn: parent
            icon: root.icon
        }
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        enabled: root.active
        from: 0
        to: 1
        onMoved: root.moved(value)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 8
            radius: 4
            color: Appearance.colors.surface

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 4
                color: Appearance.colors.accent
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 18
            height: 18
            radius: 9
            color: Appearance.colors.fg
        }
    }

    StyledText {
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
        text: `${Math.round(slider.value * 100)}%`
        color: Appearance.colors.muted
    }
}
