#!/usr/bin/env bash
# Builds the app for iPhone (Release) and installs it on the paired device.
#   scripts/device-install.sh [device-udid]
# The phone has to be unlocked, on the same network (or cabled), with Developer Mode on.
set -euo pipefail

device="${1:-$(xcrun devicectl list devices 2>/dev/null | awk '/physical/ && /iPhone/ {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F]{8}-[0-9A-F]{16}$/) print $i}' | head -1)}"
[[ -n "$device" ]] || { echo "no paired iPhone found (xcrun devicectl list devices)" >&2; exit 1; }

xcodegen generate --quiet
xcodebuild build -project JellyfinUI.xcodeproj -scheme JellyfinUI -configuration Release \
  -destination generic/platform=iOS -derivedDataPath .build/xcode-device -allowProvisioningUpdates -quiet
app=.build/xcode-device/Build/Products/Release-iphoneos/JellyfinUI.app
xcrun devicectl device install app --device "$device" "$app"
xcrun devicectl device process launch --device "$device" dev.jurrejan.jellyfin-ui
