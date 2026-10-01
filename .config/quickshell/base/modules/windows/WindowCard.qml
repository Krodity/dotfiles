import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// One window: snapshot (or big app icon if never captured) + icon and title. Click focuses it;
// right-click asks the overview for its context menu (switch / fullscreen / close).
HoverRect {
    id: root

    required property HyprlandToplevel toplevel
    signal activated
    signal menuRequested(real x, real y)   // card coords
    signal dragStarted
    signal dragMoved(point scenePos)
    signal dropped

    property bool selected   // keyboard selection in the overview

    implicitHeight: preview.height + 44
    radius: 14
    // Keyboard selection = accent tint + thick ring; the focused window only gets a thin ring.
    baseColor: selected ? Qt.tint(Appearance.colors.surface, Qt.alpha(Appearance.colors.accent, 0.18)) : Appearance.colors.surface
    border.width: selected ? 3 : toplevel.activated ? 1 : 0
    border.color: Appearance.colors.accent

    // Right button only — left clicks fall through to HoverRect's own MouseArea.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => root.menuRequested(mouse.x, mouse.y)
    }

    ClippingRectangle {
        id: preview

        x: 6
        y: 6
        width: parent.width - 12
        height: Math.round(width * 0.6)
        radius: 10
        color: Appearance.colors.bg

        IconImage {
            anchors.centerIn: parent
            visible: shot.status !== Image.Ready
            implicitSize: 48
            source: Apps.iconFor(root.toplevel)
        }

        Image {
            id: shot
            anchors.fill: parent
            source: Previews.sourceFor(root.toplevel.address)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
            bottomMargin: 8
        }
        spacing: 8

        IconImage {
            implicitSize: 18
            source: Apps.iconFor(root.toplevel)
        }
        StyledText {
            Layout.fillWidth: true
            text: root.toplevel.title || Apps.appId(root.toplevel)
            font.pixelSize: Appearance.font.small
            elide: Text.ElideRight
        }
    }

    // On top so it sees the press first. Left click = TapHandler (the DragHandler's grab keeps presses
    // from HoverRect's MouseArea, which now only drives the hover tint); moving past the drag threshold
    // turns the same press into a drag instead.
    Item {
        anchors.fill: parent

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                root.toplevel.wayland?.activate();
                root.activated();
            }
        }

        DragHandler {
            target: null
            onActiveChanged: active ? root.dragStarted() : root.dropped()
            onCentroidChanged: if (active) root.dragMoved(centroid.scenePosition)
        }
    }
}
