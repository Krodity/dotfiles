import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.widgets

// Thumbnails of ~/Pictures/Wallpapers (folder set in services/Wallpapers.qml). Click to apply.
GridView {
    id: grid

    property int columns: 4
    property real visibleRows: 3.5

    function scrollToCurrent() {
        const i = Wallpapers.files.indexOf(Wallpapers.current);
        if (i >= 0) positionViewAtIndex(i, GridView.Center);
    }

    implicitHeight: cellHeight * visibleRows
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    cellWidth: width / columns
    cellHeight: Math.round(cellWidth * 0.6)
    model: Wallpapers.files
    ScrollBar.vertical: ScrollBar {}

    delegate: Item {
        id: cell

        required property string modelData
        readonly property bool isCurrent: modelData === Wallpapers.current

        width: grid.cellWidth
        height: grid.cellHeight

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 12
            color: Appearance.colors.surface

            MaterialIcon {
                anchors.centerIn: parent
                visible: thumb.status !== Image.Ready
                icon: "image"
                color: Appearance.colors.muted
            }

            Image {
                id: thumb
                anchors.fill: parent
                source: Wallpapers.thumbFor(cell.modelData)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        // Hover tint + accent ring on the current wallpaper.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 12
            color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            border.width: cell.isCurrent ? 3 : 0
            border.color: Appearance.colors.accent
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Wallpapers.set(cell.modelData)
        }
    }
}
