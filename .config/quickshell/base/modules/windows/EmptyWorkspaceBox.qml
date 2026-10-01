import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets

// Card that appears beside the window overview while a window is being dragged, listing the empty
// workspaces as drop slots. Takes no input itself: during a drag the pointer stays grabbed by the
// overview, which hit-tests against slotAt() and tells us the hovered slot via `dropId`.
PanelWindow {
    id: root

    property bool open
    property var entries: []       // [{ id, screen }]
    property int dropId: 0         // slot to highlight
    property real preferredX       // left edge in screen coords, chosen by the overview

    readonly property int boxWidth: 220

    // Workspace id of the slot at (x, y) in this window's coords; -1 = inside the box but not on a slot,
    // 0 = outside.
    function slotAt(x, y) {
        if (x < 0 || y < 0 || x > width || y > card.height) return 0;
        for (let i = 0; i < slotRepeater.count; i++) {
            const slot = slotRepeater.itemAt(i);
            const p = slot.mapToItem(null, 0, 0);
            if (x >= p.x && x <= p.x + slot.width && y >= p.y && y <= p.y + slot.height) return slot.modelData.id;
        }
        return -1;
    }

    anchors {
        top: true
        left: true
    }
    // Same top edge as the overview (same gap, same exclusion handling), so both share a y origin.
    margins.top: Appearance.popup.gap
    margins.left: preferredX
    implicitWidth: boxWidth
    implicitHeight: card.implicitHeight
    color: "transparent"
    mask: Region {}
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "base-emptyworkspaces"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: open || card.opacity > 0

    Rectangle {
        id: card

        width: parent.width
        implicitHeight: column.implicitHeight + Appearance.popup.padding * 2
        radius: Appearance.popup.radius
        color: Appearance.colors.bg
        border.width: 1
        border.color: Appearance.colors.border

        opacity: root.open ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Appearance.anim.fast }
        }
        transform: Translate {
            y: root.open ? 0 : -10
            Behavior on y {
                NumberAnimation { duration: Appearance.anim.normal; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            id: column

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Appearance.popup.padding
            }
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.bottomMargin: 2
                spacing: 6

                MaterialIcon {
                    icon: "add_circle"
                    color: Appearance.colors.accent
                }
                StyledText {
                    Layout.fillWidth: true
                    text: "Empty workspaces"
                    font.bold: true
                    font.pixelSize: 15
                    elide: Text.ElideRight
                }
            }

            Repeater {
                id: slotRepeater
                model: root.entries

                Rectangle {
                    id: slot

                    required property var modelData
                    readonly property bool dropHere: root.dropId === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 12
                    color: dropHere ? Qt.alpha(Appearance.colors.accent, 0.22) : Appearance.colors.surface
                    border.width: dropHere ? 2 : 0
                    border.color: Appearance.colors.accent

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 10
                        spacing: 8

                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: slot.dropHere ? Appearance.colors.accent : Appearance.colors.surfaceHover

                            StyledText {
                                anchors.centerIn: parent
                                text: slot.modelData.id
                                font.bold: true
                                font.pixelSize: Appearance.font.small
                                color: slot.dropHere ? Appearance.colors.accentText : Appearance.colors.fg
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: slot.modelData.screen || "New"
                            font.pixelSize: Appearance.font.small
                            color: slot.dropHere ? Appearance.colors.accent : Appearance.colors.muted
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.topMargin: 2
                text: "Drop on one to move the window there"
                font.pixelSize: Appearance.font.small
                color: Appearance.colors.muted
                wrapMode: Text.WordWrap
            }
        }
    }
}
