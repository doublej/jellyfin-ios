#!/usr/bin/env bash
# Runs xcodebuild and approves every Quick Connect code a test shows, as the admin, so tests
# sign in without a password ever reaching the simulator or the repo.
#   scripts/xctest.sh test -scheme JellyfinUI -destination 'platform=iOS Simulator,name=iPhone 17'
# Tests announce a code by printing `JFIOS-QC-CODE=123456` or writing it to /tmp/jfios-qc-code.
# The full log goes to $XCTEST_LOG; the terminal gets results, failures and JFIOS- lines.
set -uo pipefail

[[ -z "${ADMIN_USERNAME:-}" ]] && exec onenv export jellyfin -- "$0" "$@"

here=$(cd "$(dirname "$0")" && pwd)
log="${XCTEST_LOG:-/tmp/jfios-xctest.log}"
codefile=/tmp/jfios-qc-code
trash "$codefile" 2>/dev/null

approve() {
  "$here/jf.sh" POST "/QuickConnect/Authorize?code=$1" >/dev/null && echo "approved Quick Connect code $1"
}

watch_file() {
  while sleep 1; do
    [[ -s "$codefile" ]] || continue
    code=$(<"$codefile")
    trash "$codefile"
    approve "$code"
  done
}

watch_file &
watcher=$!
trap 'kill $watcher 2>/dev/null' EXIT

xcodebuild "$@" 2>&1 | tee "$log" | while IFS= read -r line; do
  if [[ $line =~ JFIOS-QC-CODE=([0-9]+) ]]; then approve "${BASH_REMATCH[1]}" & fi
  [[ $line =~ (JFIOS-|error:|Test\ Case.*(passed|failed)|Test\ Suite.*(passed|failed)|\*\*\ .*\ \*\*|XCTAssert|Executed) ]] &&
    printf '%s\n' "$line"
done
exit "${PIPESTATUS[0]}"
