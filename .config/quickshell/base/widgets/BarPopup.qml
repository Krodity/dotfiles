import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config

// Drop-down card hanging under a bar island. Children go into a ColumnLayout inside the card.
// Closes on Escape → emits closeRequested(); outside clicks are caught by modules/dismiss/OutsideClick.qml.
// keyHandler sees keys first.
PanelWindow {
    id: root

    property string name                       // layer namespace suffix, e.g. "quicksettings"
    property bool open
    property var barWindow                      // (was the focus-grab whitelist; kept so callers still bind it)
    property real anchorX                       // horizontal centre to hang from, screen coords
    property int cardWidth: Appearance.popup.width
    default property alias content: column.data
    property alias overlayData: overlayLayer.data  // floats above the content (context menus), card coords
    // Optional keyboard hook: called with every key event before Esc handling; return true to consume it.
    property var keyHandler: null
    // Exclusive keyboard while open. ⚠️ Hyprland then also confines the POINTER to this layer, so outside
    // clicks never reach OutsideClick and the popup can't be dismissed by clicking. Leave false: OnDemand
    // still delivers keys (focus is taken on open).
    property bool exclusiveKeyboard: false
    signal closeRequested

    anchors {
        top: true
        left: true
    }
    margins.top: Appearance.popup.gap
    margins.left: Math.max(Appearance.bar.margin,
        Math.min(screen.width - implicitWidth - Appearance.bar.margin, anchorX - implicitWidth / 2))
    implicitWidth: cardWidth
    implicitHeight: card.implicitHeight
    color: "transparent"

    // Zone 0 + Normal: the compositor places us below every bar's reserved space (ours and any other).
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: `base-${name}`
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: !open ? WlrKeyboardFocus.None
        : exclusiveKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

    // Stay mapped until the fade-out finishes.
    visible: open || card.opacity > 0
    onOpenChanged: if (open) card.forceActiveFocus()

    // No HyprlandFocusGrab: on this Hyprland 0.56.2 setup an active grab swallowed every outside click
    // (neither apps nor our catcher got it) and randomly cleared ~2 s after an IPC open. Outside clicks are
    // handled by modules/dismiss/OutsideClick.qml instead.

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
            NumberAnimation { duration: Appearance.anim.normal }
        }
        transform: Translate {
            y: root.open ? 0 : -10
            Behavior on y {
                NumberAnimation { duration: Appearance.anim.normal; easing.type: Easing.OutCubic }
            }
        }

        focus: true
        // One handler for everything: Qt fires specific handlers (onEscapePressed) *before* onPressed, which
        // would let Esc close the popup before keyHandler could use it (e.g. to close a context menu first).
        Keys.onPressed: event => {
            if (root.keyHandler && root.keyHandler(event)) event.accepted = true;
            else if (event.key === Qt.Key_Escape) {
                root.closeRequested();
                event.accepted = true;
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
            spacing: 10
        }

        Item {
            id: overlayLayer
            anchors.fill: parent
            z: 10
        }
    }
}
