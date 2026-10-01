import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

// Stack of notification toasts hanging under the quick-settings (Wi-Fi) island, newest on top.
// One per monitor, but only the focused monitor's is shown. When quick settings is open on that
// screen the stack drops below it instead of covering it.
PanelWindow {
    id: root

    property bool active              // this is the monitor toasts show on
    property real anchorX             // horizontal centre to hang from (the Wi-Fi island), screen coords
    property real pushDown: 0         // extra top offset (height of an open quick-settings card)

    anchors {
        top: true
        left: true
    }
    margins.top: Appearance.popup.gap + pushDown
    margins.left: Math.max(Appearance.bar.margin,
        Math.min(screen.width - implicitWidth - Appearance.bar.margin, anchorX - implicitWidth / 2))
    implicitWidth: Appearance.popup.width
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    visible: active && Notifs.toasts.length > 0

    // Only the toasts take clicks; the gaps between them pass through.
    mask: Region { item: stack }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "base-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        id: stack

        width: parent.width
        spacing: 8

        Repeater {
            // ScriptModel diffs the array, so existing toasts keep their delegate (timer, animation state)
            // when a new one arrives; a plain array would rebuild them all.
            model: ScriptModel {
                values: Notifs.toasts
            }

            Toast {
                required property var modelData
                notification: modelData
            }
        }
    }
}
