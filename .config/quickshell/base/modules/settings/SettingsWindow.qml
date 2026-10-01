import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// The Settings window: a real floating window (title "base-settings"; custom/rules.lua floats + centres it),
// sidebar on the left, the chosen page on the right. Opened by the gear in quick settings or
// `qs -c base ipc call settings toggle|open <page>`. Pages are loaded on demand, so scans/polls only run while
// their page is showing.
Scope {
    id: scope

    readonly property var pages: [
        { id: "network", label: "Network", icon: "wifi", source: "NetworkPage.qml" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth", source: "BluetoothPage.qml" },
        { id: "tailscale", label: "Tailscale", icon: "hub", source: "TailscalePage.qml" },
        { id: "display", label: "Display", icon: "desktop_windows", source: "DisplayPage.qml" },
        { id: "sound", label: "Sound", icon: "volume_up", source: "SoundPage.qml" },
        { id: "hyprland", label: "Hyprland", icon: "grid_view", source: "HyprlandPage.qml" },
        { id: "appearance", label: "Appearance", icon: "palette", source: "AppearancePage.qml" }
    ]
    readonly property var page: pages.find(p => p.id === Panels.settingsPage) ?? pages[0]

    IdentifyOverlay {}

    LazyLoader {
        active: Panels.settingsOpen

        FloatingWindow {
            id: win

            title: "base-settings"
            visible: true
            implicitWidth: 1100
            implicitHeight: 760
            minimumSize: Qt.size(820, 520)
            color: Appearance.colors.bg

            // Closed by the compositor (SUPER+Q etc.) → keep Panels in sync.
            onVisibleChanged: if (!visible) Panels.settingsOpen = false

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: Panels.settingsOpen = false

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Sidebar
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 220
                        color: Qt.alpha(Appearance.colors.surface, 0.35)

                        ColumnLayout {
                            anchors {
                                fill: parent
                                margins: 14
                            }
                            spacing: 4

                            StyledText {
                                Layout.leftMargin: 8
                                Layout.topMargin: 6
                                Layout.bottomMargin: 12
                                text: "Settings"
                                font.pixelSize: 22
                                font.bold: true
                            }

                            Repeater {
                                model: scope.pages

                                HoverRect {
                                    required property var modelData
                                    readonly property bool active: scope.page.id === modelData.id

                                    Layout.fillWidth: true
                                    implicitHeight: 40
                                    radius: 12
                                    baseColor: active ? Qt.alpha(Appearance.colors.accent, 0.2) : "transparent"
                                    onClicked: Panels.settingsPage = modelData.id

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        MaterialIcon {
                                            icon: parent.parent.modelData.icon
                                            fill: parent.parent.active
                                            color: parent.parent.active ? Appearance.colors.accent : Appearance.colors.fg
                                        }
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: parent.parent.modelData.label
                                            font.bold: parent.parent.active
                                            color: parent.parent.active ? Appearance.colors.accent : Appearance.colors.fg
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // Page
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 20
                            Layout.bottomMargin: 8

                            StyledText {
                                Layout.fillWidth: true
                                text: scope.page.label
                                font.pixelSize: 20
                                font.bold: true
                            }
                            HoverRect {
                                implicitWidth: 34
                                implicitHeight: 34
                                radius: 17
                                onClicked: Panels.settingsOpen = false

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    icon: "close"
                                }
                            }
                        }

                        Flickable {
                            id: flick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: loader.height + 40
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            flickableDirection: Flickable.VerticalFlick
                            ScrollBar.vertical: ScrollBar {}

                            Loader {
                                id: loader
                                x: 20
                                width: flick.width - 40
                                height: item ? item.implicitHeight : 0
                                source: scope.page.source
                                onSourceChanged: flick.contentY = 0
                            }
                        }
                    }
                }
            }
        }
    }
}
