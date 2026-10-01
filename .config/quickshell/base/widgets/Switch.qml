import QtQuick
import qs.config

// Pill on/off switch. Emits toggled(); the owner flips `checked`.
Rectangle {
    id: root

    property bool checked
    signal toggled

    implicitWidth: 44
    implicitHeight: 24
    radius: 12
    opacity: enabled ? 1 : 0.4
    color: checked ? Appearance.colors.accent : Appearance.colors.surfaceHover
    Behavior on color {
        ColorAnimation { duration: Appearance.anim.fast }
    }

    Rectangle {
        width: 18
        height: 18
        radius: 9
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Appearance.colors.accentText : Appearance.colors.fg
        Behavior on x {
            NumberAnimation { duration: Appearance.anim.fast; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
