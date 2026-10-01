pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// MPRIS players. `active` = the one you picked, else whatever is playing, else one with a track loaded.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer chosen: null
    readonly property MprisPlayer active: (chosen && players.includes(chosen)) ? chosen
        : players.find(p => p.isPlaying) ?? players.find(p => p.trackTitle) ?? players[0] ?? null

    // True while a player is picked by hand (not following whatever's playing).
    readonly property bool pinned: chosen !== null && players.includes(chosen)

    // null = Auto (follow whatever's playing).
    function choose(player) {
        chosen = player;
    }

    function cyclePlayer() {
        if (players.length < 2) return;
        chosen = players[(players.indexOf(active) + 1) % players.length];
    }

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // ── Local video files (mpv etc.) ──────────────────────────────────────────
    // Their MPRIS title is just the file name ("S02E07.mp4") and there's no art, so derive
    // "show + episode" from the path and grab a frame from the video as the cover.

    readonly property string thumbDir: `${Quickshell.env("HOME")}/.cache/quickshell-base/media-thumbs`
    readonly property var videoExts: ["mp4", "mkv", "webm", "avi", "mov", "m4v", "ts", "wmv", "flv", "mpg", "mpeg"]
    // Folder names that say nothing about the show, skipped when walking up the path.
    readonly property var genericDir: /^(encoded|season[\s._-]*\d+|s\d+|specials?|extras|videos?|anime|movies?|tv|shows?|series|downloads?|disc[\s._-]*\d+|\d{3,4}p|new drive)$/i

    // Local file path of the player's current track, or "".
    function localPath(player) {
        const url = player?.metadata?.["xesam:url"] ?? "";
        if (!url.startsWith("file://")) return "";
        try { return decodeURIComponent(url.slice(7)); } catch (e) { return url.slice(7); }
    }

    function isVideo(path) {
        return videoExts.includes(path.split(".").pop().toLowerCase());
    }

    function tidy(s) {
        return s.replace(/[._]+/g, " ").replace(/\[[^\]]*\]|\([^)]*\)/g, "").replace(/\s+/g, " ")
            .replace(/^[\s-]+|[\s-]+$/g, "");
    }

    // { title, subtitle } for display. Real tags win; file-name titles get parsed.
    function describe(player) {
        const title = player?.trackTitle ?? "";
        const artist = player?.trackArtist ?? "";
        const path = localPath(player);
        const parts = path.split("/");
        const file = parts.pop() ?? "";
        const stem = file.replace(/\.[^.]+$/, "");
        if (!path || (title && title !== file && title !== stem))
            return { title: title || "Unknown title", subtitle: artist };

        // Episode code: S02E07, 2x07, "Episode 7", "Ep 07".
        let season = "", episode = "", before = stem, after = "";
        const m = stem.match(/s(\d{1,2})[\s._-]*e(\d{1,3})/i) ?? stem.match(/\b(\d{1,2})x(\d{2,3})\b/i)
            ?? stem.match(/()\bep(?:isode)?[\s._-]*(\d{1,4})\b/i);
        if (m) {
            season = m[1] ? String(parseInt(m[1])) : "";
            episode = String(parseInt(m[2]));
            before = tidy(stem.slice(0, m.index));
            after = tidy(stem.slice(m.index + m[0].length));
        }
        if (!season) {
            const sd = parts.map(d => d.match(/^(?:season|s)[\s._-]*(\d+)$/i)).filter(Boolean).pop();
            if (sd) season = String(parseInt(sd[1]));
        }

        // Show: text before the code in the file name, else the nearest meaningful folder.
        let show = m ? before : "";
        if (!show) show = tidy(parts.slice().reverse().find(d => d && !genericDir.test(d.trim())) ?? "");
        if (!m) return { title: tidy(stem) || title, subtitle: show && show !== tidy(stem) ? show : artist };

        const ep = [season && `Season ${season}`, `Episode ${episode}`].filter(Boolean).join(" · ");
        return { title: show || tidy(stem), subtitle: after ? `${ep} — ${after}` : ep };
    }

    readonly property var activeInfo: describe(active)

    // Thumbnail for the active player's local video, "" until it exists.
    property var thumbs: ({})   // md5(path) → true once generated
    readonly property string activeVideo: {
        const p = localPath(active);
        return p && isVideo(p) ? p : "";
    }
    readonly property string activeThumb: activeVideo && thumbs[Qt.md5(activeVideo)]
        ? `file://${thumbDir}/${Qt.md5(activeVideo)}.jpg` : ""

    onActiveVideoChanged: if (activeVideo) makeThumb(activeVideo)

    function makeThumb(path) {
        const h = Qt.md5(path);
        if (thumbs[h]) return;
        thumbProc.running = false;
        thumbProc.hash = h;
        thumbProc.command = ["sh", "-c",
            'mkdir -p "$1" && { [ -s "$1/$2.jpg" ] || ffmpegthumbnailer -i "$3" -o "$1/$2.jpg" -s 448 -t 25% -q 8 2>/dev/null; } && [ -s "$1/$2.jpg" ]',
            "_", thumbDir, h, path];
        thumbProc.running = true;
    }

    Process {
        id: thumbProc
        property string hash
        onExited: code => {
            if (code === 0) root.thumbs = Object.assign({}, root.thumbs, { [hash]: true });
        }
    }

    // MPRIS position isn't pushed; re-read it every second while playing.
    Timer {
        interval: 1000
        repeat: true
        running: root.active?.isPlaying ?? false
        onTriggered: root.active.positionChanged()
    }
}
