# jellyfin-ios

Jellyfin UI for iPhone and iPad: a native SwiftUI client for the home Jellyfin server, matching the web
client `jellyfin-ui` and adding AVPlayer playback, Picture in Picture, AirPlay, lock-screen controls and downloads.

## Requirements

- Xcode 26, iOS 26 simulator or device
- `xcodegen`, `swiftlint`, `just`
- `onenv` with the `jellyfin` item, for tests and scripts

## Getting started

```bash
just project        # generate JellyfinUI.xcodeproj from project.yml
just xcode          # open it
just check          # everything except the simulator tests
just app-test       # unit + UI tests on an iPhone simulator, against the real server
just device-install # Release build on the paired iPhone
```

See `CLAUDE.md` for the layout, `TASKS.md` for the v1 checklist and `docs/GAPS.md` for what the server can't do.
