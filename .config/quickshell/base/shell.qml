// Entry point. Run with: qs -c base
//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma IconTheme Papirus-Dark
import Quickshell
import QtQuick
import qs.modules.background
import qs.modules.bar
import qs.modules.carousel
import qs.modules.dismiss
import qs.modules.launcher
import qs.modules.settings
import qs.services

ShellRoot {
    // Load the dark-mode state at startup so the shell comes up flipped if the system is already light.
    Component.onCompleted: DarkMode.refresh()

    Background {}
    Bar {}
    OutsideClick {}
    SettingsWindow {}

    Variants {
        model: Quickshell.screens

        Launcher {
            required property ShellScreen modelData
            screen: modelData
            open: Panels.isOpen("launcher", modelData.name)
            onCloseRequested: Panels.close()
        }
    }

    Variants {
        model: Quickshell.screens

        WallpaperCarousel {
            required property ShellScreen modelData
            screen: modelData
            open: Panels.isOpen("carousel", modelData.name)
            onCloseRequested: Panels.close()
        }
    }
}
