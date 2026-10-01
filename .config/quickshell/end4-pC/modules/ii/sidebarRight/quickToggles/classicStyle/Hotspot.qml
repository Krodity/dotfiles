import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell.Io
import Quickshell

// Classic-style toggle for the linux-wifi-hotspot system service
// (create_ap.service). Needs the polkit rule that lets your-user manage this unit.
QuickToggleButton {
    id: root
    buttonIcon: "wifi_tethering"
    toggled: false
    property bool busy: false

    onClicked: {
        if (root.busy) return;
        root.busy = true;
        const verb = root.toggled ? "stop" : "start";
        root.toggled = !root.toggled; // optimistic; corrected by refreshProc
        toggleProc.command = ["systemctl", verb, "create_ap.service"];
        toggleProc.running = true;
    }

    Process {
        id: toggleProc
        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send",
                    Translation.tr("Wi-Fi Hotspot"),
                    Translation.tr("Could not toggle the hotspot. Inspect with: systemctl status create_ap"),
                    "-a", "Shell"]);
            }
            refreshProc.running = true;
        }
    }

    Process {
        id: refreshProc
        running: true
        command: ["systemctl", "is-active", "create_ap.service"]
        stdout: StdioCollector {
            id: stateOut
            onStreamFinished: {
                if (!root.busy) root.toggled = (stateOut.text.trim() === "active");
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!root.busy) refreshProc.running = true
    }

    StyledToolTip {
        text: Translation.tr("Wi-Fi Hotspot")
    }
}
