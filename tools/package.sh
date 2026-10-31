#!/bin/zsh
# Builds a release .app and packs a downloadable zip and a drag-to-Applications disk image.
#   tools/package.sh                 signed with the Developer ID when one exists
#   tools/package.sh --notarize      also notarizes and staples (needs APPLE_ID, APPLE_TEAM_ID,
#                                    APPLE_APP_PASSWORD, and a Developer ID Application identity)
# Output: dist/LumenBar-<version>.zip, dist/LumenBar-<version>.dmg, dist/SHA256SUMS
set -euo pipefail
here=${0:A:h:h}
name="LumenBar"
cd "$here"

developer_id=$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -o '"Developer ID Application: [^"]*"' | tr -d '"' || true)
if [[ -n "$developer_id" ]]; then
  export SIGN_IDENTITY="$developer_id"
fi

./build.sh
app="dist/$name.app"
[[ -d "$app" ]] || { echo "build produced no app"; exit 1; }

version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
bundle="LumenBar-$version"

if [[ " $* " == *" --notarize "* ]]; then
  : "${APPLE_ID:?set APPLE_ID}" "${APPLE_TEAM_ID:?set APPLE_TEAM_ID}" "${APPLE_APP_PASSWORD:?set APPLE_APP_PASSWORD}"
  [[ -n "$developer_id" ]] || { echo "notarization needs a Developer ID Application certificate"; exit 1; }
  ditto -c -k --keepParent "$app" "dist/$bundle-notarize.zip"
  xcrun notarytool submit "dist/$bundle-notarize.zip" \
    --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" --wait
  xcrun stapler staple "$app"
  rm -f "dist/$bundle-notarize.zip"
fi

rm -f "dist/$bundle.zip" "dist/$bundle.dmg"
ditto -c -k --keepParent "$app" "dist/$bundle.zip"

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
hdiutil create -volname "$name $version" -srcfolder "$stage" -ov -format UDZO "dist/$bundle.dmg" >/dev/null

if [[ -n "$developer_id" ]]; then
  codesign --force --sign "$developer_id" "dist/$bundle.dmg"
fi

( cd dist && shasum -a 256 "$bundle.zip" "$bundle.dmg" > SHA256SUMS )
echo "packed dist/$bundle.zip and dist/$bundle.dmg"
cat dist/SHA256SUMS
