import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.widgets

// Volume / brightness pill near the bottom centre of one monitor: [icon] ────●──── 42%
// Draggable; the icon mutes (volume). Driven by services/Osd.qml; only the focused monitor's is shown.
PanelWindow {
    id: root

    property bool active   // this is the focused monitor

    readonly property bool isVolume: Osd.kind === "volume"
    readonly property bool shown: active && Osd.shown

    anchors.bottom: true
    margins.bottom: 96
    implicitWidth: 320
    implicitHeight: Appearance.bar.height + 16
    color: "transparent"
    visible: shown || card.opacity > 0

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "base-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Island {
        id: card

        anchors.fill: parent
        radius: height / 2
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92
        Behavior on opacity {
            NumberAnimation { duration: Appearance.anim.normal; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Appearance.anim.normal; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            onHoveredChanged: if (root.active) Osd.hovered = hovered
        }

        IconSlider {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 16
            icon: root.isVolume ? Audio.icon : Brightness.icon
            value: root.isVolume ? (Audio.muted ? 0 : Audio.volume) : Brightness.value
            active: root.isVolume ? Audio.ready : Brightness.available
            onMoved: v => root.isVolume ? Audio.setVolume(v) : Brightness.set(v)
            onIconClicked: if (root.isVolume) Audio.toggleMute()
        }
    }
}
