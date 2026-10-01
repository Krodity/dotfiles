import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Drop-down under the left island: one column per workspace, side by side (scrolls sideways),
// each holding that workspace's windows as snapshot cards. Right-click a card → switch to / fullscreen / close;
// drag a card onto another column, or onto a slot in the "Empty workspaces" box that appears beside the
// overview mid-drag, to move that window there.
// Keyboard: ←/→ between workspaces, ↑/↓ within one, Enter opens the selected window, Shift opens its menu
// (↑/↓ + Enter inside it; Shift/Esc closes the menu). Starts on the focused window.
BarPopup {
    id: root

    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.toplevels.values.length > 0)
        .sort((a, b) => a.id - b.id)
    readonly property int columnWidth: 250

    // Context menu state: which window it's for and where it opened (overlay coords).
    property HyprlandToplevel menuTarget: null
    property point menuAt

    property int menuSel: 0   // highlighted menu row (keyboard)

    function openMenu(card, x, y) {
        menuTarget = card.toplevel;
        menuAt = card.mapToItem(menuLayer, x, y);
        menuSel = 0;
    }

    // Menu actions, shared by clicks and Enter.
    function menuSwitch() {
        menuTarget?.wayland?.activate();
        closeRequested();
    }
    function menuFullscreen() {
        const w = menuTarget?.wayland;
        if (!w) return;
        w.activate();
        w.fullscreen = !w.fullscreen;
        closeRequested();
    }
    function menuClose() {
        menuTarget?.wayland?.close();
        menuTarget = null;   // overview stays open; the card disappears
    }
    function runMenu(i) {
        [menuSwitch, menuFullscreen, menuClose][i]();
    }

    // "+" picker: the empty workspaces among 1–10; picking one switches to it, which creates it.
    property bool pickerOpen: false
    property point pickerAt          // overlay coords of the picker's top-right corner
    property int pickerSel: 0
    readonly property var pickerEntries: emptyWorkspaces.filter(e => e.id <= 10)

    function openPicker() {
        menuTarget = null;
        const p = addButton.mapToItem(menuLayer, addButton.width, addButton.height + 6);
        pickerAt = p;
        pickerSel = 0;
        pickerOpen = true;
    }

    // Keyboard selection: column (index into `workspaces`) and row (window within it).
    property int selCol: 0
    property int selRow: 0

    function cardAt(col, row) {
        return wsRepeater.itemAt(col)?.cards.itemAt(row) ?? null;
    }

    function selectedToplevel() {
        return workspaces[selCol]?.toplevels.values[selRow] ?? null;
    }

    function clampSel() {
        if (workspaces.length === 0) return;
        selCol = Math.max(0, Math.min(selCol, workspaces.length - 1));
        selRow = Math.max(0, Math.min(selRow, workspaces[selCol].toplevels.values.length - 1));
    }

    // Start on the focused window, else the first one.
    function selectInitial() {
        selCol = 0;
        selRow = 0;
        workspaces.forEach((w, c) => w.toplevels.values.forEach((t, r) => {
            if (t.activated) {
                selCol = c;
                selRow = r;
            }
        }));
        Qt.callLater(ensureVisible);
    }

    function moveSel(dCol, dRow) {
        if (workspaces.length === 0) return;
        selCol = Math.max(0, Math.min(selCol + dCol, workspaces.length - 1));
        const count = workspaces[selCol].toplevels.values.length;
        selRow = Math.max(0, Math.min(selRow + dRow, count - 1));
        ensureVisible();
    }

    // Scroll the grid so the selected card is fully in view.
    function ensureVisible() {
        const card = cardAt(selCol, selRow);
        if (!card) return;
        const p = card.mapToItem(columns, 0, 0);
        if (p.x < flick.contentX) flick.contentX = Math.max(0, p.x - 8);
        else if (p.x + card.width > flick.contentX + flick.width)
            flick.contentX = Math.min(flick.contentWidth - flick.width, p.x + card.width - flick.width + 8);
        if (p.y < flick.contentY) flick.contentY = Math.max(0, p.y - 8);
        else if (p.y + card.height > flick.contentY + flick.height)
            flick.contentY = Math.min(flick.contentHeight - flick.height, p.y + card.height - flick.height + 8);
    }

    function handleKey(event) {
        const enter = event.key === Qt.Key_Return || event.key === Qt.Key_Enter;
        if (pickerOpen) {
            const n = pickerEntries.length;
            if (event.key === Qt.Key_Up && n) pickerSel = (pickerSel + n - 1) % n;
            else if (event.key === Qt.Key_Down && n) pickerSel = (pickerSel + 1) % n;
            else if (enter && n) switchTo(pickerEntries[pickerSel].id);
            else if (event.key === Qt.Key_Escape) pickerOpen = false;
            return true;   // the picker owns the keyboard while it's open
        }
        if (menuTarget) {
            if (event.key === Qt.Key_Up) menuSel = (menuSel + 2) % 3;
            else if (event.key === Qt.Key_Down) menuSel = (menuSel + 1) % 3;
            else if (enter) runMenu(menuSel);
            else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Shift) menuTarget = null;
            return true;   // the menu owns the keyboard while it's open
        }
        switch (event.key) {
        case Qt.Key_Left: moveSel(-1, 0); return true;
        case Qt.Key_Right: moveSel(1, 0); return true;
        case Qt.Key_Up: moveSel(0, -1); return true;
        case Qt.Key_Down: moveSel(0, 1); return true;
        case Qt.Key_Shift: {
            const card = cardAt(selCol, selRow);
            if (card) openMenu(card, card.width / 2, card.height / 2);
            return true;
        }
        }
        if (enter) {
            selectedToplevel()?.wayland?.activate();
            closeRequested();
            return true;
        }
        return false;   // Esc etc. fall through to BarPopup
    }

    keyHandler: handleKey
    exclusiveKeyboard: false   // Exclusive confines the pointer to this layer in Hyprland → outside clicks never reach OutsideClick
    onWorkspacesChanged: clampSel()

    onOpenChanged: {
        if (open) {
            selectInitial();
        } else {
            menuTarget = null;
            pickerOpen = false;
            dragToplevel = null;
        }
    }

    // Drag-and-drop state. dropId: workspace id under the pointer, -1 = the empty-workspaces box but not a
    // slot (drops go to the lowest empty one), 0 = none.
    property HyprlandToplevel dragToplevel: null
    property point dragPos          // overlay coords
    property int dropId: 0
    property int edgeScroll: 0      // -1 / 0 / 1
    readonly property int newWorkspaceId: emptyWorkspaces[0].id
    // Workspaces with no windows, listed in the side box during a drag. Screen labels mirror the
    // pinning in ~/.config/hypr/custom/rules.lua (1–5 Alienware, 6–9 Samsung, 10 HDP); if 1–10 are all
    // taken, the next free id is offered instead.
    readonly property var emptyWorkspaces: {
        const used = workspaces.map(w => w.id);
        const screenOf = id => id <= 5 ? "Alienware" : id <= 9 ? "Samsung" : id === 10 ? "HDP" : "";
        const list = [];
        for (let id = 1; id <= 10; id++)
            if (!used.includes(id)) list.push({ id, screen: screenOf(id) });
        if (list.length === 0) {
            let id = 11;
            while (used.includes(id)) id++;
            list.push({ id, screen: "" });
        }
        return list;
    }

    // Side box beside the overview while dragging: to the right if it fits, else to the left, else
    // over the overview's right end.
    readonly property real boxX: {
        const w = emptyBox.boxWidth, gap = Appearance.bar.spacing, edge = Appearance.bar.margin;
        const right = margins.left + implicitWidth + gap;
        if (right + w <= screen.width - edge) return right;
        const left = margins.left - gap - w;
        return left >= edge ? left : screen.width - edge - w;
    }

    property EmptyWorkspaceBox emptyBox: EmptyWorkspaceBox {
        screen: root.screen
        open: root.open && root.dragToplevel !== null
        entries: root.emptyWorkspaces
        dropId: root.dropId
        preferredX: root.boxX
    }

    // HyprlandWorkspace.activate() sends the old string dispatch, which the Lua config rejects.
    function switchTo(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${id}" })`);
        closeRequested();
    }

    function startDrag(toplevel) {
        menuTarget = null;
        pickerOpen = false;
        dragToplevel = toplevel;
    }

    function moveDrag(scenePos) {
        dragPos = menuLayer.mapFromItem(null, scenePos.x, scenePos.y);
        const f = menuLayer.mapToItem(flick, dragPos.x, dragPos.y);
        // Only inside the grid's edge strips — past them the pointer may be over the side box.
        edgeScroll = f.x >= 0 && f.x < 48 ? -1 : f.x <= flick.width && f.x > flick.width - 48 ? 1 : 0;
        dropId = dropIdAt(dragPos);
    }

    function dropIdAt(p) {
        // The side box first (it can overlap the overview on a full-width screen). Both windows share the
        // same top edge, so only x needs shifting between their coordinate spaces.
        const slot = emptyBox.slotAt(margins.left + p.x - emptyBox.margins.left, p.y);
        if (slot !== 0) return slot;

        const f = menuLayer.mapToItem(flick, p.x, p.y);
        if (f.x < 0 || f.x > flick.width || f.y < -24 || f.y > flick.height + 24) return 0;
        const hits = item => {
            const q = menuLayer.mapToItem(item, p.x, p.y);
            return q.x >= 0 && q.x <= item.width;
        };
        for (let i = 0; i < wsRepeater.count; i++) {
            const col = wsRepeater.itemAt(i);
            if (col && hits(col)) return col.modelData.id;
        }
        return 0;
    }

    // Moves the window without following it: focus and what's on screen stay put.
    function endDrag() {
        const t = dragToplevel;
        const target = dropId === -1 ? newWorkspaceId : dropId;
        dragToplevel = null;
        dropId = 0;
        edgeScroll = 0;
        if (!t || target <= 0 || target === t.workspace?.id) return;
        const address = `0x${String(t.address).replace(/^0x/, "")}`;
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = "${target}", window = "address:${address}", follow = false })`);
    }

    name: "windows"
    // As wide as the columns need, up to the screen width.
    cardWidth: Math.max(360, Math.min(columns.implicitWidth + Appearance.popup.padding * 2,
        screen.width - Appearance.bar.margin * 2))

    // Header: title + counts on the left, tray icons centred, + and ↻ on the right.
    // z: the tray's hover label hangs below the row, over the grid.
    Item {
        Layout.fillWidth: true
        implicitHeight: 32
        z: 5

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4

            StyledText {
                text: "Windows"
                font.bold: true
                font.pixelSize: 15
            }
            StyledText {
                // Stop short of the centred tray.
                Layout.maximumWidth: Math.max(0, tray.x - x - 8)
                Layout.leftMargin: 4
                text: `${Hyprland.toplevels.values.length} open · ${root.workspaces.length} workspaces`
                font.pixelSize: Appearance.font.small
                color: Appearance.colors.muted
                elide: Text.ElideRight
            }
            Item {
                Layout.fillWidth: true
            }
            HoverRect {
                id: addButton
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                onClicked: root.pickerOpen ? root.pickerOpen = false : root.openPicker()

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: "add"
                    color: root.pickerOpen ? Appearance.colors.accent : Appearance.colors.fg
                }
            }
            HoverRect {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                onClicked: Previews.capture()

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: "refresh"
                }
            }
        }

        TrayStrip {
            id: tray
            anchors.centerIn: parent
            onActivated: root.closeRequested()
        }
    }

    StyledText {
        visible: root.workspaces.length === 0
        Layout.leftMargin: 4
        text: "No windows open"
        color: Appearance.colors.muted
    }

    Flickable {
        id: flick

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(columns.implicitHeight, root.screen.height * 0.7)
        contentWidth: columns.implicitWidth
        contentHeight: columns.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // Mouse drags move windows between workspaces, so the view scrolls by wheel only
        // (vertical wheel scrolls sideways unless the columns overflow vertically; Shift forces sideways).
        interactive: false

        function scrollBy(dx, dy) {
            contentX = Math.max(0, Math.min(contentWidth - width, contentX + dx));
            contentY = Math.max(0, Math.min(contentHeight - height, contentY + dy));
        }

        WheelHandler {
            onWheel: event => {
                const d = -(event.angleDelta.y || event.angleDelta.x) / 2;
                const sideways = event.angleDelta.x !== 0 || (event.modifiers & Qt.ShiftModifier) || flick.contentHeight <= flick.height;
                if (sideways) flick.scrollBy(d, 0);
                else flick.scrollBy(0, d);
            }
        }

        Row {
            id: columns
            spacing: 4

            Repeater {
                id: wsRepeater
                model: root.workspaces

                // Whole column is a drop target; lights up while a window is dragged over it.
                Rectangle {
                    id: section

                    required property HyprlandWorkspace modelData
                    required property int index
                    property alias cards: cardRepeater
                    readonly property bool dropHere: root.dragToplevel !== null && root.dropId === modelData.id

                    width: root.columnWidth + 12
                    implicitHeight: inner.implicitHeight + 12
                    radius: 18
                    color: dropHere ? Qt.alpha(Appearance.colors.accent, 0.12) : "transparent"
                    border.width: dropHere ? 2 : 0
                    border.color: Appearance.colors.accent

                    Column {
                        id: inner

                        x: 6
                        y: 6
                        width: root.columnWidth
                        spacing: 8

                        // Header: click to switch to this workspace.
                        HoverRect {
                            width: parent.width
                            implicitHeight: 30
                            radius: 15
                            onClicked: root.switchTo(section.modelData.id)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 3
                                anchors.rightMargin: 8
                                spacing: 8

                                Rectangle {
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    radius: 12
                                    color: section.modelData.active ? Appearance.colors.accent : Appearance.colors.surface

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: section.modelData.name
                                        font.bold: true
                                        font.pixelSize: Appearance.font.small
                                        color: section.modelData.active ? Appearance.colors.accentText : Appearance.colors.fg
                                    }
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: [section.modelData.monitor?.name, section.modelData.active ? "on screen" : ""].filter(Boolean).join(" · ")
                                    font.pixelSize: Appearance.font.small
                                    color: Appearance.colors.muted
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Repeater {
                            id: cardRepeater
                            model: [...section.modelData.toplevels.values]

                            WindowCard {
                                required property HyprlandToplevel modelData
                                required property int index

                                toplevel: modelData
                                selected: root.selCol === section.index && root.selRow === index
                                width: root.columnWidth
                                opacity: root.dragToplevel === modelData ? 0.35 : 1
                                onActivated: root.closeRequested()
                                onMenuRequested: (x, y) => root.openMenu(this, x, y)
                                onDragStarted: root.startDrag(modelData)
                                onDragMoved: pos => root.moveDrag(pos)
                                onDropped: root.endDrag()
                            }
                        }
                    }
                }
            }
        }
    }

    // Nudges the grid sideways while a dragged window is held near its left/right edge.
    Timer {
        interval: 16
        repeat: true
        running: root.dragToplevel !== null && root.edgeScroll !== 0
        onTriggered: flick.scrollBy(root.edgeScroll * 12, 0)
    }

    overlayData: Item {
        id: menuLayer
        anchors.fill: parent

        // Any click outside the menu / picker just dismisses it.
        MouseArea {
            anchors.fill: parent
            visible: root.menuTarget !== null || root.pickerOpen
            acceptedButtons: Qt.AllButtons
            onPressed: {
                root.menuTarget = null;
                root.pickerOpen = false;
            }
        }

        // "+" picker: empty workspaces 1–10, hanging below the + button.
        Rectangle {
            visible: root.pickerOpen
            x: Math.max(6, Math.min(root.pickerAt.x - width, parent.width - width - 6))
            y: Math.max(6, Math.min(root.pickerAt.y, parent.height - height - 6))
            width: 220
            implicitHeight: pickerItems.implicitHeight + 12
            radius: 14
            color: Appearance.colors.bg
            border.width: 1
            border.color: Appearance.colors.border

            ColumnLayout {
                id: pickerItems

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 6
                }
                spacing: 2

                StyledText {
                    Layout.leftMargin: 8
                    Layout.topMargin: 4
                    Layout.bottomMargin: 2
                    text: "New workspace"
                    font.bold: true
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                }
                StyledText {
                    visible: root.pickerEntries.length === 0
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 6
                    text: "Workspaces 1–10 are all in use"
                    color: Appearance.colors.muted
                }
                Repeater {
                    model: root.pickerEntries

                    ListRow {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 34
                        icon: "add_circle"
                        text: `Workspace ${modelData.id}`
                        trailing: modelData.screen
                        highlighted: root.pickerSel === index
                        onHoveredChanged: if (hovered) root.pickerSel = index
                        onClicked: root.switchTo(modelData.id)
                    }
                }
            }
        }

        // Follows the pointer while dragging a window.
        Rectangle {
            visible: root.dragToplevel !== null
            x: root.dragPos.x - 24
            y: root.dragPos.y - height / 2
            width: 190
            height: 40
            radius: 12
            color: Appearance.colors.bg
            border.width: 1
            border.color: Appearance.colors.accent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                IconImage {
                    implicitSize: 20
                    source: root.dragToplevel ? Apps.iconFor(root.dragToplevel) : ""
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.dragToplevel?.title || Apps.appId(root.dragToplevel)
                    font.pixelSize: Appearance.font.small
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            id: menu

            readonly property var wayland: root.menuTarget?.wayland ?? null

            visible: root.menuTarget !== null
            x: Math.max(6, Math.min(root.menuAt.x, parent.width - width - 6))
            y: Math.max(6, Math.min(root.menuAt.y, parent.height - height - 6))
            width: 190
            implicitHeight: items.implicitHeight + 12
            radius: 14
            color: Appearance.colors.bg
            border.width: 1
            border.color: Appearance.colors.border

            ColumnLayout {
                id: items

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 6
                }
                spacing: 2

                ListRow {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    icon: "open_in_new"
                    text: "Switch to"
                    highlighted: root.menuSel === 0
                    onHoveredChanged: if (hovered) root.menuSel = 0
                    onClicked: root.menuSwitch()
                }
                ListRow {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    icon: menu.wayland?.fullscreen ? "fullscreen_exit" : "fullscreen"
                    text: menu.wayland?.fullscreen ? "Exit fullscreen" : "Fullscreen"
                    highlighted: root.menuSel === 1
                    onHoveredChanged: if (hovered) root.menuSel = 1
                    onClicked: root.menuFullscreen()
                }
                ListRow {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    icon: "close"
                    text: "Close"
                    highlighted: root.menuSel === 2
                    onHoveredChanged: if (hovered) root.menuSel = 2
                    onClicked: root.menuClose()
                }
            }
        }
    }
}
