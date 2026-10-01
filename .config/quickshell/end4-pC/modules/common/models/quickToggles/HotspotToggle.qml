import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

// Toggles the linux-wifi-hotspot system service (create_ap.service).
// It is a *system* unit, so start/stop go through polkit — a rule at
// /etc/polkit-1/rules.d/49-create_ap-hotspot.rules lets user your-user manage just
// this unit without a password prompt.
QuickToggleModel {
    id: root
    name: Translation.tr("Hotspot")
    icon: "wifi_tethering"
    tooltipText: Translation.tr("Wi-Fi hotspot") + (root.ssid ? " (" + root.ssid + ")" : "")

    property string ssid: ""
    property bool busy: false

    statusText: toggled ? (root.ssid || Translation.tr("On")) : Translation.tr("Off")

    mainAction: () => {
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

    Process {
        id: ssidProc
        running: true
        command: ["bash", "-c", "awk -F= '/^SSID=/{print $2; exit}' /etc/create_ap.conf 2>/dev/null"]
        stdout: StdioCollector {
            id: ssidOut
            onStreamFinished: root.ssid = ssidOut.text.trim()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!root.busy) refreshProc.running = true
    }
}
