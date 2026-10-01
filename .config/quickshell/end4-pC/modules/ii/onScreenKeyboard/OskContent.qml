import qs.modules.common
import "layouts.js" as Layouts
import QtQuick
import QtQuick.Layouts

Item {
    id: root    
    property var layouts: Layouts.byName
    property var activeLayoutName: (layouts.hasOwnProperty(Config.options?.osk.layout)) 
        ? Config.options?.osk.layout 
        : Layouts.defaultLayout
    property var currentLayout: layouts[activeLayoutName]

    implicitWidth: keyRows.implicitWidth
    implicitHeight: keyRows.implicitHeight

    // Full-width keys: derive a per-key width unit from the actual laid-out width and
    // the widest row, so keys stretch to fill the screen instead of a fixed 45px.
    property real keySpacing: 5
    readonly property var widthUnits: ({
        "normal": 1, "fn": 1, "tab": 1.6, "caps": 1.9, "shift": 2.5,
        "control": 1.3, "space": 5, "expand": 1, "empty": 1
    })
    readonly property var rowMetrics: {
        let maxUnits = 8, maxKeys = 8
        const rows = root.currentLayout?.keys ?? []
        for (let i = 0; i < rows.length; i++) {
            let u = 0
            for (let j = 0; j < rows[i].length; j++) u += (widthUnits[rows[i][j].shape] ?? 1)
            maxUnits = Math.max(maxUnits, u)
            maxKeys = Math.max(maxKeys, rows[i].length)
        }
        return { units: maxUnits, keys: maxKeys }
    }
    readonly property real keyUnit: Math.max(
        Math.round(45 * Appearance.uiScale),
        (width - keySpacing * (rowMetrics.keys - 1)) / rowMetrics.units
    )

    ColumnLayout {
        id: keyRows
        anchors.fill: parent
        spacing: root.keySpacing

        Repeater {
            model: root.currentLayout.keys

            delegate: RowLayout {
                id: keyRow
                required property var modelData
                spacing: root.keySpacing

                Repeater {
                    model: modelData
                    // A normal key looks like this: {label: "a", labelShift: "A", shape: "normal", keycode: 30, type: "normal"}
                    delegate: OskKey {
                        required property var modelData
                        keyData: modelData
                        unit: root.keyUnit
                    }
                }
            }
        }
    }
}
