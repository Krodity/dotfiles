import QtQuick
import qs.config

// The floating pill every bar section sits in. Put content inside; width follows implicitWidth.
Rectangle {
    implicitHeight: Appearance.bar.height
    radius: height / 2
    color: Appearance.colors.bg
    border.width: 1
    border.color: Appearance.colors.border
}
