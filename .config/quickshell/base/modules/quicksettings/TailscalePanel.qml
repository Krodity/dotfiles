import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Tailscale detail: Allow-LAN switch + exit node picker (None / Auto / own machines / Mullvad by city).
// Picking a city uses its highest-priority online server; searching a server name lists servers directly.
ColumnLayout {
    id: root

    readonly property string query: search.text.trim().toLowerCase()
    readonly property var activeNode: Tailscale.exitNode

    // Rows: { kind: "none"|"auto"|"own"|"city"|"server", data, icon, text, trailing, active, dim }
    readonly property var rows: {
        const q = query;
        const match = s => s.toLowerCase().includes(q);
        const out = [];
        if (!q) {
            out.push({ kind: "none", icon: "block", text: "No exit node", trailing: "", active: !Tailscale.exitNodeId && !Tailscale.autoExitNode });
            out.push({ kind: "auto", icon: "auto_awesome", text: "Auto (best available)", trailing: "", active: Tailscale.autoExitNode });
        }
        for (const n of Tailscale.ownNodes) {
            if (q && !match(n.name)) continue;
            out.push({ kind: "own", data: n, icon: "computer", text: n.name, trailing: n.online ? "" : "Offline",
                active: !Tailscale.autoExitNode && n.id === Tailscale.exitNodeId, dim: !n.online });
        }
        for (const c of Tailscale.cities) {
            const here = c.nodes.some(n => n.id === Tailscale.exitNodeId);
            if (!q || match(c.city) || match(c.country) || c.code.toLowerCase() === q) {
                const online = c.nodes.filter(n => n.online).length;
                out.push({ kind: "city", data: c, icon: "public", text: `${c.city}, ${c.country}`,
                    trailing: here ? Tailscale.exitNode.name : `${c.code} · ${online}`,
                    active: !Tailscale.autoExitNode && here, dim: online === 0 });
                continue;
            }
            for (const n of c.nodes) {
                if (!match(n.name)) continue;
                out.push({ kind: "server", data: n, icon: "dns", text: n.name, trailing: n.online ? c.code : "Offline",
                    active: !Tailscale.autoExitNode && n.id === Tailscale.exitNodeId, dim: !n.online });
            }
        }
        return out;
    }

    property int listHeight: 240

    spacing: 6

    StyledText {
        visible: !Tailscale.available || Tailscale.backendState === "NeedsLogin"
        Layout.leftMargin: 6
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: !Tailscale.available ? "tailscaled isn't responding" : "Logged out — run `tailscale login`"
        color: Appearance.colors.muted
    }

    StyledText {
        visible: Tailscale.error !== ""
        Layout.leftMargin: 6
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: Tailscale.error
        color: Appearance.colors.accent
        font.pixelSize: Appearance.font.small
    }

    ListRow {
        Layout.fillWidth: true
        icon: "lan"
        text: "Allow LAN access"
        trailing: Tailscale.allowLan ? "On" : "Off"
        highlighted: Tailscale.allowLan
        onClicked: Tailscale.setAllowLan(!Tailscale.allowLan)
    }

    TextField {
        id: search
        Layout.fillWidth: true
        placeholderText: "Search exit nodes — city, country, server"
        color: Appearance.colors.fg
        placeholderTextColor: Appearance.colors.muted
        font.pixelSize: Appearance.font.size
        leftPadding: 12
        background: Rectangle {
            radius: 12
            color: Appearance.colors.surface
            border.width: search.activeFocus ? 1 : 0
            border.color: Appearance.colors.accent
        }
        // First Esc clears the search; with it empty, Esc falls through and closes the popup.
        Keys.onEscapePressed: event => {
            if (text) text = "";
            else event.accepted = false;
        }
        onVisibleChanged: if (!visible) text = ""
    }

    StyledText {
        visible: root.rows.length === 0
        Layout.leftMargin: 6
        text: Tailscale.cities.length === 0 && Tailscale.ownNodes.length === 0 ? "No exit nodes available" : "No matches"
        color: Appearance.colors.muted
    }

    ListView {
        id: list
        visible: root.rows.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, root.listHeight)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.rows

        delegate: ListRow {
            required property var modelData

            width: list.width
            icon: modelData.icon
            text: modelData.text
            trailing: modelData.active && modelData.kind !== "city" ? "Active" : modelData.trailing
            highlighted: modelData.active
            opacity: modelData.dim ? 0.5 : 1
            onClicked: {
                if (Tailscale.busy) return;
                if (modelData.kind === "none") Tailscale.useExitNode(null);
                else if (modelData.kind === "auto") Tailscale.useExitNode("auto");
                else if (modelData.active) Tailscale.useExitNode(null); // click the active one to turn it off
                else Tailscale.useExitNode(modelData.data);
            }
        }
    }
}
