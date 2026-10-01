import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.widgets

// Settings → Display → Identify: a big name tag in the middle of every monitor for a couple of seconds.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData
            readonly property var mon: Monitors.live.find(m => m.name === modelData.name) ?? null

            screen: modelData
            visible: Monitors.identify
            implicitWidth: tag.implicitWidth + 64
            implicitHeight: tag.implicitHeight + 40
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "base-identify"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: 28
                color: Appearance.colors.bg
                border.width: 2
                border.color: Appearance.colors.accent

                Column {
                    id: tag
                    anchors.centerIn: parent
                    spacing: 4

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: win.mon?.label ?? win.modelData.name
                        font.pixelSize: 44
                        font.bold: true
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: win.mon ? `${win.mon.name} · ${win.mon.w}×${win.mon.h} @ ${win.mon.rate} Hz · ${Math.round(win.mon.scale * 100)}%` : win.modelData.name
                        color: Appearance.colors.muted
                        font.pixelSize: 18
                    }
                }
            }
        }
    }
}
