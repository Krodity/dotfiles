import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Big wallpaper grid, opened from the dashboard's Wallpaper button. Back arrow returns to the dashboard.
BarPopup {
    id: root

    name: "wallpapers"
    cardWidth: Math.min(980, screen.width - Appearance.bar.margin * 2)
    onOpenChanged: if (open) grid.scrollToCurrent()

    component IconButton: HoverRect {
        property string icon

        implicitWidth: 32
        implicitHeight: 32
        radius: 16

        MaterialIcon {
            anchors.centerIn: parent
            icon: parent.icon
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        IconButton {
            icon: "arrow_back"
            onClicked: Panels.toggle("dashboard", Panels.screen)
        }
        StyledText {
            text: "Wallpapers"
            font.bold: true
            font.pixelSize: 15
        }
        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            readonly property int done: Object.keys(Wallpapers.ready).length
            text: done < Wallpapers.files.length ? `making thumbnails ${done}/${Wallpapers.files.length}` : `${Wallpapers.files.length} images`
            font.pixelSize: Appearance.font.small
            color: Appearance.colors.muted
        }
        IconButton {
            icon: "shuffle"
            onClicked: Wallpapers.random()
        }
        IconButton {
            icon: "refresh"
            onClicked: Wallpapers.rescan()
        }
        IconButton {
            icon: "close"
            onClicked: root.closeRequested()
        }
    }

    WallpaperGrid {
        id: grid
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 12

        StyledText {
            Layout.leftMargin: 4
            text: "Scaling"
            font.bold: true
        }
        SegmentedControl {
            Layout.fillWidth: true
            options: Wallpapers.fitModes
            current: Wallpapers.fit
            onSelected: mode => Wallpapers.setFit(mode)
        }
    }
}
