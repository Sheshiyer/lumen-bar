#!/bin/zsh
# Builds a release .app and packs a downloadable zip and a drag-to-Applications disk image.
#   tools/package.sh                 signed with the Developer ID when one exists
#   tools/package.sh --notarize      also notarizes and staples the app and the disk image
#                                    (needs APPLE_API_KEY, APPLE_API_KEY_ID, APPLE_API_ISSUER)
# Output: dist/LumenBar-<version>.zip, dist/LumenBar-<version>.dmg, dist/SHA256SUMS
set -euo pipefail
here=${0:A:h:h}
name="LumenBar"
cd "$here"

notarize=false
[[ " $* " == *" --notarize "* ]] && notarize=true

developer_id=$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -o '"Developer ID Application: [^"]*"' | tr -d '"' || true)
if [[ -n "$developer_id" ]]; then
  export SIGN_IDENTITY="$developer_id"
elif $notarize; then
  echo "notarization needs a Developer ID Application certificate"
  exit 1
fi

if $notarize; then
  : "${APPLE_API_KEY:?set APPLE_API_KEY}" "${APPLE_API_KEY_ID:?set APPLE_API_KEY_ID}" "${APPLE_API_ISSUER:?set APPLE_API_ISSUER}"
fi

# The key path is passed to notarytool; its contents are never printed.
notarize_file() {
  python3 "$here/tools/run-with-timeout.py" --seconds 1800 -- xcrun notarytool submit "$1" \
    --key "$APPLE_API_KEY" --key-id "$APPLE_API_KEY_ID" --issuer "$APPLE_API_ISSUER" --wait
}

./build.sh
app="dist/$name.app"
[[ -d "$app" ]] || { echo "build produced no app"; exit 1; }

version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
bundle="LumenBar-$version"

if $notarize; then
  ditto -c -k --keepParent --norsrc --noextattr "$app" "dist/$bundle-notarize.zip"
  notarize_file "dist/$bundle-notarize.zip"
  rm -f "dist/$bundle-notarize.zip"
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
fi

rm -f "dist/$bundle.zip" "dist/$bundle.dmg"
ditto -c -k --keepParent --norsrc --noextattr "$app" "dist/$bundle.zip"
if unzip -l "dist/$bundle.zip" | grep -qE '(^|/)\._|__MACOSX'; then
  echo "zip contains AppleDouble metadata"
  exit 1
fi

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
hdiutil create -volname "$name $version" -srcfolder "$stage" -ov -format UDZO "dist/$bundle.dmg" >/dev/null

if [[ -n "$developer_id" ]]; then
  python3 "$here/tools/run-with-timeout.py" --seconds 120 -- codesign --force --timestamp --sign "$developer_id" "dist/$bundle.dmg"
fi

if $notarize; then
  notarize_file "dist/$bundle.dmg"
  xcrun stapler staple "dist/$bundle.dmg"
  xcrun stapler validate "dist/$bundle.dmg"
  spctl --assess --type execute -vv "$app"
  spctl --assess --type open --context context:primary-signature -vv "dist/$bundle.dmg"
fi

( cd dist && shasum -a 256 "$bundle.zip" "$bundle.dmg" > SHA256SUMS )
echo "packed dist/$bundle.zip and dist/$bundle.dmg"
cat dist/SHA256SUMS
