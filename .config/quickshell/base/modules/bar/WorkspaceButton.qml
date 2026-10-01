import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.widgets

// Left island: icon of the current app on this monitor's workspace + how many windows it has.
// Click opens the window overview.
Island {
    id: root

    required property ShellScreen screen
    property bool open
    signal clicked

    readonly property HyprlandWorkspace workspace: Hyprland.monitorFor(screen)?.activeWorkspace ?? null
    readonly property var windows: workspace ? [...workspace.toplevels.values] : []
    readonly property int count: windows.length

    // The focused window if it's here, else this workspace's most recently focused one.
    readonly property HyprlandToplevel current: windows.find(t => t.activated)
        ?? [...windows].sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 99) - (b.lastIpcObject?.focusHistoryID ?? 99))[0]
        ?? null

    implicitWidth: row.implicitWidth + 16
    color: open ? Appearance.colors.accent : Appearance.colors.bg
    Behavior on color {
        ColorAnimation { duration: Appearance.anim.normal }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.current !== null
            implicitSize: 22
            source: Apps.iconFor(root.current)
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.current === null
            icon: "select_window"
            color: root.open ? Appearance.colors.accentText : Appearance.colors.muted
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(22, countLabel.implicitWidth + 10)
            height: 22
            radius: 11
            color: root.open ? Appearance.colors.bg : Appearance.colors.accent

            StyledText {
                id: countLabel
                anchors.centerIn: parent
                text: root.count
                font.bold: true
                font.pixelSize: Appearance.font.small
                color: root.open ? Appearance.colors.fg : Appearance.colors.accentText
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
