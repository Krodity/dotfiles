import QtQuick
import qs.config
import qs.services
import qs.widgets

// Scaled map of the draft monitor layout (logical coordinates). Click selects, drag moves; while dragging, the
// monitor's edges snap to its neighbours' edges (side by side, stacked, aligned or centred).
Item {
    id: canvas

    property int selected: 0
    signal picked(int index)

    implicitHeight: 300

    // Bounds of every enabled monitor. Frozen while dragging so the map doesn't rescale under the pointer.
    property bool dragging: false
    property var frozenBox: null
    readonly property var liveBox: {
        const on = Monitors.enabledIdx.map(i => ({ m: Monitors.draft[i], s: Monitors.logical(Monitors.draft[i]) }));
        if (on.length === 0) return { x0: 0, y0: 0, x1: 1920, y1: 1080 };
        return {
            x0: Math.min(...on.map(o => o.m.x)),
            y0: Math.min(...on.map(o => o.m.y)),
            x1: Math.max(...on.map(o => o.m.x + o.s.w)),
            y1: Math.max(...on.map(o => o.m.y + o.s.h))
        };
    }
    readonly property var box: dragging && frozenBox ? frozenBox : liveBox
    readonly property real f: Math.min((width - 60) / Math.max(1, box.x1 - box.x0), (height - 60) / Math.max(1, box.y1 - box.y0))
    readonly property real ox: (width - (box.x1 - box.x0) * f) / 2 - box.x0 * f
    readonly property real oy: (height - (box.y1 - box.y0) * f) / 2 - box.y0 * f

    // Nearest edge-to-edge position within ~20 screen px of (x, y), per axis.
    function snap(i, x, y) {
        const self = Monitors.logical(Monitors.draft[i]);
        const t = 20 / f;
        let bx = x, by = y, dx = t, dy = t;
        for (const j of Monitors.enabledIdx) {
            if (j === i) continue;
            const o = Monitors.draft[j], s = Monitors.logical(o);
            for (const c of [o.x - self.w, o.x + s.w, o.x, o.x + s.w - self.w]) {
                if (Math.abs(c - x) < dx) {
                    dx = Math.abs(c - x);
                    bx = c;
                }
            }
            for (const c of [o.y - self.h, o.y + s.h, o.y, o.y + s.h - self.h, o.y + (s.h - self.h) / 2]) {
                if (Math.abs(c - y) < dy) {
                    dy = Math.abs(c - y);
                    by = c;
                }
            }
        }
        return { x: Math.round(bx), y: Math.round(by) };
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Qt.alpha(Appearance.colors.bg, 0.5)
        border.width: 1
        border.color: Appearance.colors.border
    }

    Repeater {
        model: Monitors.draft.length

        Rectangle {
            id: mon

            required property int index
            readonly property var m: Monitors.draft[index] ?? null
            readonly property var sz: m ? Monitors.logical(m) : ({ w: 0, h: 0 })
            readonly property bool isSelected: canvas.selected === index

            visible: m !== null && !m.disabled
            x: canvas.ox + (m?.x ?? 0) * canvas.f
            y: canvas.oy + (m?.y ?? 0) * canvas.f
            width: Math.max(8, sz.w * canvas.f - 2)
            height: Math.max(8, sz.h * canvas.f - 2)
            z: drag.pressed ? 2 : isSelected ? 1 : 0
            radius: 8
            color: isSelected ? Qt.alpha(Appearance.colors.accent, 0.3) : Appearance.colors.surface
            border.width: isSelected ? 2 : 1
            border.color: isSelected ? Appearance.colors.accent : Appearance.colors.border

            Column {
                anchors.centerIn: parent
                width: parent.width - 12
                spacing: 2

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: mon.m?.label ?? ""
                    font.bold: true
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: mon.m ? `${mon.m.name} · ${mon.m.w}×${mon.m.h}` : ""
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: drag

                property point press
                property point origin

                anchors.fill: parent
                preventStealing: true   // the settings page is a Flickable; don't let it take the drag
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: mouse => {
                    canvas.picked(mon.index);
                    canvas.frozenBox = canvas.liveBox;
                    canvas.dragging = true;
                    press = mapToItem(canvas, mouse.x, mouse.y);
                    origin = Qt.point(mon.m.x, mon.m.y);
                }
                onPositionChanged: mouse => {
                    const p = mapToItem(canvas, mouse.x, mouse.y);
                    const s = canvas.snap(mon.index, origin.x + (p.x - press.x) / canvas.f, origin.y + (p.y - press.y) / canvas.f);
                    if (s.x !== mon.m.x || s.y !== mon.m.y) Monitors.update(mon.index, s);
                }
                onReleased: {
                    canvas.dragging = false;
                    Monitors.normalize();
                }
            }
        }
    }
}
