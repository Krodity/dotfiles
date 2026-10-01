import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Draws the wallpaper on every monitor (the background layer, under all windows).
// Follows Wallpapers.current, so the picker — or anything else that writes config.json — updates it.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "base-wallpaper"
            color: "black"

            // Two images, cross-faded: the new one loads underneath, then fades in over the old.
            property bool showA: true

            function load() {
                const src = Wallpapers.current ? `file://${Wallpapers.current}` : "";
                (showA ? imgB : imgA).source = src;
            }

            Component.onCompleted: load()
            Connections {
                target: Wallpapers
                function onCurrentChanged() {
                    win.load();
                }
            }

            // Picker "Scaling" setting → Image fill mode. Fit/Center/Tile leave black around the image.
            readonly property int fillMode: ({
                    fill: Image.PreserveAspectCrop,
                    fit: Image.PreserveAspectFit,
                    stretch: Image.Stretch,
                    center: Image.Pad,
                    tile: Image.Tile
                })[Wallpapers.fit] ?? Image.PreserveAspectCrop

            component Wall: Image {
                anchors.fill: parent
                fillMode: win.fillMode
                asynchronous: true
                cache: false
                // Decode at most monitor resolution — some wallpapers are 8x upscales. (So Center/Tile show
                // big images shrunk to fit the monitor; smaller ones at their real size.)
                sourceSize.width: win.modelData.width * win.modelData.devicePixelRatio
                sourceSize.height: win.modelData.height * win.modelData.devicePixelRatio
                Behavior on opacity {
                    NumberAnimation { duration: 400 }
                }
            }

            Wall {
                id: imgA
                opacity: win.showA ? 1 : 0
                onStatusChanged: if (status === Image.Ready && !win.showA) win.showA = true
            }
            Wall {
                id: imgB
                opacity: win.showA ? 0 : 1
                onStatusChanged: if (status === Image.Ready && win.showA) win.showA = false
            }
        }
    }
}
