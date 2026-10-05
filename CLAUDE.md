# jellyfin-ios

> Native iOS/iPadOS client for JJ's Jellyfin server (Jellyfin UI on the home screen): parity with the
> web client `$HOME/dev/web/jellyfin-ui`, plus AVPlayer, PiP, AirPlay, lock-screen controls and downloads.

## What this is

A SwiftUI app for iOS 26 (iPhone + iPad), Swift 6 strict concurrency. Two halves:

```
jellyfin-ios/Kit/      JellyfinKit: UI-free SwiftPM library (API, models, profile, player rules). swift test on macOS.
jellyfin-ios/App/      The app, built by XcodeGen (project.yml → JellyfinUI.xcodeproj, gitignored). MainActor by default.
Tests/JellyfinKitTests Unit tests: decoding, device profile, resume, player rules, MP4 fix-ups.
Tests/UITests          XCUITests: sign-in, Home → play → resume, toggles, screen tour (screenshots to /tmp/jfios-shots/).
Tests/ProbeTests       What AVPlayer really plays against the live library (`just probe`, ~30 min).
scripts/               jf.sh (one API call as admin), xctest.sh (approves Quick Connect), watch-state.sh, device-install.sh.
docs/                  GAPS.md (server limits), PROFILE.md (probe results → device profile).
```

## Mental model

`JellyfinApp` → `RootView` (sign-in or `MainTabs`) → a `NavigationStack` per tab with `routeDestinations()`.
`AppModel` (environment) owns the session, API client, `UserDataStore` (watched/favourite shared by every view),
`DownloadManager` and `PlaybackPrefs`. Playing anything sets `app.playing`; `RootView` shows `PlayerView` full screen.
`PlayerController` negotiates (`Negotiator`, PlaybackInfo with `DeviceProfile.build(.avPlayer)`), attaches the stream,
switches tracks/quality at the same position, falls back from direct play to HLS, and reports progress.
Ported rules from the web client live in Kit with the web file named in the doc comment.

## Invariants

- Credentials only through `onenv export jellyfin -- <command>` (scripts do this). Never in files, logs or the repo.
- Watch state changed by tests is JJ's: `scripts/watch-state.sh snapshot` before, `restore` after (`diff` must print nothing).
- Quick Connect in the simulator is approved by `scripts/xctest.sh`; no password is ever typed into the UI.
- Jellyfin JSON is PascalCase (`JSONCoding` flips the first letter); local persistence uses plain JSON coders.
- User-facing text: `L10n.t("key")` / `L10n.f("key", args)` with keys in `jellyfin-ios/App/Resources/{en,nl}.lproj`.
  Wording follows the web client's `messages/` (`scripts/import-web-strings.py`). nl is informal (je/jij).
- New source files need `just project` (xcodegen) before xcodebuild sees them.
- SwiftLint `--strict`; files ≤ 300 lines, ≤ 6 files per folder (`.quality.json`).

## Common change patterns

- **Add text** → both `.strings` files, then `just i18n-check keys-check`.
- **Add an API call** → `Kit/API/<area>.swift` extension on `APIClient`, decoded with `JSONCoding.decoder`.
- **Change what AVPlayer is offered** → `Kit/Profile/Capabilities.swift`, re-run `just probe`, update docs/PROFILE.md.
- **Add a screen** → a `View` in the matching `App/<area>/` folder; route via `Route` in `Shell/Routes.swift`.
- **Server can't do it** → note it in docs/GAPS.md with the reason and build the closest thing it allows.

## Verification

`just check` = fmt + loc + dir + i18n + keys + lint + build (app + Kit) + Kit tests.
`just app-test` runs the unit and UI tests on an iPhone simulator against the real server (`JFIOS_SIM` overrides the destination).
`just device-install` builds Release and installs on the paired iPhone (it must be unlocked).
Timings: the app logs `JFIOS-TIMING <event> <ms>` (category `timing`); stream them with
`xcrun simctl spawn booted log stream --predicate 'eventMessage CONTAINS "JFIOS-TIMING"'`.

## Related context

- [agent.md](agent.md) — verify loop, auto-fix commands, common tasks, boundaries
- `.claude/` — Claude Code settings, scaffold-update hook, library-freshness hook, diagnostic logging
- `.quality.json` — loc / dir thresholds (single source of truth)
- `.swiftlint.yml` — strict lint ruleset
- `TASKS.md` — the v1 checklist; `docs/GAPS.md`, `docs/PROFILE.md`
- `$HOME/dev/web/jellyfin-ui` — the web client this app matches (TASKS.md, docs/DESIGN.md, `src/lib/player/rules/`)

<!-- agent-log:policy -->
### Shared agent journal

Use `./agent-log` (a shim for `atlas agent-log` — both are identical) for short-lived
operational awareness between concurrent agents. It is not chat and not a task tracker: the
issue tracker remains the source of truth for ownership, blockers, and durable findings.

- Run `./agent-log recent` before interpreting shared state.
- Before an action that can change another agent's observations, write an intent with every
  affected scope. This includes shared-worktree edits, generated artifacts, git/index
  mutations, and shared ports, processes, or services.
- Run builds, tests, and deployments through the wrapper so start, commit, dirty state,
  duration, exit code, and outcome are recorded even on failure:
  `./agent-log run build|test|deploy --scope <resource> [--bead <id>] -- <command...>`.
- For manual operations, use `./agent-log begin <operation> --scope <resource> [--bead <id>]
  -- <summary>` and always close the returned id with `./agent-log end <id> --outcome
  ok|failed|cancelled -- <result>`. `<operation>` is one of build, commit, deploy, edit, implement, investigate, merge, push, review, sync, test — what
  makes this particular run specific goes in the summary, never in an invented operation name.
- Record a temporary result-affecting discovery with `./agent-log finding --scope <resource>
  --evidence <fact> [--bead <id>] -- <summary>`. This is the entry that saves another agent a
  wasted run, and the one most often skipped — write one whenever you learn something that
  would change what a concurrent agent does next, especially a dead end. Promote lasting
  knowledge to the issue tracker or the relevant doc.
- At session end, write `./agent-log handoff -- <stopping point + next step>` — the durable
  baton the next session's briefing picks up. Handoffs never expire; the latest one is
  always shown by `recent`.
- Intents expire after 20 minutes and findings after 4 hours unless `--ttl` overrides them.
  Renew by closing and reopening an intent; never treat an expired entry as current.
- Keep summaries factual and short. Do not reply, ask questions, mention agents, narrate
  routine progress, or log isolated reads/edits/tests that cannot affect anyone else.

Canonical scopes are `path:<repo-relative-path>`, `artifact:<name>`, `service:<name>`,
`host:<name>`, `port:<number>`, and `git:<worktree-or-ref>`; a repo may define additional
canonical scopes of its own. Add multiple `--scope` flags when needed. The journal SQLite db
lives in the git common directory, so linked worktrees share it without dirtying the repo.
