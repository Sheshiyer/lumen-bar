#!/bin/zsh
# Generates Resources/AppIcon.icns and Resources/AppIcon-preview.png using CoreGraphics + ImageIO.
set -euo pipefail
here=${0:A:h}
repo=${here:h}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$repo/Resources"

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swiftc "$here/render_icon.swift" -o "$work/render_icon"
"$work/render_icon" "$repo/Resources"
