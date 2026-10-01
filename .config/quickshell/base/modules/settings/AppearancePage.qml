import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Settings → Appearance: shortcuts to the theme and wallpaper pickers (they live under the clock).
ColumnLayout {
    spacing: 18

    Card {
        title: "Look"

        SettingRow {
            label: "Theme"
            hint: `${Theme.current.preset || "Custom"} — colours for the shell and kitty.`

            PillButton {
                icon: "palette"
                text: "Open theme picker"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.toggle("theme", Hyprland.focusedMonitor?.name ?? "");
                }
            }
        }

        SettingRow {
            label: "Wallpaper"

            PillButton {
                icon: "wallpaper"
                text: "Open wallpapers"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.toggle("wallpapers", Hyprland.focusedMonitor?.name ?? "");
                }
            }
        }
    }
}
