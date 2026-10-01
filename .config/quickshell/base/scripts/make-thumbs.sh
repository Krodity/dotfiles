#!/bin/sh
# make-thumbs.sh <thumb-dir> <image>...
# Writes <thumb-dir>/<md5 of image path>.jpg for each image (skips existing ones, 4 at a time)
# and prints each finished hash, so the shell can show thumbnails as they arrive.
dir=$1; shift
mkdir -p "$dir"
printf '%s\0' "$@" | xargs -0 -P4 -I{} sh -c '
    f=$1; dir=$2
    h=$(printf %s "$f" | md5sum | cut -d" " -f1)
    [ -e "$dir/$h.jpg" ] || vipsthumbnail "$f" -s 360x200 --smartcrop attention -o "$dir/$h.jpg[Q=82]" 2>/dev/null
    [ -e "$dir/$h.jpg" ] && echo "$h"
' _ {} "$dir"
