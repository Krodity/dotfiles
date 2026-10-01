import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

// Slider with a value readout. Emits moved(value) while dragging; outside changes to `value` still show.
RowLayout {
    id: root

    property real value
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property int decimals: 0
    property string suffix: ""
    property real displayScale: 1   // e.g. 100 to show 0..1 as a percentage
    signal moved(real value)

    implicitWidth: 260
    spacing: 10

    onValueChanged: if (!slider.pressed) slider.value = value
    Component.onCompleted: slider.value = value

    Slider {
        id: slider
        Layout.fillWidth: true
        Layout.preferredWidth: root.implicitWidth - 56
        from: root.from
        to: root.to
        stepSize: root.stepSize
        snapMode: root.stepSize > 0 ? Slider.SnapAlways : Slider.NoSnap
        onMoved: root.moved(value)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 6
            width: slider.availableWidth
            height: 6
            radius: 3
            color: Appearance.colors.surfaceHover

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 3
                color: Appearance.colors.accent
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 16
            height: 16
            radius: 8
            color: Appearance.colors.fg
        }
    }

    StyledText {
        Layout.preferredWidth: 46
        horizontalAlignment: Text.AlignRight
        text: (slider.value * root.displayScale).toFixed(root.decimals) + root.suffix
        color: Appearance.colors.muted
        font.pixelSize: Appearance.font.small
    }
}
