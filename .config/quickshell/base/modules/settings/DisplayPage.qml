import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Settings → Display: drag-to-arrange map + resolution / refresh / scale / orientation / position per monitor.
// Nothing touches Hyprland until Apply; then Keep within 15 s or it reverts by itself.
ColumnLayout {
    id: root

    property int sel: 0
    readonly property var m: Monitors.draft[sel] ?? null

    readonly property var resolutions: {
        if (!m) return [];
        const seen = {}, out = [];
        for (const md of m.modes.slice().sort((a, b) => b.w * b.h - a.w * a.h || b.w - a.w)) {
            const k = `${md.w}x${md.h}`;
            if (seen[k]) continue;
            seen[k] = true;
            out.push({ value: k, label: `${md.w} × ${md.h}` });
        }
        return out;
    }
    readonly property var rates: m ? m.modes.filter(md => md.w === m.w && md.h === m.h)
        .sort((a, b) => b.rate - a.rate)
        .filter((md, i, a) => i === 0 || a[i - 1].rate !== md.rate)
        .map(md => ({ value: md.rate, label: `${md.text} Hz` })) : []
    readonly property var scales: {
        const list = [1, 1.25, 1.5, 1.6, 1.75, 2];
        if (m && !list.includes(m.scale)) list.push(m.scale);
        return list.sort((a, b) => a - b).map(s => ({ value: s, label: `${Math.round(s * 100)}%` }));
    }

    spacing: 18
    Component.onCompleted: Monitors.refresh()

    Card {
        title: "Arrangement"

        MonitorCanvas {
            Layout.fillWidth: true
            selected: root.sel
            onPicked: i => root.sel = i
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: Monitors.layoutWarning || "Drag a monitor to move it; edges snap together."
                color: Monitors.layoutWarning ? Appearance.colors.accent : Appearance.colors.muted
                font.pixelSize: Appearance.font.small
                wrapMode: Text.Wrap
            }
            PillButton {
                icon: "view_column"
                text: "Line up"
                onClicked: Monitors.autoArrange()
            }
            PillButton {
                icon: "tag"
                text: "Identify"
                onClicked: Monitors.identify = true
            }
        }

        // Monitor chips — also the only way to reach a disabled monitor.
        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: Monitors.draft.length

                HoverRect {
                    required property int index
                    readonly property var mon: Monitors.draft[index]
                    readonly property bool active: root.sel === index

                    implicitWidth: chip.implicitWidth + 24
                    implicitHeight: 30
                    radius: 15
                    baseColor: active ? Appearance.colors.accent : Appearance.colors.surface
                    hoverColor: active ? Appearance.colors.accent : Appearance.colors.surfaceHover
                    onClicked: root.sel = index

                    StyledText {
                        id: chip
                        anchors.centerIn: parent
                        text: `${parent.mon?.label ?? ""}${parent.mon?.disabled ? " (off)" : ""}`
                        font.pixelSize: Appearance.font.small
                        color: parent.active ? Appearance.colors.accentText : Appearance.colors.fg
                    }
                }
            }
        }
    }

    Card {
        visible: root.m !== null
        title: root.m ? `${root.m.label} · ${root.m.name}` : ""

        SettingRow {
            label: "Enabled"
            hint: "Workspaces on a monitor you switch off move to the others."

            Switch {
                checked: !(root.m?.disabled ?? false)
                onToggled: Monitors.update(root.sel, { disabled: !root.m.disabled })
            }
        }

        SettingRow {
            label: "Resolution"
            enabled: !(root.m?.disabled ?? true)
            opacity: enabled ? 1 : 0.4

            Dropdown {
                implicitWidth: 220
                options: root.resolutions
                current: root.m ? `${root.m.w}x${root.m.h}` : ""
                onSelected: v => {
                    const [w, h] = v.split("x").map(Number);
                    const best = root.m.modes.filter(md => md.w === w && md.h === h).sort((a, b) => b.rate - a.rate)[0];
                    Monitors.update(root.sel, { w, h, rate: best.rate });
                }
            }
        }

        SettingRow {
            label: "Refresh rate"
            enabled: !(root.m?.disabled ?? true)
            opacity: enabled ? 1 : 0.4

            Dropdown {
                implicitWidth: 220
                options: root.rates
                current: root.m?.rate
                onSelected: v => Monitors.update(root.sel, { rate: v })
            }
        }

        SettingRow {
            label: "Scale"
            hint: "Hyprland rounds scales that don't divide the resolution evenly."
            enabled: !(root.m?.disabled ?? true)
            opacity: enabled ? 1 : 0.4

            Dropdown {
                implicitWidth: 220
                options: root.scales
                current: root.m?.scale
                onSelected: v => Monitors.update(root.sel, { scale: v })
            }
        }

        SettingRow {
            label: "Orientation"
            enabled: !(root.m?.disabled ?? true)
            opacity: enabled ? 1 : 0.4

            SegmentedControl {
                implicitWidth: 380
                options: [
                    { value: "0", label: "Landscape" },
                    { value: "1", label: "Portrait" },
                    { value: "2", label: "Upside down" },
                    { value: "3", label: "Portrait (left)" }
                ]
                current: String((root.m?.transform ?? 0) % 4)
                onSelected: v => Monitors.update(root.sel, { transform: Number(v) + (root.m.transform >= 4 ? 4 : 0) })
            }
        }

        SettingRow {
            label: "Mirror image"
            hint: "Flips the picture horizontally."
            enabled: !(root.m?.disabled ?? true)
            opacity: enabled ? 1 : 0.4

            Switch {
                checked: (root.m?.transform ?? 0) >= 4
                onToggled: Monitors.update(root.sel, { transform: (root.m.transform + 4) % 8 })
            }
        }

        SettingRow {
            label: "Position"
            hint: "Top-left corner in logical pixels."
            enabled: !(root.m?.disabled ?? true)
            opacity: enabled ? 1 : 0.4

            Row {
                spacing: 6

                Repeater {
                    model: ["x", "y"]

                    TextField {
                        id: field
                        required property string modelData
                        width: 90
                        height: 34
                        text: String(Math.round(root.m?.[modelData] ?? 0))
                        validator: IntValidator {}
                        color: Appearance.colors.fg
                        font.pixelSize: Appearance.font.size
                        horizontalAlignment: TextInput.AlignHCenter
                        leftPadding: 18
                        background: Rectangle {
                            radius: 12
                            color: Appearance.colors.surface
                            border.width: field.activeFocus ? 1 : 0
                            border.color: Appearance.colors.accent

                            StyledText {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: field.modelData.toUpperCase()
                                color: Appearance.colors.muted
                                font.pixelSize: Appearance.font.small
                            }
                        }
                        onEditingFinished: {
                            const c = {};
                            c[modelData] = Number(text);
                            Monitors.update(root.sel, c);
                        }
                    }
                }
            }
        }
    }

    // Apply / confirm bar.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: bar.implicitHeight + 24
        radius: 18
        color: Monitors.countdown > 0 ? Qt.alpha(Appearance.colors.accent, 0.18) : Qt.alpha(Appearance.colors.surface, 0.55)
        border.width: Monitors.countdown > 0 ? 1 : 0
        border.color: Appearance.colors.accent

        RowLayout {
            id: bar
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 14
            }
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: Monitors.error ? Monitors.error
                    : Monitors.countdown > 0 ? `Keep these display settings? Reverting in ${Monitors.countdown} s.`
                    : Monitors.busy ? "Applying…"
                    : Monitors.dirty ? "Unapplied changes." : "Saved to ~/.config/hypr/monitors.lua when you keep a change."
                color: Monitors.error ? Appearance.colors.accent : Monitors.countdown > 0 ? Appearance.colors.fg : Appearance.colors.muted
                font.pixelSize: Appearance.font.small
            }

            PillButton {
                visible: Monitors.countdown > 0
                text: "Revert"
                onClicked: Monitors.revert()
            }
            PillButton {
                visible: Monitors.countdown > 0
                primary: true
                icon: "check"
                text: "Keep"
                onClicked: Monitors.keep()
            }
            PillButton {
                visible: Monitors.countdown === 0
                enabled: Monitors.dirty
                text: "Reset"
                onClicked: Monitors.reset()
            }
            PillButton {
                visible: Monitors.countdown === 0
                enabled: Monitors.dirty && !Monitors.busy
                primary: true
                icon: "done"
                text: "Apply"
                onClicked: Monitors.apply()
            }
        }
    }
}
