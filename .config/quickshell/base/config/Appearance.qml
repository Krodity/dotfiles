pragma Singleton

import Quickshell
import QtQuick

// Shared look-and-feel tokens. Use from anywhere: `import qs.config` → Appearance.colors.bg
Singleton {
    // Live palette — edited in the theme picker, stored by Theme.qml; flipped by the Dark mode tile.
    readonly property QtObject colors: QtObject {
        readonly property color bg: Theme.colors.bg              // island + popup fill
        readonly property color border: Theme.colors.border
        readonly property color surface: Theme.colors.surface    // tiles, slider tracks, list rows
        readonly property color surfaceHover: Theme.colors.surfaceHover
        readonly property color fg: Theme.colors.fg
        readonly property color muted: Theme.colors.muted
        readonly property color accent: Theme.colors.accent
        readonly property color accentText: Theme.colors.accentText
    }

    readonly property QtObject font: QtObject {
        readonly property string family: "sans-serif"
        readonly property string iconFamily: "Material Symbols Rounded"
        readonly property int size: 13
        readonly property int small: 11
        readonly property int iconSize: 18
    }

    readonly property QtObject bar: QtObject {
        readonly property int height: 36     // island height
        readonly property int margin: 6      // gap between screen edge and islands
        readonly property int spacing: 8     // gap between islands
        readonly property int padding: 14    // inner horizontal padding of a pill
    }

    readonly property QtObject popup: QtObject {
        readonly property int width: 380
        readonly property int radius: 22
        readonly property int padding: 14
        readonly property int gap: 8         // space between bar and popup
    }

    readonly property QtObject launcher: QtObject {
        readonly property real opacity: 0.65 // card fill; colours still come from the theme
    }

    readonly property QtObject dock: QtObject {
        readonly property int icon: 44       // app icon size at rest
        readonly property int cell: 56       // slot per icon (icon + gap)
        readonly property int padding: 6     // inside the dock card
        readonly property int margin: 8      // gap between the card and the screen's bottom edge
        readonly property real magnify: 0.8  // extra scale of the icon right under the pointer (1.8×)
        readonly property int revealDelay: 150 // ms the pointer must rest on the bottom edge to show it
        readonly property int hideDelay: 450 // ms after the pointer leaves before it slides away
    }

    readonly property QtObject anim: QtObject {
        readonly property int fast: 120
        readonly property int normal: 200
    }
}
