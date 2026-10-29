#!/usr/bin/env bash
# Compile the single master icon into platform density assets. Requires ImageMagick.
# The master assets/icon/focubili_icon.png is read-only; every platform slot
# (including night/dark variants) uses the same light artwork.
set -euo pipefail
cd "$(dirname "$0")/.."

MASTER=assets/icon/focubili_icon.png
# Flattened full-bleed square for slots that must be opaque or fill an adaptive mask.
# 130% zoom crops the rounded corners away so no dark background can leak through.
flat_square() {
  local size=$1 out=$2
  convert "$MASTER" -background '#DCE7F7' -alpha remove -alpha off \
    -resize "$((size * 13 / 10))x$((size * 13 / 10))" \
    -gravity center -extent "${size}x${size}" "$out"
}

# Android legacy icons and adaptive foregrounds (day and night share the light art).
for spec in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  IFS=: read -r density legacy foreground <<< "$spec"
  for night in '' night-; do
    dir="android/app/src/main/res/mipmap-${night}${density}"
    mkdir -p "$dir"
    for name in ic_launcher ic_launcher_round; do
      convert "$MASTER" -resize "${legacy}x${legacy}" "$dir/$name.png"
    done
    flat_square "$foreground" "$dir/ic_launcher_foreground.png"
  done
done

# iOS AppIcon slots, including the dark-appearance entry (same light artwork).
ios=ios/Runner/Assets.xcassets/AppIcon.appiconset
for spec in \
  Icon-App-20x20@1x.png:20 Icon-App-20x20@2x.png:40 Icon-App-20x20@3x.png:60 \
  Icon-App-29x29@1x.png:29 Icon-App-29x29@2x.png:58 Icon-App-29x29@3x.png:87 \
  Icon-App-40x40@1x.png:40 Icon-App-40x40@2x.png:80 Icon-App-40x40@3x.png:120 \
  Icon-App-60x60@2x.png:120 Icon-App-60x60@3x.png:180 \
  Icon-App-76x76@1x.png:76 Icon-App-76x76@2x.png:152 \
  Icon-App-83.5x83.5@2x.png:167 \
  Icon-App-1024x1024@1x.png:1024 Icon-App-dark-1024.png:1024; do
  file=${spec%%:*}
  size=${spec##*:}
  flat_square "$size" "$ios/$file"
done

# Traditional macOS icon slots keep the rounded artwork with transparent corners.
for size in 16 32 64 128 256 512 1024; do
  convert "$MASTER" -resize "${size}x${size}" \
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png"
done

# macOS Icon Composer light/dark layers use the same full-bleed artwork.
flat_square 1024 macos/Runner/FocuBiliIcon.icon/Assets/Light.png
cp macos/Runner/FocuBiliIcon.icon/Assets/Light.png macos/Runner/FocuBiliIcon.icon/Assets/Dark.png

# Windows multi-size icon keeps the rounded artwork with transparency.
convert "$MASTER" -define icon:auto-resize=256,128,64,48,32,24,16 \
  windows/runner/resources/app_icon.ico

echo 'Platform icons generated from assets/icon/focubili_icon.png'
