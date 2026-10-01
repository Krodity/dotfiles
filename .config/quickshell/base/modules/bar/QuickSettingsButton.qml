import QtQuick
import qs.config
import qs.services
import qs.widgets

// The round Wi-Fi island. Scroll on it to change volume.
Island {
    id: root

    property bool open
    signal clicked

    implicitWidth: implicitHeight
    color: open ? Appearance.colors.accent : Appearance.colors.bg
    Behavior on color {
        ColorAnimation { duration: Appearance.anim.normal }
    }

    MaterialIcon {
        anchors.centerIn: parent
        icon: Net.icon
        fill: true
        color: root.open ? Appearance.colors.accentText : Appearance.colors.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: wheel => Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
