#!/bin/bash
# Render the Mac AppIcon set from the full-bleed Paper Almanac artwork.
set -euo pipefail
cd "$(dirname "$0")/.."
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
art=Design/AppIcon.png
magick "$art" -resize 824x824 \
    \( -size 824x824 xc:black -fill white -draw 'roundrectangle 0,0 823,823 168,168' \) \
    -alpha off -compose CopyOpacity -composite "$stage/tile.png"
# Pad the colored tile in a fresh operation so only the mask uses CopyOpacity.
magick "$stage/tile.png" -background none -gravity center -extent 1024x1024 "$stage/icon.png"
for pixels in 16 32 64 128 256 512 1024; do
    magick "$stage/icon.png" -resize "${pixels}x${pixels}" -depth 8 \
        "PNG32:Mac/Assets.xcassets/AppIcon.appiconset/icon-${pixels}.png"
done
