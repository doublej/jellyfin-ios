# v1 tasks

One line per item in the brief: parity with jellyfin-ui v1 (its TASKS.md), the native extras, setup, testing and
the quality bar. Server limits are in docs/GAPS.md; what AVPlayer plays is in docs/PROFILE.md.

## Setup
- [x] Scaffold with `atlas new swift/ios`, branch `feature/v1`
- [x] XcodeGen app target (`project.yml`), `just check` still green
- [x] App Transport Security + Local Network usage description for the plain-http LAN server
- [x] en + nl strings from the first commit, wording from the web client's `messages/`, `just i18n-check` passing

## Sign-in
- [x] User tiles (none show: every user is hidden on this server, see docs/GAPS.md)
- [x] Manual sign-in (built; tests never type a password, by rule)
- [x] Quick Connect (SignInTests, approved from a script)
- [x] Remember me: token in the Keychain, session survives relaunch (PlaybackTests start signed in)

## Home
- [x] Continue Watching
- [x] Next Up
- [x] Recently Added per library
- [x] Large backdrop hero with logo art

## Library browse
- [x] Films and series grids
- [x] Sort
- [x] Filters: status, genre, year, rating, video quality (films only)
- [x] Alphabet jump
- [x] Grid or list view
- [x] View choices remembered per library

## Detail pages
- [x] Film, series, season, episode and person pages
- [x] Version, audio and subtitle pickers
- [x] Cast
- [x] Similar items
- [x] Chapters with their images

## Search
- [x] As you type, grouped by type

## Watched and favourite
- [x] Toggles everywhere: cards (context menu), pages, shared state across views (ToggleTests)

## Player
- [x] Direct play when AVPlayer can play the file, otherwise HLS from the server; profile derived from the probe
- [x] Audio, subtitle and quality switching without losing position
- [x] Subtitle offset (menu, and the web keys `g`/`h` on iPad)
- [x] Trickplay thumbnails on the seek bar (64 items have them, see docs/GAPS.md)
- [x] Skip intro and outro from media segments (server has no segments, see docs/GAPS.md)
- [x] Up Next card with countdown
- [x] Progress reporting: a resume point set in the app shows in the web client's Continue Watching
- [x] Playback errors say what happened and what to do, in the user's language; direct play falls back to HLS

## Settings
- [x] Language follows the system (en, nl)
- [x] Audio and subtitle language, subtitle mode (account-wide, saved on the server)
- [x] Subtitle appearance
- [x] Quality cap
- [x] Quick Connect: approve another device's code

## Admin
- [x] Link to `/web/stock/#/dashboard`, opens in Safari

## Native
- [x] AVPlayer playback (UIKit host, AVPlayerLayer)
- [x] Picture in Picture
- [x] AirPlay (route picker in the player)
- [x] Now Playing info and lock-screen / Control Center commands
- [x] Downloads: choose a quality, see progress, play offline, send the position when back online
- [x] iPhone and iPad layouts (tab bar on iPhone, sidebar-adaptable tabs on iPad)
- [x] Hardware-keyboard shortcuts in the player, keys from the web client's `keys.ts`
- [x] Access token in the Keychain
- [x] Native navigation: TabView, NavigationStack, system sheets; colours, type and artwork from DESIGN.md

## Testing
- [x] Unit tests: decoding, device profile, resume logic, player rules, MP4 retagging (`swift test`)
- [x] XCUITests: sign-in, Home → detail → play → resume, toggles
- [x] Screenshots of each screen on iPhone and iPad (`ScreenTour`)
- [x] Watch state noted before testing and restored after (`scripts/watch-state.sh`)
- [x] Installed on JJ's iPhone (Pocketline Swing)

## Quality bar (simulator, real server)
- [x] Warm launch to Home content ≤ 1 s
- [x] Direct play start ≤ 2 s, with the server/app split (missed for the one MP4, see docs/GAPS.md)
- [x] Audio, subtitle and quality switches keep the position

## Found along the way
- [x] The play/pause observer was dropped whenever a stream attached, so the app never saw playback start
- [x] Pages reloaded before the stop report landed and showed the old resume point; reloads now wait for it
- [x] The seek bar only seeked when a drag ended; VoiceOver's adjust never seeked
- [x] Settings pushed Search into "More" on iPhone; Settings now sits behind Home's gear there
- [x] The server's MP4 remux tags HEVC `hev1`; downloads are retagged `hvc1` so AVPlayer plays them
- [x] The server's H.264 encoder fails on 10-bit HEVC; HEVC downloads keep the original video
- [x] A stalled direct stream never errors, so it now counts as failed after 6 s and falls back to HLS
- [x] LuLu blocked the simulator until "Allow simulator apps" was on
- [x] The trickplay task slowed every API call; stopped during testing with JJ's OK
