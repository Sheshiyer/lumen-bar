#!/bin/zsh
# Snapshots of every page in light and dark, with seed data, on a fresh test store.
set -u
here=${0:A:h:h}
app="$here/dist/LumenBar.app/Contents/MacOS/LumenBar"
[[ -x "$app" ]] || app=~/Applications/LumenBar.app/Contents/MacOS/LumenBar
store=/tmp/LumenBar-test.store
shots="$here/docs/screenshots"
rm -f $store $store-shm $store-wal
rm -rf "$shots"
mkdir -p "$shots"
APP_STORE=$store APP_SEED=1 APP_SNAPSHOT="$shots" "$app"
