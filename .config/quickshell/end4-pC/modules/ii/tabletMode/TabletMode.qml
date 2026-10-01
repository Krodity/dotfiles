import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Tablet Mode controller.
//  - Master toggle surface (IPC + global shortcuts)
//  - Drives UI up-scaling via Appearance.uiScale (bound in Appearance.qml)
//  - Starts/stops the osk-autoshow daemon (auto-show OSK on text-field focus)
//  - Auto-enables tablet mode when a touch device (Moonlight "touch-passthrough") appears
Scope {
    id: root

    function setEnabled(v) {
        if (Config.options.tablet.enable !== v)
            Config.options.tablet.enable = v
    }
    function toggleEnabled() {
        Config.options.tablet.enable = !Config.options.tablet.enable
    }

    // ---- OSK auto-show daemon lifecycle ------------------------------------
    readonly property bool oskDaemonWanted:
        (Config.options?.tablet.enable ?? false) && (Config.options?.tablet.autoOsk ?? true)

    function applyDaemon() {
        Quickshell.execDetached(["systemctl", "--user",
            root.oskDaemonWanted ? "start" : "stop", "osk-autoshow.service"])
    }
    onOskDaemonWantedChanged: root.applyDaemon()
    Component.onCompleted: root.applyDaemon()

    // ---- Auto-enable on touch-device appearance ----------------------------
    // Moonlight native touch enumerates a Wayland touch device named "touch-passthrough".
    // It is ephemeral (only present during a touch stream), so we poll for it.
    property bool touchPresent: false
    property bool autoEnabledByTouch: false
    property bool startupReconciled: false

    Timer {
        interval: 3000; running: true; repeat: true
        triggeredOnStart: true
        onTriggered: if (!touchProbe.running) touchProbe.running = true
    }
    Process {
        id: touchProbe
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.touchPresent = this.text.includes("touch-passthrough")
                if (!root.startupReconciled) {
                    root.startupReconciled = true
                    // Tablet mode must NOT persist across shell restarts / reboots.
                    // If no touch device is present at startup, force it off regardless
                    // of what was saved in config.json. Auto-enable re-arms the instant a
                    // touch stream appears. If a touch device IS present at startup, the
                    // rising-edge handler below will (re)enable and take auto-ownership.
                    if (!root.touchPresent) root.setEnabled(false)
                }
            }
        }
    }
    onTouchPresentChanged: {
        if (root.touchPresent) {
            if ((Config.options?.tablet.autoEnableOnTouch ?? false) && !Config.options.tablet.enable) {
                root.setEnabled(true)
                root.autoEnabledByTouch = true
            }
        } else {
            if (root.autoEnabledByTouch && Config.options.tablet.enable) {
                root.setEnabled(false)
                root.autoEnabledByTouch = false
            }
        }
    }
    // Detach auto-ownership the moment tablet mode is turned off by ANY means
    // (button/shortcut/IPC), so we never re-toggle against a manual choice.
    Connections {
        target: Config.options?.tablet ?? null
        function onEnableChanged() {
            if (!Config.options.tablet.enable) root.autoEnabledByTouch = false
        }
    }

    // ---- Edge-swipe gestures ----------------------------------------------
    Loader {
        active: (Config.options?.tablet.enable ?? false) && (Config.options?.tablet.edgeSwipes ?? true)
        sourceComponent: EdgeSwipes {}
    }

    // ---- Toggle surface ----------------------------------------------------
    IpcHandler {
        target: "tablet"
        function toggle(): void { root.toggleEnabled() }
        function on(): void { root.setEnabled(true) }
        function off(): void { root.setEnabled(false) }
        function status(): string { return Config.options.tablet.enable ? "on" : "off" }
    }

    CompositorGlobalShortcut {
        name: "tabletToggle"
        description: "Toggle tablet (touch) mode"
        onPressed: root.toggleEnabled()
    }
    CompositorGlobalShortcut {
        name: "tabletOn"
        description: "Enable tablet (touch) mode"
        onPressed: root.setEnabled(true)
    }
    CompositorGlobalShortcut {
        name: "tabletOff"
        description: "Disable tablet (touch) mode"
        onPressed: root.setEnabled(false)
    }
}
