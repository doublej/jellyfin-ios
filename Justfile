set shell := ["zsh", "-uo", "pipefail", "-c"]
set unstable := true

sim := env("JFIOS_SIM", "platform=iOS Simulator,name=iPhone 17")

default:
    @just --list
    @echo ''
    @echo "branch: $(git branch --show-current 2>/dev/null || echo 'n/a')"

[group('setup')]
install:
    swift package resolve
    @command -v swiftlint >/dev/null 2>&1 || echo 'warn: swiftlint not installed — run: brew install swiftlint'

[group('develop')]
xcode: project
    open JellyfinUI.xcodeproj

# Generate JellyfinUI.xcodeproj (gitignored) from project.yml
[group('develop')]
project:
    xcodegen generate --quiet

[group('quality')]
lint:
    swiftlint lint --strict

[group('quality')]
lint-fix:
    swiftlint --fix && swiftlint lint --strict

[group('quality')]
just-fmt-check:
    just --fmt --check

[group('quality')]
test:
    swift test

[group('quality')]
loc-check:
    #!/usr/bin/env zsh
    setopt null_glob
    eval "$(python3 -c "
    import json, shlex
    c = json.load(open('.quality.json'))
    print(f'WARN={c[\"loc\"][\"warn\"]}')
    print(f'ERROR={c[\"loc\"][\"error\"]}')
    g = c['globs']
    print(f'GLOBS=({shlex.join(g)})')
    ")"
    err=0
    for pattern in $GLOBS; do
        for f in ${~pattern}; do
            lines=$(wc -l < "$f")
            if (( lines > ERROR )); then echo "error: $f ($lines lines, max $ERROR)"; err=1
            elif (( lines > WARN )); then echo "warn: $f ($lines lines, target ≤$WARN — don't trim, split the file!)"; fi
        done
    done
    exit $err

[group('quality')]
dir-check:
    #!/usr/bin/env zsh
    setopt null_glob
    eval "$(python3 -c "
    import json, shlex
    c = json.load(open('.quality.json'))
    print(f'MAX={c[\"dir\"][\"max_files\"]}')
    g = c['globs']
    print(f'GLOBS=({shlex.join(g)})')
    ")"
    err=0
    typeset -A counts
    for pattern in $GLOBS; do
        for f in ${~pattern}; do
            dir=${f:h}
            counts[$dir]=$(( ${counts[$dir]:-0} + 1 ))
        done
    done
    for dir count in ${(kv)counts}; do
        if (( count > MAX )); then
            echo "error: $dir ($count files, max $MAX)"
            err=1
        fi
    done
    exit $err

[group('quality')]
i18n-check:
    python3 .claude/scripts/check_i18n.py

# Every L10n key the app uses exists in en
[group('quality')]
keys-check:
    python3 scripts/check-keys.py

[group('quality')]
check:
    @echo '→ Checking Justfile format...'
    just just-fmt-check
    @echo '→ Checking file lengths...'
    just loc-check
    @echo '→ Checking directory sizes...'
    just dir-check
    @echo '→ Checking translations...'
    just i18n-check
    just keys-check
    @echo '→ Running lint...'
    just lint
    @echo '→ Running build...'
    just build
    @echo '→ Running tests...'
    just test

# The UI-free core (SwiftPM) and the iOS app (XcodeGen + xcodebuild)
[group('build')]
build: app-build
    swift build

[group('build')]
app-build: project
    xcodebuild build -scheme JellyfinUI -destination '{{ sim }}' -derivedDataPath .build/xcode -quiet

# Unit and UI tests on an iPhone simulator, against the real server; Quick Connect codes are approved by scripts/xctest.sh
[group('quality')]
app-test: project
    scripts/xctest.sh test -scheme JellyfinUI -destination '{{ sim }}' -derivedDataPath .build/xcode

# Measure what AVPlayer plays against the library (about 30 minutes); results land in /tmp/jfios-probe.json
[group('quality')]
probe: project
    scripts/xctest.sh test -scheme Probe -destination '{{ sim }}' -derivedDataPath .build/xcode

# Install a release build on the paired iPhone
[group('build')]
device-install: project
    scripts/device-install.sh

[group('build')]
build-release:
    swift build -c release

[group('cleanup')]
clean:
    swift package clean
    rm -rf .build/

# Open this project's CLAUDE.md tree in the project-atlas viewer, https://github.com/doublej/project-atlas (via the global `atlas` CLI)
[group('docs')]
claude-tree:
    atlas tree

[group('scaffold')]
update-scaffold *ARGS:
    #!/usr/bin/env zsh
    set -euo pipefail
    repo="${COOKIECUTTER_TEMPLATES:-}"
    if [[ -z "$repo" && -f .template-meta.json ]]; then
        repo=$(python3 -c "import json; print(json.load(open('.template-meta.json'))['template_source']['path'])" 2>/dev/null || true)
    fi
    if [[ -z "$repo" || ! -d "$repo" ]]; then
        echo "error: cookiecutter-templates repo not found — set \$COOKIECUTTER_TEMPLATES or fix template_source.path in .template-meta.json" >&2
        exit 1
    fi
    python3 "$repo/tools/update_scaffold.py" {{ ARGS }}
