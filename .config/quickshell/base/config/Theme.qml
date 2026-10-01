pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The live colour palette. Appearance.colors reads from here; the theme picker writes here.
// Saved to ~/.local/state/quickshell-base/theme.json (outside the config dir, so saving doesn't hot-reload).
Singleton {
    id: root

    readonly property JsonAdapter current: adapter
    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/quickshell-base`

    // Editable colour roles, in picker order. Colours are "#RRGGBB" or "#AARRGGBB" strings.
    readonly property var roles: [
        { key: "accent", label: "Accent" },
        { key: "accentText", label: "Text on accent" },
        { key: "bg", label: "Background" },
        { key: "surface", label: "Surface" },
        { key: "surfaceHover", label: "Surface hover" },
        { key: "fg", label: "Text" },
        { key: "muted", label: "Muted text" },
        { key: "border", label: "Border" }
    ]

    readonly property var presets: [
        { name: "Catppuccin Mocha", bg: "#e61e1e2e", border: "#26ffffff", surface: "#313244", surfaceHover: "#45475a", fg: "#cdd6f4", muted: "#9399b2", accent: "#89b4fa", accentText: "#11111b" },
        { name: "Catppuccin Latte", bg: "#f0eff1f5", border: "#1a000000", surface: "#dce0e8", surfaceHover: "#ccd0da", fg: "#4c4f69", muted: "#7c7f93", accent: "#1e66f5", accentText: "#eff1f5" },
        { name: "Nord", bg: "#e62e3440", border: "#26ffffff", surface: "#3b4252", surfaceHover: "#434c5e", fg: "#eceff4", muted: "#9aa5b8", accent: "#88c0d0", accentText: "#2e3440" },
        { name: "Gruvbox", bg: "#e6282828", border: "#26ffffff", surface: "#3c3836", surfaceHover: "#504945", fg: "#ebdbb2", muted: "#a89984", accent: "#fabd2f", accentText: "#282828" },
        { name: "Rosé Pine", bg: "#e6191724", border: "#26ffffff", surface: "#26233a", surfaceHover: "#403d52", fg: "#e0def4", muted: "#908caa", accent: "#ebbcba", accentText: "#191724" },
        { name: "Tokyo Night", bg: "#e61a1b26", border: "#26ffffff", surface: "#24283b", surfaceHover: "#414868", fg: "#c0caf5", muted: "#9aa5ce", accent: "#7aa2f7", accentText: "#1a1b26" },
        { name: "Dracula", bg: "#e6282a36", border: "#26ffffff", surface: "#44475a", surfaceHover: "#565a70", fg: "#f8f8f2", muted: "#a4a8c4", accent: "#bd93f9", accentText: "#282a36" },
        { name: "Everforest", bg: "#e62d353b", border: "#26ffffff", surface: "#3d484d", surfaceHover: "#475258", fg: "#d3c6aa", muted: "#9da9a0", accent: "#a7c080", accentText: "#2d353b" }
    ]

    // Terminal colours 0–15 per preset (each theme's own published terminal palette). Used by kitty via syncKitty.
    readonly property var ansiPalettes: ({
        "Catppuccin Mocha": ["#45475a", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#bac2de", "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8"],
        "Catppuccin Latte": ["#5c5f77", "#d20f39", "#40a02b", "#df8e1d", "#1e66f5", "#ea76cb", "#179299", "#acb0be", "#6c6f85", "#d20f39", "#40a02b", "#df8e1d", "#1e66f5", "#ea76cb", "#179299", "#bcc0cc"],
        "Nord": ["#3b4252", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#88c0d0", "#e5e9f0", "#4c566a", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#8fbcbb", "#eceff4"],
        "Gruvbox": ["#282828", "#cc241d", "#98971a", "#d79921", "#458588", "#b16286", "#689d6a", "#a89984", "#928374", "#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#d3869b", "#8ec07c", "#ebdbb2"],
        "Rosé Pine": ["#26233a", "#eb6f92", "#31748f", "#f6c177", "#9ccfd8", "#c4a7e7", "#ebbcba", "#e0def4", "#6e6a86", "#eb6f92", "#31748f", "#f6c177", "#9ccfd8", "#c4a7e7", "#ebbcba", "#e0def4"],
        "Tokyo Night": ["#15161e", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#a9b1d6", "#414868", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#c0caf5"],
        "Dracula": ["#21222c", "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd", "#f8f8f2", "#6272a4", "#ff6e6e", "#69ff94", "#ffffa5", "#d6acff", "#ff92df", "#a4ffff", "#ffffff"],
        "Everforest": ["#343f44", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#859289", "#868d80", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#9da9a0"]
    })

    // end4's matugen terminal palette (color0–15 from its generated kitty-theme.conf), for "From wallpaper".
    readonly property var wallpaperAnsi: {
        const out = [];
        for (const line of (wallKitty.text() || "").split("\n")) {
            const m = line.match(/^color(\d+)\s+(#[0-9a-fA-F]{6})/);
            if (m && +m[1] < 16) out[+m[1]] = m[2];
        }
        return out.filter(c => c).length === 16 ? out : [];
    }

    // Material colours end4-pC/matugen generates from the current wallpaper, mapped onto our roles.
    // Selecting it keeps following the wallpaper until you pick something else.
    readonly property var wallpaperPreset: {
        let m = {};
        try {
            m = JSON.parse(wallColors.text() || "{}");
        } catch (e) {}
        if (!m.primary) return null;
        return {
            name: "From wallpaper",
            bg: `#e6${m.background.slice(1)}`,
            border: `#40${(m.outline_variant ?? "#ffffff").slice(1)}`,
            surface: m.surface_container_high,
            surfaceHover: m.surface_container_highest,
            fg: m.on_surface,
            muted: m.on_surface_variant,
            accent: m.primary,
            accentText: m.on_primary,
            ansi: root.wallpaperAnsi
        };
    }

    // Dark mode tile (services/DarkMode.qml sets this). When the palette's own brightness disagrees with it, the
    // colours are flipped: background ↔ text, surfaces/muted re-mixed between them, border inverted. The saved
    // palette (current / theme.json) is never touched, so the picker still edits the original.
    property bool dark: true
    readonly property bool flipped: Qt.color(adapter.bg).hslLightness > 0.5 === dark

    function mix(a, b, t) {
        const x = Qt.color(a), y = Qt.color(b);
        return Qt.rgba(x.r + (y.r - x.r) * t, x.g + (y.g - x.g) * t, x.b + (y.b - x.b) * t, 1);
    }

    readonly property var colors: {
        const c = adapter;
        if (!flipped) return { bg: c.bg, border: c.border, surface: c.surface, surfaceHover: c.surfaceHover,
                               fg: c.fg, muted: c.muted, accent: c.accent, accentText: c.accentText };
        const bg = Qt.color(c.bg), fg = Qt.color(c.fg), br = Qt.color(c.border);
        const newBg = Qt.rgba(fg.r, fg.g, fg.b, bg.a), newFg = Qt.rgba(bg.r, bg.g, bg.b, 1);
        return {
            bg: newBg,
            fg: newFg,
            surface: mix(newBg, newFg, 0.12),
            surfaceHover: mix(newBg, newFg, 0.22),
            muted: mix(newFg, newBg, 0.35),
            border: Qt.rgba(1 - br.r, 1 - br.g, 1 - br.b, br.a),
            accent: c.accent,
            accentText: c.accentText
        };
    }
    onColorsChanged: Qt.callLater(root.syncKitty) // kitty follows the flip too

    function applyPreset(p) {
        if (!p) return;
        for (const r of roles) adapter[r.key] = p[r.key];
        adapter.ansi = p.ansi ?? ansiPalettes[p.name] ?? [];
        adapter.preset = p.name;
    }

    function setRole(key, value) {
        adapter[key] = value;
        adapter.preset = "Custom";
    }

    // Colour → "#RRGGBB", or "#AARRGGBB" when translucent.
    function hex(c) {
        return String(Qt.color(c));
    }

    FileView {
        id: themeFile
        path: `${root.stateDir}/theme.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: saveDelay.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property string preset: "Catppuccin Mocha"
            property string bg: "#e61e1e2e"
            property string border: "#26ffffff"
            property string surface: "#313244"
            property string surfaceHover: "#45475a"
            property string fg: "#cdd6f4"
            property string muted: "#9399b2"
            property string accent: "#89b4fa"
            property string accentText: "#11111b"
            property var ansi: [] // terminal colours 0–15; empty = leave the wallpaper palette
        }
    }

    // Dragging a colour fires many updates; write once it settles.
    Timer {
        id: saveDelay
        interval: 300
        onTriggered: {
            themeFile.writeAdapter();
            root.syncKitty();
        }
    }

    // Kitty follows the theme. Two layers, both needed:
    //  - kitty.conf in our state dir, included by ~/.config/kitty/kitty.conf after end4's palette (new windows,
    //    tab bar / borders), reloaded live with SIGUSR1;
    //  - OSC escape codes in sequences.txt. fish cats end4's sequences.txt on startup, and colours set by escape
    //    codes beat kitty.conf and survive a reload, so fish cats ours right after, and we push ours to every
    //    open terminal on a theme change.
    property string kittyText: ""

    function kittyHex(c) {
        const s = hex(c);
        return s.length === 9 ? `#${s.slice(3)}` : s; // kitty has no alpha
    }

    // Named presets always use their own palette and "From wallpaper" end4's live one. "Custom" keeps the palette
    // of the preset it was edited from (stored in theme.json); an old theme.json without one falls back to the
    // preset with the same background.
    function currentAnsi() {
        if (ansiPalettes[adapter.preset]) return ansiPalettes[adapter.preset];
        if (adapter.preset === "From wallpaper") return wallpaperAnsi;
        if (adapter.ansi?.length === 16) return adapter.ansi;
        const twin = presets.find(p => p.bg.toLowerCase() === String(adapter.bg).toLowerCase());
        return twin ? ansiPalettes[twin.name] : [];
    }

    function syncKitty() {
        const c = root.colors;
        const a = kittyHex(c.accent), at = kittyHex(c.accentText);
        const bg = kittyHex(c.bg), fg = kittyHex(c.fg);
        let ansi = root.currentAnsi();
        // Flipped: swap black↔white (0↔7, 8↔15) so plain/bright text stays readable on the new background.
        if (root.flipped && ansi.length === 16)
            ansi = ansi.map((x, i) => ansi[[7, 1, 2, 3, 4, 5, 6, 0, 15, 9, 10, 11, 12, 13, 14, 8][i]]);
        const text = `# Generated by quickshell base (config/Theme.qml) — preset: ${adapter.preset}
background              ${bg}
foreground              ${fg}
cursor                  ${a}
cursor_text_color       ${at}
selection_background    ${a}
selection_foreground    ${at}
url_color               ${a}
mark1_background        ${a}
active_border_color     ${a}
inactive_border_color   ${kittyHex(c.surfaceHover)}
bell_border_color       ${a}
active_tab_background   ${a}
active_tab_foreground   ${at}
inactive_tab_background ${kittyHex(c.surface)}
inactive_tab_foreground ${kittyHex(c.muted)}
tab_bar_background      ${bg}
${ansi.map((c, i) => `color${i} ${kittyHex(c)}`).join("\n")}
`;
        if (text === kittyText) return;
        kittyText = text;
        const osc = (n, c) => `\x1b]${n};${c}\x1b\\`;
        const seq = osc(10, fg) + osc(11, bg) + osc(12, a) + osc(17, a) + osc(19, at)
            + ansi.map((c, i) => osc(4, `${i};${kittyHex(c)}`)).join("");
        kittyFile.setText(text);
        seqFile.setText(seq);
        kittyReload.command = ["sh", "-c",
            'pkill -USR1 -x kitty; for f in /dev/pts/[0-9]*; do [ -w "$f" ] && printf %s "$1" > "$f" & done; wait',
            "sh", seq];
        kittyReload.running = true;
    }

    FileView {
        id: kittyFile
        path: `${root.stateDir}/kitty.conf`
        preload: false
    }

    FileView {
        id: seqFile
        path: `${root.stateDir}/sequences.txt`
        preload: false
    }

    Process {
        id: kittyReload
    }

    Connections {
        target: themeFile
        function onLoaded() { root.syncKitty(); }
    }

    FileView {
        id: wallColors
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/user/generated/colors.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: if (adapter.preset === "From wallpaper") root.applyPreset(root.wallpaperPreset)
    }

    FileView {
        id: wallKitty
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: if (adapter.preset === "From wallpaper") root.applyPreset(root.wallpaperPreset)
    }
}
