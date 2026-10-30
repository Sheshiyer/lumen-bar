#!/bin/zsh
# Runs the in-app self-test against a fresh store in /tmp. Exit code 0 when every check passed.
set -u
here=${0:A:h:h}
app="$here/dist/LumenBar.app/Contents/MacOS/LumenBar"
[[ -x "$app" ]] || app=~/Applications/LumenBar.app/Contents/MacOS/LumenBar
store=/tmp/LumenBar-self.store
rm -f $store $store-shm $store-wal
APP_STORE=$store "$app" --selftest
