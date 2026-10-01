import QtQuick
import qs.config
import qs.services
import qs.widgets

// Centre island: the time. Click opens the dashboard (media + wallpapers).
Island {
    id: root

    property bool open
    signal clicked

    implicitWidth: label.implicitWidth + Appearance.bar.padding * 2
    color: open ? Appearance.colors.accent : Appearance.colors.bg
    Behavior on color {
        ColorAnimation { duration: Appearance.anim.normal }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: Time.time
        font.bold: true
        color: root.open ? Appearance.colors.accentText : Appearance.colors.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
