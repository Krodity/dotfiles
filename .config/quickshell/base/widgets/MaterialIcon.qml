import QtQuick
import qs.config

// A Material Symbols glyph by name, e.g. MaterialIcon { icon: "wifi" }
StyledText {
    property string icon
    property bool fill: false
    property int size: Appearance.font.iconSize

    text: icon
    font.family: Appearance.font.iconFamily
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill ? 1 : 0 })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
