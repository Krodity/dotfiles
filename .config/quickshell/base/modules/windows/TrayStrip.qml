pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.widgets

// System tray icons as a small pill, centred in the overview's header row. Quickshell's SystemTray is the
// StatusNotifierWatcher/host while base runs.
// Left-click = activate (menu-only items open their menu), right-click = menu, middle = secondary activate,
// wheel = scroll. Hover shows the item's tooltip/title under the pill.
Rectangle {
    id: root

    signal activated   // an item was activated — the overview closes

    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)

    visible: items.length > 0
    implicitWidth: row.implicitWidth + 12
    implicitHeight: 32
    radius: 16
    color: Appearance.colors.surface

    property string hint: ""

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.items

            HoverRect {
                id: button

                required property SystemTrayItem modelData

                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                onHoveredChanged: {
                    const t = modelData.tooltipTitle || modelData.title || modelData.id;
                    if (hovered) root.hint = t;
                    else if (root.hint === t) root.hint = "";
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: button.modelData?.icon ?? ""
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: button.modelData?.menu ?? null
                    anchor.item: button
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                }

                // HoverRect's own MouseArea only takes left clicks; this one takes the rest on top of it.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        const it = button.modelData;
                        if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && it.onlyMenu)) {
                            if (it.hasMenu) menuAnchor.open();
                        } else if (event.button === Qt.MiddleButton) {
                            it.secondaryActivate();
                        } else {
                            it.activate();
                            root.activated();
                        }
                    }
                    onWheel: event => button.modelData.scroll(event.angleDelta.y || event.angleDelta.x, event.angleDelta.x !== 0)
                }
            }
        }
    }

    // Hovered item's name, just under the pill.
    Rectangle {
        visible: root.hint !== ""
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        z: 20
        width: hintText.implicitWidth + 16
        height: 24
        radius: 12
        color: Appearance.colors.bg
        border.width: 1
        border.color: Appearance.colors.border

        StyledText {
            id: hintText
            anchors.centerIn: parent
            text: root.hint
            font.pixelSize: Appearance.font.small
        }
    }
}
