import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// App launcher: a search card over a dimmed screen. Tap Super (or `qs -c base ipc call launcher toggle`).
// Type to filter · ↑/↓ or Tab to pick · Enter launches · Esc / click outside closes.
// Apps first, then files under ~ (services/FileSearch.qml); Shift+Enter on a file opens its folder.
PanelWindow {
    id: root

    property bool open
    signal closeRequested

    // File hits arrive a beat later; the name filter hides leftovers from the previous query meanwhile.
    readonly property string query: search.text.trim().toLowerCase()
    property var results: AppSearch.search(search.text)
        .concat(FileSearch.results.filter(f => f.name.toLowerCase().includes(query)))
    property int current: 0

    function launch(item, inFolder) {
        if (!item) return;
        if (item.kind === "file") FileSearch.open(item, inFolder);
        else AppSearch.launch(item);
        closeRequested();
    }

    function move(by) {
        if (results.length === 0) return;
        current = (current + by + results.length) % results.length;
        list.positionViewAtIndex(current, ListView.Contain);
    }

    onResultsChanged: if (current >= results.length) current = 0
    onOpenChanged: {
        if (open) {
            search.text = "";
            search.forceActiveFocus();
            list.positionViewAtBeginning();
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
    WlrLayershell.namespace: "base-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Stay mapped until the fade-out finishes.
    visible: open || card.opacity > 0

    // Backdrop tinted with the theme background; clicking it closes.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Appearance.colors.bg, 1)
        opacity: root.open ? 0.25 : 0
        Behavior on opacity {
            NumberAnimation { duration: Appearance.anim.normal }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }


    // Sizes are fractions of this monitor: 20% wide; 5% tall with just the search bar,
    // growing with the live results up to 22.5%. Always centred.
    readonly property int barHeight: Math.round(screen.height * 0.05)
    readonly property int maxHeight: Math.round(screen.height * 0.225)
    readonly property bool expanded: search.text.trim().length > 0
    readonly property int pad: Math.max(6, Math.round(barHeight * 0.12))

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.round(root.screen.width * 0.2)
        height: root.expanded
            ? Math.min(root.maxHeight, root.barHeight + (root.results.length > 0 ? list.contentHeight : noMatch.implicitHeight + 12) + root.pad)
            : root.barHeight
        Behavior on height {
            NumberAnimation { duration: Appearance.anim.fast; easing.type: Easing.OutCubic }
        }
        clip: true
        radius: Math.min(Appearance.popup.radius, root.barHeight / 2)
        color: Qt.alpha(Appearance.colors.bg, Appearance.launcher.opacity)
        border.width: 1
        border.color: Appearance.colors.border

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        Behavior on opacity {
            NumberAnimation { duration: Appearance.anim.normal }
        }
        Behavior on scale {
            NumberAnimation { duration: Appearance.anim.normal; easing.type: Easing.OutCubic }
        }

        // Swallow clicks so they don't reach the backdrop.
        MouseArea {
            anchors.fill: parent
        }

        // Search bar — fills the collapsed height.
        Rectangle {
            id: field

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: root.pad
            }
            height: root.barHeight - root.pad * 2
            radius: height / 2
            color: Qt.alpha(Appearance.colors.surface, Appearance.launcher.opacity)
            border.width: search.activeFocus ? 1 : 0
            border.color: Appearance.colors.accent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                MaterialIcon {
                    icon: "search"
                    size: Math.min(22, field.height * 0.55)
                    color: Appearance.colors.accent
                }

                TextField {
                    id: search

                    Layout.fillWidth: true
                    placeholderText: "Search apps and files"
                    color: Appearance.colors.fg
                    placeholderTextColor: Appearance.colors.muted
                    selectionColor: Appearance.colors.accent
                    selectedTextColor: Appearance.colors.accentText
                    font.family: Appearance.font.family
                    font.pixelSize: Math.min(16, Math.max(12, field.height * 0.4))
                    background: null
                    padding: 0

                    onTextChanged: {
                        root.current = 0;
                        FileSearch.search(text);
                    }
                    Keys.onReturnPressed: event => {
                        if (root.expanded) root.launch(root.results[root.current], event.modifiers & Qt.ShiftModifier);
                    }
                    Keys.onEnterPressed: event => {
                        if (root.expanded) root.launch(root.results[root.current], event.modifiers & Qt.ShiftModifier);
                    }
                    Keys.onEscapePressed: root.closeRequested()
                    Keys.onUpPressed: root.move(-1)
                    Keys.onDownPressed: root.move(1)
                    Keys.onTabPressed: root.move(1)
                    Keys.onBacktabPressed: root.move(-1)
                }

                StyledText {
                    visible: root.expanded
                    text: `${root.results.length}`
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                }
            }
        }

        // Live results — rebuilt on every keystroke.
        ListView {
            id: list

            anchors {
                top: field.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: root.pad
                leftMargin: root.pad
                rightMargin: root.pad
                bottomMargin: root.pad
            }
            visible: root.expanded && root.results.length > 0
            clip: true
            spacing: 2
            model: root.expanded ? root.results : []
            currentIndex: root.current
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0

            delegate: Column {
                id: row

                required property var modelData
                required property int index
                readonly property bool selected: index === root.current
                readonly property bool isFile: modelData.kind === "file"
                readonly property bool firstFile: isFile && (index === 0 || root.results[index - 1]?.kind !== "file")

                width: list.width

                StyledText {
                    visible: row.firstFile
                    leftPadding: 10
                    topPadding: row.index > 0 ? 6 : 0
                    bottomPadding: 2
                    text: "Files"
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                }

                HoverRect {
                    width: parent.width
                    implicitHeight: 40
                    radius: 12
                    baseColor: row.selected ? Qt.alpha(Appearance.colors.accent, 0.18) : "transparent"
                    hoverColor: row.selected ? Qt.alpha(Appearance.colors.accent, 0.24) : Qt.alpha(Appearance.colors.surfaceHover, Appearance.launcher.opacity)
                    onHoveredChanged: if (hovered) root.current = row.index
                    onClicked: root.launch(row.modelData)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 10
                        spacing: 10

                        IconImage {
                            implicitSize: 26
                            source: row.isFile ? FileSearch.iconFor(row.modelData) : AppSearch.iconFor(row.modelData)
                            asynchronous: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                elide: Text.ElideRight
                                color: row.selected ? Appearance.colors.accent : Appearance.colors.fg
                                font.bold: row.selected
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: row.isFile
                                text: row.modelData.dir ?? ""
                                elide: Text.ElideMiddle
                                font.pixelSize: Appearance.font.small
                                color: Appearance.colors.muted
                            }
                        }

                        MaterialIcon {
                            visible: row.selected
                            icon: "keyboard_return"
                            size: 16
                            color: Appearance.colors.accent
                        }
                    }
                }
            }
        }

        StyledText {
            id: noMatch

            anchors.top: field.bottom
            anchors.topMargin: root.pad + 6
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.expanded && root.results.length === 0
            text: "No matching apps or files"
            color: Appearance.colors.muted
        }
    }
}
