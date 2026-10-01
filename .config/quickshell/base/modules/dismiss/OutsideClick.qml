import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Closes the open bar popup when you click anywhere outside it, on any monitor.
// A transparent full-screen layer on WlrLayer.Top: above normal windows, below the popups (Overlay).
// ExclusionMode.Normal keeps it out of the bar's reserved strip, so the bar islands stay clickable.
// Replaces BarPopup's old HyprlandFocusGrab: on this Hyprland 0.56.2 setup an active grab swallowed every
// outside click, so it was removed.
// The launcher has its own backdrop, so it's left out. The click is swallowed, not passed on.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            visible: Panels.popup !== "" && Panels.popup !== "launcher"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            WlrLayershell.namespace: "base-outsideclick"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: Panels.close()
            }
        }
    }
}
