import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.modules.dashboard
import qs.modules.notifications
import qs.modules.osd
import qs.modules.quicksettings
import qs.modules.theme
import qs.modules.wallpapers
import qs.modules.windows

// One transparent strip per monitor holding three floating islands:
//   [ workspace · windows ▾ ]  [ time ]  (wifi)
// The clock is pinned to the exact centre; the others hang off its sides.
Scope {
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property ShellScreen modelData
            readonly property bool quickSettingsOpen: Panels.isOpen("quicksettings", modelData.name)
            readonly property bool dashboardOpen: Panels.isOpen("dashboard", modelData.name)
            readonly property bool wallpapersOpen: Panels.isOpen("wallpapers", modelData.name)
            readonly property bool windowsOpen: Panels.isOpen("windows", modelData.name)
            readonly property bool themeOpen: Panels.isOpen("theme", modelData.name)
            // Wallpaper + theme pickers open from the dashboard, so the clock counts them as its own.
            readonly property bool clockMenuOpen: dashboardOpen || wallpapersOpen || themeOpen

            PanelWindow {
                id: bar

                screen: perScreen.modelData
                visible: Panels.barVisible
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: Appearance.bar.height + Appearance.bar.margin
                color: "transparent"
                WlrLayershell.namespace: "base-bar"

                // Only the islands take clicks; the gaps between them pass through to windows.
                mask: Region {
                    item: clock
                    Region { item: apps }
                    Region { item: qsButton }
                }

                ClockPill {
                    id: clock
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Appearance.bar.margin
                    open: perScreen.clockMenuOpen
                    onClicked: perScreen.clockMenuOpen ? Panels.close() : Panels.toggle("dashboard", perScreen.modelData.name)
                }

                WorkspaceButton {
                    id: apps
                    screen: bar.screen
                    anchors.right: clock.left
                    anchors.rightMargin: Appearance.bar.spacing
                    y: Appearance.bar.margin
                    open: perScreen.windowsOpen
                    onClicked: Panels.toggleWindows(perScreen.modelData.name)
                }

                QuickSettingsButton {
                    id: qsButton
                    anchors.left: clock.right
                    anchors.leftMargin: Appearance.bar.spacing
                    y: Appearance.bar.margin
                    open: perScreen.quickSettingsOpen
                    onClicked: Panels.toggle("quicksettings", perScreen.modelData.name)
                }
            }

            QuickSettings {
                id: quickSettings
                screen: perScreen.modelData
                barWindow: bar
                open: perScreen.quickSettingsOpen
                anchorX: qsButton.x + qsButton.width / 2
                onCloseRequested: Panels.close()
            }

            // Notification toasts under the Wi-Fi island; below the quick-settings card while it's open.
            Toasts {
                screen: perScreen.modelData
                active: Hyprland.focusedMonitor?.name === perScreen.modelData.name
                anchorX: qsButton.x + qsButton.width / 2
                pushDown: perScreen.quickSettingsOpen ? quickSettings.implicitHeight + Appearance.popup.gap : 0
            }

            // Volume / brightness OSD (bottom centre). Stays quiet while quick settings is open.
            OsdPopup {
                screen: perScreen.modelData
                active: Hyprland.focusedMonitor?.name === perScreen.modelData.name
            }

            Dashboard {
                screen: perScreen.modelData
                barWindow: bar
                open: perScreen.dashboardOpen
                anchorX: clock.x + clock.width / 2
                onCloseRequested: Panels.close()
            }

            WallpaperPicker {
                screen: perScreen.modelData
                barWindow: bar
                open: perScreen.wallpapersOpen
                anchorX: clock.x + clock.width / 2
                onCloseRequested: Panels.close()
            }

            WindowOverview {
                screen: perScreen.modelData
                barWindow: bar
                open: perScreen.windowsOpen
                anchorX: apps.x + apps.width / 2
                onCloseRequested: Panels.close()
            }

            ThemePicker {
                screen: perScreen.modelData
                barWindow: bar
                open: perScreen.themeOpen
                anchorX: clock.x + clock.width / 2
                onCloseRequested: Panels.close()
            }
        }
    }
}
