pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Wallpaper folders + thumbnails. Setting one goes through end4-pC's switchwall.sh,
// which also regenerates the matugen colour scheme (end4-pC still draws the wallpaper).
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // Every source folder (top level only, so .originals/ stays hidden). The list is sorted by path, so
    // each folder's wallpapers stay together.
    readonly property var dirs: [`${home}/Pictures/Wallpapers`]
    readonly property string thumbDir: `${home}/.cache/quickshell-base/thumbs`
    readonly property string configFile: `${home}/.config/illogical-impulse/config.json`
    readonly property string switchwall: `${home}/.config/quickshell/end4-pC/scripts/colors/switchwall.sh`

    // How the wallpaper is fitted to the monitor. Saved in ~/.local/state/quickshell-base/wallpaper.json.
    readonly property string fit: settings.fit
    readonly property var fitModes: [
        { value: "fill", label: "Fill", icon: "crop" },
        { value: "fit", label: "Fit", icon: "fit_screen" },
        { value: "stretch", label: "Stretch", icon: "open_in_full" },
        { value: "center", label: "Center", icon: "center_focus_strong" },
        { value: "tile", label: "Tile", icon: "grid_view" }
    ]

    function setFit(mode) {
        settings.fit = mode;
    }

    property var files: []
    property var ready: ({})   // md5(path) → true once its thumbnail exists
    property string current: ""

    // Same hash make-thumbs.sh uses for the file name.
    function thumbFor(path) {
        const h = Qt.md5(path);
        return ready[h] ? `file://${thumbDir}/${h}.jpg` : "";
    }

    function set(path) {
        current = path;
        Quickshell.execDetached(["env", `ILLOGICAL_IMPULSE_VIRTUAL_ENV=${home}/.local/state/quickshell/.venv`,
            switchwall, "--image", path]);
    }

    function random() {
        const others = files.filter(f => f !== current);
        if (others.length) set(others[Math.floor(Math.random() * others.length)]);
    }

    // Step through `files` (wraps around). The pick shows at once in `current`; switchwall runs once the
    // presses stop, so holding the key doesn't spawn a matugen run per step.
    function step(delta) {
        if (!files.length) return;
        const i = files.indexOf(current);
        current = files[((i < 0 ? (delta > 0 ? -1 : 0) : i) + delta + files.length) % files.length];
        stepApply.restart();
    }

    Timer {
        id: stepApply
        interval: 300
        onTriggered: root.set(root.current)
    }

    // qs -c base ipc call wallpaper next|prev   (SUPER+ALT+Right / SUPER+ALT+Left)
    IpcHandler {
        target: "wallpaper"

        function next(): void {
            root.step(1);
        }
        function prev(): void {
            root.step(-1);
        }
    }

    function rescan() {
        lister.running = true;
    }

    Process {
        id: lister
        running: true
        command: ["find", ...root.dirs, "-maxdepth", "1", "-type", "f", "(",
            "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(Boolean).sort();
                thumbs.running = true;
            }
        }
    }

    Process {
        id: thumbs
        command: [Quickshell.shellPath("scripts/make-thumbs.sh"), root.thumbDir, ...root.files]
        stdout: SplitParser {
            onRead: hash => root.ready = Object.assign({}, root.ready, { [hash]: true })
        }
    }

    // Track the current wallpaper, including changes made elsewhere (end4's own picker).
    FileView {
        path: root.configFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.current = JSON.parse(text()).background?.wallpaperPath ?? "";
            } catch (e) {}
        }
    }

    FileView {
        path: `${root.home}/.local/state/quickshell-base/wallpaper.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: settings
            property string fit: "fill"
        }
    }
}
