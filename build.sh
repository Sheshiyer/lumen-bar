#!/bin/zsh
# Builds LumenBar, compiles AppIcon.icns, installs to ./dist/LumenBar.app and ~/Applications/LumenBar.app,
# and registers with macOS Launch Services so Dock & Finder display the custom icon immediately.
set -euo pipefail
here=${0:A:h}
name="LumenBar"
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
scratch="$here/.build-app"
config=release
[[ " $* " == *" --debug "* ]] && config=debug

identity="${SIGN_IDENTITY:-}"
if [[ -z "$identity" ]]; then
  identity=$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -o '"Apple Development: [^"]*"' | tr -d '"' || true)
fi
[[ -n "$identity" ]] || identity=-

if ! build_out=$(swift build --disable-sandbox -c $config --package-path "$here" --scratch-path "$scratch" 2>&1); then
  print -r -- "$build_out"
  echo "build failed"
  exit 1
fi
print -r -- "$build_out" | grep -E "error|warning|Build complete" | grep -v "^\[" | grep -v "org.swift.swiftpm" || true
bin=$(find "$scratch" -type f -name "$name" -perm +111 | grep -i "$config" | head -1)
[[ -n "$bin" && -x "$bin" ]] || bin="$scratch/$config/$name"
[[ -x "$bin" ]] || { echo "build failed"; exit 1; }

app="$here/dist/$name.app"
mkdir -p "$here/dist"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/$name"
version=$(tr -d '[:space:]' < "$here/VERSION")
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || { echo "VERSION must be semantic versioning"; exit 1; }
commit=$(git -C "$here" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)
dirty=""
[[ -z "$(git -C "$here" status --porcelain 2>/dev/null)" ]] || dirty="-dirty"
sed -e "s/__VERSION__/$version/" -e "s/__BUILD__/$(date +%Y%m%d%H%M)/" -e "s/__GIT_COMMIT__/${commit}${dirty}/" "$here/Info.plist.in" > "$app/Contents/Info.plist"

if [[ ! -f "$here/Resources/AppIcon.icns" || -n "$(find "$here/tools/render_icon.swift" -newer "$here/Resources/AppIcon.icns" 2>/dev/null | head -1)" ]]; then
  "$here/tools/make_icon.sh"
fi
if [[ -f "$here/Resources/AppIcon.icns" ]]; then
  cp -X "$here/Resources/AppIcon.icns" "$app/Contents/Resources/"
fi
if [[ -f "$here/Resources/Assets.car" ]]; then
  cp -X "$here/Resources/Assets.car" "$app/Contents/Resources/"
fi

xattr -cr "$app" 2>/dev/null || true
# Hardened runtime and a secure timestamp are required for public Developer ID distribution.
# Ad-hoc signatures cannot carry a timestamp, so only real identities request one.
sign_flags=(--force --options runtime)
[[ "$identity" == "-" ]] || sign_flags+=(--timestamp)
if ! sign_out=$(python3 "$here/tools/run-with-timeout.py" --seconds 300 -- codesign "${sign_flags[@]}" --sign "$identity" "$app" 2>&1); then
  print -r -- "$sign_out"
  echo "codesign failed"
  exit 1
fi
print -r -- "$sign_out" | grep -v "replacing existing signature" || true
echo "installed $app (signed: ${identity})"

lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$lsregister" ]]; then
  "$lsregister" -f -R -trusted "$app" 2>/dev/null || true
fi

install_app="$app"
if mkdir -p /Applications 2>/dev/null && [[ -w /Applications ]]; then
  rm -rf "/Applications/$name.app" 2>/dev/null || true
  cp -R "$app" "/Applications/$name.app" 2>/dev/null || true
  install_app="/Applications/$name.app"
elif mkdir -p "$HOME/Applications" 2>/dev/null && [[ -w "$HOME/Applications" ]]; then
  rm -rf "$HOME/Applications/$name.app" 2>/dev/null || true
  cp -R "$app" "$HOME/Applications/$name.app" 2>/dev/null || true
  install_app="$HOME/Applications/$name.app"
fi
if [[ -x "$lsregister" && -d "$install_app" ]]; then
  "$lsregister" -f -R -trusted "$install_app" 2>/dev/null || true
fi

if [[ " $* " == *" --open "* ]]; then
  osascript -e "quit app \"$name\"" 2>/dev/null || true
  sleep 0.5
  open "$install_app"
fi
