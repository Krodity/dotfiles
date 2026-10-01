import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Settings → Hyprland: tiling layout, gaps/borders, effects, input. Every change applies live and is saved to
// hyprland/shellOverrides/main.lua (loaded last), see services/HyprOptions.qml.
ColumnLayout {
    id: root

    readonly property string layout: HyprOptions.get("general:layout", "dwindle")

    spacing: 18
    Component.onCompleted: HyprOptions.refresh()

    component Slide: SettingRow {
        id: s
        property string key
        property real from: 0
        property real to: 1
        property real step: 1
        property int decimals: 0
        property string suffix: ""
        property real displayScale: 1

        ValueSlider {
            implicitWidth: 280
            from: s.from
            to: s.to
            stepSize: s.step
            decimals: s.decimals
            suffix: s.suffix
            displayScale: s.displayScale
            value: HyprOptions.get(s.key, s.from)
            onMoved: v => HyprOptions.set(s.key, v)
        }
    }

    component Toggle: SettingRow {
        id: t
        property string key

        Switch {
            checked: HyprOptions.get(t.key, false) === true
            onToggled: HyprOptions.set(t.key, !checked)
        }
    }

    component Choice: SettingRow {
        id: c
        property string key
        property var options: []

        Dropdown {
            implicitWidth: 220
            options: c.options
            current: HyprOptions.get(c.key, "")
            onSelected: v => HyprOptions.set(c.key, v)
        }
    }

    Card {
        title: "Tiling"

        SettingRow {
            label: "Layout"
            hint: "How new windows are placed."

            SegmentedControl {
                implicitWidth: 400
                options: [
                    { value: "dwindle", label: "Dwindle", icon: "view_quilt" },
                    { value: "master", label: "Master", icon: "view_sidebar" },
                    { value: "scrolling", label: "Scrolling", icon: "view_week" },
                    { value: "monocle", label: "Monocle", icon: "crop_square" }
                ]
                current: root.layout
                onSelected: v => HyprOptions.set("general:layout", v)
            }
        }

        Toggle {
            visible: root.layout === "dwindle"
            label: "Preserve split"
            hint: "Keep a split's direction when windows around it change."
            key: "dwindle:preserve_split"
        }

        Choice {
            visible: root.layout === "master"
            label: "Master side"
            key: "master:orientation"
            options: ["left", "right", "top", "bottom", "center"].map(v => ({ value: v, label: v[0].toUpperCase() + v.slice(1) }))
        }

        Choice {
            visible: root.layout === "master"
            label: "New windows open as"
            key: "master:new_status"
            options: [
                { value: "slave", label: "Stack" },
                { value: "master", label: "Master" },
                { value: "inherit", label: "Same as focused" }
            ]
        }

        Slide {
            visible: root.layout === "scrolling"
            label: "Column width"
            hint: "Share of the screen a new column takes."
            key: "scrolling:column_width"
            from: 0.1
            to: 1
            step: 0.05
            displayScale: 100
            suffix: "%"
        }
    }

    Card {
        title: "Windows"

        Slide {
            label: "Gaps between windows"
            key: "general:gaps_in"
            to: 40
            suffix: " px"
        }
        Slide {
            label: "Gaps at screen edges"
            key: "general:gaps_out"
            to: 60
            suffix: " px"
        }
        Slide {
            label: "Border width"
            key: "general:border_size"
            to: 10
            suffix: " px"
        }
        Slide {
            label: "Corner rounding"
            key: "decoration:rounding"
            to: 40
            suffix: " px"
        }
        Toggle {
            label: "Resize by dragging borders"
            key: "general:resize_on_border"
        }
    }

    Card {
        title: "Effects"

        Toggle {
            label: "Blur"
            key: "decoration:blur:enabled"
        }
        Slide {
            visible: HyprOptions.get("decoration:blur:enabled", false) === true
            label: "Blur size"
            key: "decoration:blur:size"
            from: 1
            to: 20
        }
        Slide {
            visible: HyprOptions.get("decoration:blur:enabled", false) === true
            label: "Blur passes"
            key: "decoration:blur:passes"
            from: 1
            to: 6
        }
        Toggle {
            label: "Shadows"
            key: "decoration:shadow:enabled"
        }
        Slide {
            label: "Focused window opacity"
            key: "decoration:active_opacity"
            from: 0.3
            to: 1
            step: 0.01
            displayScale: 100
            suffix: "%"
        }
        Slide {
            label: "Other windows opacity"
            key: "decoration:inactive_opacity"
            from: 0.3
            to: 1
            step: 0.01
            displayScale: 100
            suffix: "%"
        }
        Toggle {
            label: "Dim unfocused windows"
            key: "decoration:dim_inactive"
        }
        Slide {
            visible: HyprOptions.get("decoration:dim_inactive", false) === true
            label: "Dim amount"
            key: "decoration:dim_strength"
            to: 0.5
            step: 0.01
            displayScale: 100
            suffix: "%"
        }
        Toggle {
            label: "Animations"
            key: "animations:enabled"
        }
    }

    Card {
        title: "Input"

        Choice {
            label: "Focus follows mouse"
            key: "input:follow_mouse"
            options: [
                { value: 0, label: "Off (click to focus)" },
                { value: 1, label: "Always" },
                { value: 2, label: "Loose" },
                { value: 3, label: "Pointer only" }
            ]
        }
        Slide {
            label: "Mouse sensitivity"
            key: "input:sensitivity"
            from: -1
            to: 1
            step: 0.05
            decimals: 2
        }
        Toggle {
            label: "Natural scrolling (mouse)"
            key: "input:natural_scroll"
        }
        Slide {
            label: "Key repeat rate"
            key: "input:repeat_rate"
            from: 10
            to: 80
            suffix: " /s"
        }
        Slide {
            label: "Key repeat delay"
            key: "input:repeat_delay"
            from: 150
            to: 1000
            step: 10
            suffix: " ms"
        }
    }

    Card {
        title: "Display sync"

        Choice {
            label: "Variable refresh rate"
            hint: "\"Always\" is left out on purpose: it wedged the Alienware (its CRTC can't do VRR)."
            key: "misc:vrr"
            options: [
                { value: 0, label: "Off" },
                { value: 2, label: "Fullscreen only" }
            ]
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        text: HyprOptions.error || "Changes apply immediately and are saved to hyprland/shellOverrides/main.lua."
        color: HyprOptions.error ? Appearance.colors.accent : Appearance.colors.muted
        font.pixelSize: Appearance.font.small
        wrapMode: Text.Wrap
    }
}
