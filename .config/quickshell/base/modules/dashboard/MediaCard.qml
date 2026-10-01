import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Now playing: art, title/artist, seekable progress, prev / play-pause / next.
// The source button top-right opens a list of every MPRIS player: pick one to pin it, or Auto to follow
// whatever's playing.
Rectangle {
    id: root

    readonly property MprisPlayer player: Media.active
    property bool picking: false
    // Poll the browsers' tabs only while the list is open.
    onPickingChanged: BrowserTabs.watchers += picking ? 1 : -1
    Component.onDestruction: if (picking) BrowserTabs.watchers -= 1
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    implicitHeight: player ? content.implicitHeight + 24 : 56
    radius: 18
    color: Appearance.colors.surface

    component ControlButton: HoverRect {
        property string icon
        property bool primary

        implicitWidth: primary ? 44 : 36
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
        baseColor: primary ? Appearance.colors.accent : "transparent"
        hoverColor: primary ? Qt.lighter(Appearance.colors.accent, 1.1) : Appearance.colors.surfaceHover

        MaterialIcon {
            anchors.centerIn: parent
            icon: parent.icon
            fill: true
            size: parent.primary ? 26 : 22
            color: parent.primary ? Appearance.colors.accentText : Appearance.colors.fg
        }
    }

    StyledText {
        visible: !root.player
        anchors.centerIn: parent
        text: "Nothing playing"
        color: Appearance.colors.muted
    }

    ColumnLayout {
        id: content
        visible: root.player !== null
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ClippingRectangle {
                id: art
                Layout.alignment: Qt.AlignTop
                // Video frames get a 16:9 box (112 × 16/9 ≈ 199) so the whole frame shows.
                readonly property bool video: !root.player?.trackArtUrl && Media.activeThumb !== ""
                implicitWidth: video ? 199 : 112
                implicitHeight: 112
                radius: 14
                color: Appearance.colors.surfaceHover

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    icon: "music_note"
                    size: 40
                    color: Appearance.colors.muted
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.player?.trackArtUrl || Media.activeThumb
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 398
                    sourceSize.height: 224
                }
            }

            ColumnLayout {
                id: info
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: Media.activeInfo.title
                        font.bold: true
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    // Source button: which player is shown. Click → list of players below.
                    HoverRect {
                        implicitHeight: 24
                        implicitWidth: chipRow.implicitWidth + 16
                        radius: 12
                        baseColor: root.picking ? Qt.alpha(Appearance.colors.accent, 0.18) : Appearance.colors.bg
                        onClicked: root.picking = !root.picking

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: Media.pinned ? "push_pin" : "swap_horiz"
                                size: 15
                                color: Media.pinned ? Appearance.colors.accent : Appearance.colors.muted
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Media.players.length > 1
                                    ? `${root.player?.identity ?? ""}  ${Media.players.indexOf(root.player) + 1}/${Media.players.length}`
                                    : (root.player?.identity ?? "")
                                font.pixelSize: Appearance.font.small
                                color: Appearance.colors.muted
                            }
                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: root.picking ? "expand_less" : "expand_more"
                                size: 15
                                color: Appearance.colors.muted
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Media.activeInfo.subtitle
                    color: Appearance.colors.muted
                    elide: Text.ElideRight
                }

                // Progress bar — click to seek when the player allows it.
                Item {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    implicitHeight: 12
                    visible: (root.player?.length ?? 0) > 0

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Appearance.colors.bg

                        Rectangle {
                            width: parent.width * root.progress
                            height: parent.height
                            radius: 2
                            color: Appearance.colors.accent
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player?.canSeek ?? false
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mouse => root.player.position = mouse.x / width * root.player.length
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: (root.player?.length ?? 0) > 0

                    StyledText {
                        text: Media.formatTime(root.player?.position ?? 0)
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: Media.formatTime(root.player?.length ?? 0)
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    ControlButton {
                        icon: "skip_previous"
                        opacity: root.player?.canGoPrevious ? 1 : 0.4
                        onClicked: root.player?.previous()
                    }
                    ControlButton {
                        icon: root.player?.isPlaying ? "pause" : "play_arrow"
                        primary: true
                        onClicked: root.player?.togglePlaying()
                    }
                    ControlButton {
                        icon: "skip_next"
                        opacity: root.player?.canGoNext ? 1 : 0.4
                        onClicked: root.player?.next()
                    }
                }
            }
        }

        // Player list (open from the source button). Auto = follow whatever's playing.
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.picking
            spacing: 2

            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Appearance.colors.border
            }

            ListRow {
                Layout.fillWidth: true
                icon: "auto_mode"
                text: "Auto — follow what's playing"
                highlighted: !Media.pinned
                onClicked: {
                    Media.choose(null);
                    root.picking = false;
                }
            }

            Repeater {
                model: Media.players

                // One player; browsers with the Beam extension get a chevron that opens their tabs' media.
                ColumnLayout {
                    id: playerEntry
                    required property MprisPlayer modelData
                    readonly property var host: BrowserTabs.hostFor(modelData)
                    readonly property var tabs: host?.tabs ?? []
                    property bool open: modelData === root.player

                    Layout.fillWidth: true
                    spacing: 2

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: playerRow.implicitHeight

                        ListRow {
                            id: playerRow
                            anchors.fill: parent
                            icon: playerEntry.modelData.isPlaying ? "play_arrow"
                                : (playerEntry.modelData.trackTitle ? "pause" : "stop")
                            text: playerEntry.modelData.trackTitle
                                ? `${playerEntry.modelData.identity} · ${Media.describe(playerEntry.modelData).title}`
                                : playerEntry.modelData.identity
                            trailing: playerEntry.tabs.length ? ""
                                : playerEntry.modelData === root.player ? (Media.pinned ? "pinned" : "showing") : ""
                            highlighted: Media.pinned && playerEntry.modelData === Media.chosen
                            onClicked: {
                                Media.choose(playerEntry.modelData);
                                root.picking = false;
                            }
                        }

                        // Tabs chevron: "3 tabs ⌄".
                        HoverRect {
                            visible: playerEntry.tabs.length > 0
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            implicitHeight: 30
                            implicitWidth: tabsChip.implicitWidth + 14
                            radius: 10
                            baseColor: playerEntry.open ? Appearance.colors.bg : "transparent"
                            onClicked: playerEntry.open = !playerEntry.open

                            Row {
                                id: tabsChip
                                anchors.centerIn: parent
                                spacing: 2

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: `${playerEntry.tabs.length} tab${playerEntry.tabs.length === 1 ? "" : "s"}`
                                    font.pixelSize: Appearance.font.small
                                    color: Appearance.colors.muted
                                }
                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: playerEntry.open ? "expand_less" : "expand_more"
                                    size: 16
                                    color: Appearance.colors.muted
                                }
                            }
                        }
                    }

                    // The browser's tabs with media. Click = switch to that tab (its other tabs pause, so the
                    // browser's player follows); click the playing one = pause. ↗ = bring the tab to the front.
                    Repeater {
                        model: playerEntry.open ? playerEntry.tabs : []

                        Item {
                            id: tabEntry
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: 26
                            implicitHeight: 36

                            ListRow {
                                anchors.fill: parent
                                implicitHeight: 36
                                icon: tabEntry.modelData.playing ? "graphic_eq" : "pause"
                                text: tabEntry.modelData.title || tabEntry.modelData.pageTitle
                                trailing: tabEntry.modelData.site
                                trailingPad: 26
                                highlighted: tabEntry.modelData.playing
                                onClicked: {
                                    if (tabEntry.modelData.playing) {
                                        BrowserTabs.pause(playerEntry.host.id, tabEntry.modelData.id);
                                    } else {
                                        BrowserTabs.play(playerEntry.host.id, tabEntry.modelData.id);
                                        Media.choose(playerEntry.modelData);
                                    }
                                }
                            }

                            HoverRect {
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 9
                                onClicked: BrowserTabs.show(playerEntry.host.id, tabEntry.modelData.id)

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    icon: "open_in_new"
                                    size: 16
                                    color: Appearance.colors.muted
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
