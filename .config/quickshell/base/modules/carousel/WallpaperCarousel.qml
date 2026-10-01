import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.widgets

// Wallpaper carousel: a looping row of wallpapers over a dimmed screen; the centre one is enlarged.
// SUPER+ALT+W (or `qs -c base ipc call carousel toggle`).
// ←/→ · h/l · wheel · drag to scroll · click a side card to bring it to the centre ·
// Enter / click the centre card sets it · Esc / click outside closes.
PanelWindow {
    id: root

    property bool open
    signal closeRequested

    readonly property var files: Wallpapers.files
    readonly property string selected: files[view.currentIndex] ?? ""

    // Tall 2:5 cards sized from the monitor height, 25 px apart. The path spaces unscaled cards evenly
    // (step = width + gap); each card is then nudged sideways (`shift`) so the gap stays 25 px next to the
    // enlarged centre card too. Enough cards to overfill the screen; the outer ones fade at the edges.
    readonly property real centerScale: 1.44 // centre card = 82% of the screen height
    readonly property real gap: 25
    readonly property real cardHeight: Math.round(height * 0.57)
    readonly property real cardWidth: Math.round(cardHeight * 2 / 5)
    readonly property int side: 4 // cards shown on each side of the centre
    readonly property real step: cardWidth + gap
    // The row is bent over an arch: a circle of radius archRadius whose top is the centre card. Cards keep their
    // spacing along the curve, drop and tilt outward as they move away, reaching ~35° at the screen edge.
    readonly property real archRadius: (width / 2) / (35 * Math.PI / 180)
    // `side` cards each side plus one spare each way that fades in while scrolling.
    readonly property int count: side * 2 + 3
    readonly property real pathLength: count * step

    function apply(path) {
        if (!path) return;
        if (path !== Wallpapers.current) Wallpapers.set(path);
        closeRequested();
    }

    // Jump (no animation) to the current wallpaper when opening.
    function jumpToCurrent() {
        const i = files.indexOf(Wallpapers.current);
        const d = view.highlightMoveDuration;
        view.highlightMoveDuration = 0;
        view.currentIndex = Math.max(0, i);
        view.highlightMoveDuration = d;
    }

    onOpenChanged: {
        if (open) {
            jumpToCurrent();
            view.forceActiveFocus();
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "base-carousel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Stay mapped until the fade-out finishes.
    visible: open || stage.opacity > 0

    // Backdrop tinted with the theme background; clicking it closes.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Appearance.colors.bg, 1)
        opacity: root.open ? 0.85 : 0
        Behavior on opacity {
            NumberAnimation { duration: Appearance.anim.normal }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    Item {
        id: stage

        anchors.fill: parent
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        Behavior on opacity {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }

        PathView {
            id: view

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -root.height * 0.045
            height: root.cardHeight * root.centerScale + 40

            model: root.files
            pathItemCount: root.count
            cacheItemCount: 2
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: 380
            snapMode: PathView.SnapToItem
            flickDeceleration: 900
            maximumFlickVelocity: 4000
            focus: true

            path: Path {
                startX: (view.width - root.pathLength) / 2
                startY: view.height / 2
                PathLine { x: (view.width + root.pathLength) / 2; y: view.height / 2 }
            }

            Keys.onLeftPressed: decrementCurrentIndex()
            Keys.onRightPressed: incrementCurrentIndex()
            Keys.onReturnPressed: root.apply(root.selected)
            Keys.onEnterPressed: root.apply(root.selected)
            Keys.onEscapePressed: root.closeRequested()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_H) decrementCurrentIndex();
                else if (event.key === Qt.Key_L) incrementCurrentIndex();
                else if (event.key === Qt.Key_Home) currentIndex = 0;
                else if (event.key === Qt.Key_End) currentIndex = count - 1;
            }

            // One card per wheel notch (touchpads accumulate), either wheel axis.
            WheelHandler {
                property real acc: 0
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    acc += Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? -event.angleDelta.x : event.angleDelta.y;
                    while (acc >= 120) { view.decrementCurrentIndex(); acc -= 120; }
                    while (acc <= -120) { view.incrementCurrentIndex(); acc += 120; }
                }
            }

            delegate: Item {
                id: card

                required property string modelData
                required property int index
                readonly property bool isCenter: PathView.isCurrentItem
                readonly property bool isWallpaper: modelData === Wallpapers.current

                // Continuous distance from the centre in cards (0 = centred, ±1 = neighbours), so size and
                // spacing change smoothly while scrolling rather than per step.
                readonly property real rel: (x + width / 2 - view.width / 2) / root.step
                readonly property real near: Math.max(0, 1 - Math.abs(rel))
                // Push cards out by half the centre card's extra width, so every gap is exactly root.gap.
                readonly property real shift: Math.max(-1, Math.min(1, rel)) * (root.centerScale - 1) * root.cardWidth / 2
                // Distance along the arch → angle; the card slides to that point on the circle and tilts with it.
                // The spacing is measured along the cards' bottom edges (where tilted cards pinch together), so
                // centres ride a circle half a card taller and the narrowest gap is still root.gap.
                readonly property real angle: (rel * root.step + shift) / root.archRadius
                readonly property real centreRadius: root.archRadius + root.cardHeight / 2
                readonly property real archX: centreRadius * Math.sin(angle) - (rel * root.step + shift)
                readonly property real archY: centreRadius * (1 - Math.cos(angle))
                // Fade out over the last card-width before the screen edge.
                readonly property real edgeRoom: view.width / 2 - Math.abs(centreRadius * Math.sin(angle)) - root.cardWidth / 2

                width: root.cardWidth
                height: root.cardHeight
                antialiasing: true // clean edges when tilted on the arch
                scale: 1 + (root.centerScale - 1) * near
                // Beyond `side` cards out (and near the screen edge on narrow monitors) fade away.
                opacity: Math.max(0, Math.min(1, edgeRoom / root.cardWidth + 0.35, root.side + 1 - Math.abs(rel)))
                z: near * 10 - Math.abs(rel) * 0.01
                rotation: angle * 180 / Math.PI
                transform: Translate { x: card.shift + card.archX; y: card.archY }

                // Soft shadow.
                Rectangle {
                    anchors.fill: frame
                    anchors.margins: -2
                    anchors.topMargin: 6
                    anchors.bottomMargin: -10
                    radius: frame.radius + 4
                    color: "#000000"
                    opacity: card.isCenter ? 0.35 : 0.18
                    Behavior on opacity {
                        NumberAnimation { duration: Appearance.anim.normal }
                    }
                }

                ClippingRectangle {
                    id: frame

                    anchors.fill: parent
                    radius: 16
                    color: Appearance.colors.surface

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: thumb.status !== Image.Ready && full.status !== Image.Ready
                        icon: "image"
                        size: 32
                        color: Appearance.colors.muted
                    }

                    // Small cached thumbnail shows instantly; the sharper decode fades in over it.
                    Image {
                        id: thumb
                        anchors.fill: parent
                        source: Wallpapers.thumbFor(card.modelData)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Image {
                        id: full
                        anchors.fill: parent
                        source: `file://${card.modelData}`
                        // Decode at the centre card's size in *physical* pixels (DP-2 runs at 1.25×), so it's never
                        // upscaled; mipmaps keep the smaller, tilted side cards crisp instead of shimmering.
                        sourceSize.height: Math.round(root.cardHeight * root.centerScale * (root.screen?.devicePixelRatio ?? 1))
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        mipmap: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: Appearance.anim.normal }
                        }
                    }

                    // Side cards are slightly dimmed.
                    Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        opacity: card.isCenter ? 0 : (hover.hovered ? 0.1 : 0.25)
                        Behavior on opacity {
                            NumberAnimation { duration: Appearance.anim.normal }
                        }
                    }
                }

                // Accent ring on the wallpaper that's set now.
                Rectangle {
                    anchors.fill: parent
                    radius: frame.radius
                    color: "transparent"
                    border.width: card.isWallpaper ? 3 : (card.isCenter ? 1 : 0)
                    border.color: card.isWallpaper ? Appearance.colors.accent : Qt.rgba(1, 1, 1, 0.35)
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (card.isCenter) root.apply(card.modelData);
                        else view.currentIndex = card.index;
                    }
                }
            }
        }

        // Position counter + a bar that slides with the row, under it.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: view.bottom
            anchors.topMargin: 18
            spacing: 8

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: `${view.currentIndex + 1} / ${root.files.length}`
                color: root.selected === Wallpapers.current ? Appearance.colors.accent : Appearance.colors.fg
                font.pixelSize: 14
                font.bold: true
                font.features: ({ "tnum": 1 }) // fixed-width digits, so the text doesn't jiggle while counting
            }

            // Follows PathView.offset (continuous), so it glides during the move animation and tracks drags live.
            Rectangle {
                id: track

                readonly property real pos: view.count ? (view.count - view.offset) % view.count : 0

                anchors.horizontalCenter: parent.horizontalCenter
                width: 220
                height: 4
                radius: 2
                color: Appearance.colors.surface

                Rectangle {
                    width: Math.max(height, track.width * (track.pos + 1) / Math.max(1, view.count))
                    height: parent.height
                    radius: parent.radius
                    color: Appearance.colors.accent
                }
            }
        }
    }
}
