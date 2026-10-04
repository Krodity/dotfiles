#!/usr/bin/env bash
# Re-copy the live desktop config into this repo and scrub machine-specific bits.
# Run from anywhere: ~/Dotfiles/sync.sh   (then review `git diff` before committing)
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SRC="$HOME/.config"
DST="$REPO/.config"

EXCLUDES=(--exclude='*.bak*' --exclude='*.disabled*' --exclude='.git/' --exclude='__pycache__/'
          --exclude='.qmlls.ini' --exclude='.dms-backups/')

copy() {  # copy <path relative to ~/.config> [extra rsync args...]
    local p="$1"; shift
    mkdir -p "$(dirname "$DST/$p")"
    if [[ -d "$SRC/$p" ]]; then
        rsync -a --delete "${EXCLUDES[@]}" "$@" "$SRC/$p/" "$DST/$p/"
    else
        rsync -a "$SRC/$p" "$DST/$p"
    fi
}

# ── Hyprland (Lua config) ────────────────────────────────────────────────────
copy hypr/hyprland.lua
copy hypr/hyprland --exclude='scripts/ai/'
copy hypr/hyprlock
copy hypr/hyprlock.conf
copy hypr/hypridle.conf
mkdir -p "$DST/hypr/custom"
# custom/ is mostly machine-specific (monitor layout, app launchers, personal scripts);
# only the look-and-feel parts are kept, as hand-curated templates under templates/.
cp "$REPO/templates/hypr/custom/"*.lua "$DST/hypr/custom/"

# ── Shells: Quickshell `base` (live bar/launcher/overview) + end4-pC (wallpaper → colours) ──
copy quickshell/base
copy quickshell/end4-pC --exclude='screenshots/'
copy illogical-impulse/config.json

# ── Terminal, prompt, theming ────────────────────────────────────────────────
copy kitty
copy fish/config.fish
copy fish/auto-Hypr.fish
copy starship.toml
copy fastfetch
copy matugen
copy fuzzel
copy gtk-3.0/gtk.css
copy gtk-4.0/gtk.css
copy Kvantum
copy kdeglobals
copy darklyrc
copy fontconfig
copy btop/btop.conf
copy btop/themes/current.theme
copy cava

# fastfetch logo lived in omarchy's branding dir — vendor it next to the config
cp "$SRC/omarchy/branding/about.txt" "$DST/fastfetch/logo.txt"

# ── Scrub ────────────────────────────────────────────────────────────────────
cd "$DST"

# Absolute home paths → ~ / $HOME
grep -rlIZ "$HOME" . | xargs -0 -r sed -i "s|$HOME|~|g"

# Username in comments → generic
grep -rlIZw "$USER" . | xargs -0 -r sed -i "s/\\b$USER\\b/your-user/g"

# fastfetch logo
sed -i 's|~/.config/omarchy/branding/about.txt|~/.config/fastfetch/logo.txt|' fastfetch/config.jsonc

# Autostart the base shell instead of end4-pC (end4-pC still runs headless-ish for colours via switchwall)
sed -i 's|hl.env("qsConfig", "end4-pC")|hl.env("qsConfig", "base")|' hypr/hyprland/variables.lua

# Wallpapers: personal second folder → just ~/Pictures/Wallpapers
sed -i 's|, `${home}/Pictures/wallhaven-toplist`||' quickshell/base/services/Wallpapers.qml

# hyprlock background → whatever wallpaper matugen last applied
sed -i 's|^\$background_image = .*|$background_image = ~/Pictures/Wallpapers/wallpaper.png|' hypr/hyprlock/colors.conf

# end4-pC: personal "second brain" button → plain command on PATH (off by default below)
sed -i 's|"~/bin/second-brain"|"second-brain"|' quickshell/end4-pC/modules/ii/bar/UtilButtons.qml

# Beam is a separate personal project — drop the local path from the comment
sed -i 's| (~/Projects/beam)||' quickshell/base/scripts/browser-tabs.py

# Upstream end4-pC hardcodes an OpenWeather key; don't republish it. Hotspot SSID comment → generic.
sed -i 's|let apiKey = "[0-9a-f]\{32\}"|let apiKey = ""|' quickshell/end4-pC/services/Weather.qml
sed -i 's|, SSID KRDTY||' quickshell/end4-pC/modules/common/models/quickToggles/HotspotToggle.qml

# illogical-impulse config: drop personal file paths + location
python3 - illogical-impulse/config.json <<'PY'
import json, sys
p = sys.argv[1]
c = json.load(open(p))
def walk(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if isinstance(v, str) and (v.startswith("~/") or v.startswith("/")):
                o[k] = ""
            elif k == "city":
                o[k] = ""
            elif k == "showSecondBrain":
                o[k] = False
            else:
                walk(v)
    elif isinstance(o, list):
        for x in o: walk(x)
walk(c)
json.dump(c, open(p, "w"), indent=2)
open(p, "a").write("\n")
PY

# ── Personal palette stays frozen ────────────────────────────────────────────
# matugen regenerates these from whatever wallpaper is set. A palette swap is personal
# taste, not something to publish, so the repo keeps its committed copies. To publish a
# deliberate change to one of them, commit it by hand.
FROZEN=(hypr/hyprland/colors.lua hypr/hyprlock/colors.conf fuzzel/fuzzel_theme.ini
        gtk-3.0/gtk.css gtk-4.0/gtk.css)
for f in "${FROZEN[@]}"; do
    git -C "$REPO" ls-files --error-unmatch ".config/$f" >/dev/null 2>&1 \
        && git -C "$REPO" checkout HEAD -- ".config/$f"
done

# ── Safety net: fail loudly if anything personal survived ────────────────────
LEAKS="$USER|"'100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+|192\.168\.|\.ts\.net|gh[opsu]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|@gmail\.com|krodity|KRDTY|\b[0-9a-f]{32}\b|~/bin/|~/Projects/'
if grep -rnIE "$LEAKS" . ; then
    echo "!! possible personal data above — fix the scrub rules before committing" >&2
    exit 1
fi
echo "synced → $DST"
