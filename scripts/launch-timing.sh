#!/usr/bin/env bash
# Warm launch to Home content: relaunches the installed, signed-in app a few times and prints the
# app's own `JFIOS-TIMING home-content` (milliseconds since the process started).
#   scripts/launch-timing.sh [simulator-udid] [runs]
set -euo pipefail

sim="${1:-booted}" runs="${2:-5}" app=dev.jurrejan.jellyfin-ui
log=$(mktemp)
xcrun simctl spawn "$sim" log stream --level info --predicate 'eventMessage CONTAINS "JFIOS-TIMING home-"' >"$log" 2>&1 &
streamer=$!
trap 'kill $streamer 2>/dev/null; trash "$log"' EXIT
sleep 2

for _ in $(seq "$runs"); do
  xcrun simctl terminate "$sim" "$app" 2>/dev/null || true
  sleep 1
  xcrun simctl launch "$sim" "$app" >/dev/null
  sleep 6
done
xcrun simctl terminate "$sim" "$app" 2>/dev/null || true
grep -o 'home-[a-z]* [0-9]* ms.*' "$log"
