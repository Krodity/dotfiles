#!/usr/bin/env bash
# Copy these dotfiles into ~/.config. Anything it would overwrite is backed up first
# to ~/.config-backup-<timestamp>/. Not meant for the machine they were synced from.
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.config-backup-$(date +%s)"

cd "$REPO/.config"
find . -type f | while read -r f; do
    target="$HOME/.config/${f#./}"
    if [[ -e "$target" ]]; then
        mkdir -p "$BACKUP/$(dirname "${f#./}")"
        cp -a "$target" "$BACKUP/${f#./}"
    fi
    mkdir -p "$(dirname "$target")"
    cp -a "$f" "$target"
done
chmod +x "$HOME"/.config/quickshell/*/scripts/*.sh "$HOME"/.config/hypr/hyprland/scripts/*.sh 2>/dev/null || true
mkdir -p "$HOME/Pictures/Wallpapers"

[[ -d "$BACKUP" ]] && echo "Backed up replaced files to $BACKUP"
echo "Done. Set your monitors in ~/.config/hypr/custom/general.lua, drop wallpapers in ~/Pictures/Wallpapers, then log into Hyprland."
