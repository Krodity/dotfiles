import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Dashboard card: current wallpaper preview. Click opens the picker; the corner button shuffles.
HoverRect {
    id: root

    implicitHeight: 136
    radius: 18
    baseColor: Appearance.colors.surface
    onClicked: Panels.toggle("wallpapers", Panels.screen)

    ClippingRectangle {
        id: preview
        x: 8
        y: 8
        width: parent.width - 16
        height: 84
        radius: 12
        color: Appearance.colors.bg

        MaterialIcon {
            anchors.centerIn: parent
            visible: image.status !== Image.Ready
            icon: "wallpaper"
            color: Appearance.colors.muted
        }

        Image {
            id: image
            anchors.fill: parent
            source: Wallpapers.thumbFor(Wallpapers.current)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        HoverRect {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            implicitWidth: 30
            implicitHeight: 30
            radius: 15
            baseColor: Qt.alpha(Appearance.colors.bg, 0.8)
            hoverColor: Appearance.colors.bg
            onClicked: Wallpapers.random()

            MaterialIcon {
                anchors.centerIn: parent
                icon: "shuffle"
                size: 16
            }
        }
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 12
            bottomMargin: 10
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: "Wallpaper"
                font.bold: true
            }
            StyledText {
                Layout.fillWidth: true
                text: Wallpapers.current.split("/").pop() || "None set"
                font.pixelSize: Appearance.font.small
                color: Appearance.colors.muted
                elide: Text.ElideMiddle
            }
        }
        MaterialIcon {
            icon: "chevron_right"
            color: Appearance.colors.muted
        }
    }
}
