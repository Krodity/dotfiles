import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Edge-swipe gestures for Tablet Mode.
// Thin, transparent, input-masked strips along each screen edge (WlrLayer.Top,
// no reserved space). A swipe past the threshold runs the edge's configured action.
// Only instantiated while tablet mode + edgeSwipes are on (see TabletMode.qml).
// Works with Moonlight native touch: touch-down on the strip grabs the sequence,
// so drag motion keeps arriving even after leaving the strip's bounds.
Scope {
    id: root
    readonly property int catcher: Config.options?.tablet.edgeCatcherWidth ?? 14
    readonly property int threshold: Config.options?.tablet.edgeSwipeThreshold ?? 60

    // Map an action name (from config) to a shell/compositor action.
    function doAction(name) {
        switch (name) {
        case "leftSidebar":  GlobalStates.sidebarLeftOpen = true; break
        case "rightSidebar": GlobalStates.sidebarRightOpen = true; break
        case "osk":          GlobalStates.oskOpen = true; break
        case "bar":          GlobalStates.barOpen = true; break
        case "search":
        case "overview":     GlobalStates.overviewOpen = true; break
        case "kill":         Hyprland.dispatch("killactive"); break
        case "none":
        default:             break
        }
    }

    component EdgeCatcher: PanelWindow {
        id: win
        required property string edge          // "left" | "right" | "top" | "bottom"
        required property string action         // action name, see doAction()
        property bool hidden: false
        readonly property bool horizontal: edge === "left" || edge === "right"
        // Guard destructive actions (kill) behind a longer swipe.
        readonly property real fireThreshold: action === "kill" ? root.threshold * 1.7 : root.threshold

        visible: !hidden && action !== "none"
        WlrLayershell.namespace: "quickshell:tabletEdge"
        WlrLayershell.layer: WlrLayer.Top
        exclusiveZone: 0
        color: "transparent"

        anchors {
            left: edge !== "right"
            right: edge !== "left"
            top: edge !== "bottom"
            bottom: edge !== "top"
        }
        implicitWidth: horizontal ? root.catcher : 1
        implicitHeight: horizontal ? 1 : root.catcher

        mask: Region { item: area }

        MouseArea {
            id: area
            anchors.fill: parent
            property real sx: 0
            property real sy: 0
            property bool armed: false

            onPressed: (m) => { sx = m.x; sy = m.y; armed = true }
            onReleased: armed = false
            onCanceled: armed = false
            onPositionChanged: (m) => {
                if (!armed) return
                const dx = m.x - sx
                const dy = m.y - sy
                const t = win.fireThreshold
                const pass = (win.edge === "left"   && dx >  t)
                          || (win.edge === "right"  && dx < -t)
                          || (win.edge === "top"    && dy >  t)
                          || (win.edge === "bottom" && dy < -t)
                if (pass) {
                    armed = false          // fire once per swipe
                    root.doAction(win.action)
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens
        Scope {
            id: monitorScope
            required property var modelData
            property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            property list<HyprlandWorkspace> wsForMon: Hyprland.workspaces.values
                .filter(w => w.monitor && w.monitor.name === monitor.name)
            property var fsWs: wsForMon
                .filter(w => ((w.toplevels.values.filter(t => t.wayland?.fullscreen)[0] !== undefined) && w.active))[0]
            property bool fullscreen: fsWs !== undefined

            EdgeCatcher { screen: modelData; edge: "left";   hidden: monitorScope.fullscreen; action: Config.options?.tablet.edgeLeft   ?? "leftSidebar" }
            EdgeCatcher { screen: modelData; edge: "right";  hidden: monitorScope.fullscreen; action: Config.options?.tablet.edgeRight  ?? "kill" }
            EdgeCatcher { screen: modelData; edge: "bottom"; hidden: monitorScope.fullscreen; action: Config.options?.tablet.edgeBottom ?? "osk" }
            EdgeCatcher { screen: modelData; edge: "top";    hidden: monitorScope.fullscreen; action: Config.options?.tablet.edgeTop    ?? "search" }
        }
    }
}
