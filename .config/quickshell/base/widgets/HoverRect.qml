import QtQuick
import qs.config

// Clickable rectangle with a hover tint. Emits clicked().
Rectangle {
    id: root

    signal clicked
    property color baseColor: "transparent"
    property color hoverColor: Appearance.colors.surfaceHover
    readonly property bool hovered: mouse.containsMouse

    color: hovered ? hoverColor : baseColor
    Behavior on color {
        ColorAnimation { duration: Appearance.anim.fast }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
