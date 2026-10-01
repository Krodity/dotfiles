#!/bin/sh
# snap-windows.sh <dir> [max-age-seconds]
# Screenshots every window on a currently *visible* workspace into <dir>/<address>.jpg (address without 0x),
# printing each address as it lands. Windows whose picture is younger than max-age (default 0 = always)
# are skipped, so frequent triggers don't keep re-capturing and re-loading the same images. Uses grim region capture = whole-output screencopy, NOT per-window
# toplevel export (that path segfaults Hyprland 0.56.2 — see mempalace desktop.md).
# Also deletes previews of windows that no longer exist.
dir=$1
maxage=${2:-0}
now=$(date +%s)
mkdir -p "$dir"
clients=$(hyprctl clients -j) || exit 1
visible=$(hyprctl monitors -j | jq '[.[].activeWorkspace.id]')

printf '%s' "$clients" | jq -r --argjson ws "$visible" '
    .[] | select(.mapped and (.hidden | not) and (.workspace.id as $w | $ws | index($w)))
        | select(.size[0] > 40 and .size[1] > 40)
        | "\(.address | ltrimstr("0x")) \(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
while read -r addr pos size; do
    if [ "$maxage" -gt 0 ] && [ -e "$dir/$addr.jpg" ] &&
        [ $((now - $(stat -c %Y "$dir/$addr.jpg"))) -lt "$maxage" ]; then
        continue
    fi
    timeout 3 grim -t jpeg -q 75 -s 0.5 -g "$pos $size" "$dir/$addr.tmp" </dev/null &&
        mv "$dir/$addr.tmp" "$dir/$addr.jpg" && echo "$addr"
done

live=$(printf '%s' "$clients" | jq -r '.[].address | ltrimstr("0x")')
for f in "$dir"/*.jpg; do
    [ -e "$f" ] || continue
    a=$(basename "$f" .jpg)
    printf '%s\n' "$live" | grep -qx "$a" || rm -f "$f"
done
rm -f "$dir"/*.tmp
