#!/usr/bin/env bash
# Snapshot and restore the admin user's watch state (played, resume point, favourite), so
# testing leaves JJ's library as it was.
#   scripts/watch-state.sh snapshot [file]   # writes the file (default under ~/dev/_data)
#   scripts/watch-state.sh diff [file]       # items whose state differs from the file
#   scripts/watch-state.sh restore [file]    # puts every differing item back
set -euo pipefail

[[ -z "${ADMIN_USERNAME:-}" ]] && exec onenv export jellyfin -- "$0" "$@"

here=$(cd "$(dirname "$0")" && pwd)
file="${2:-$HOME/dev/_data/jellyfin-ios/watch-state.json}"
user=$("$here/jf.sh" GET /Users/Me | jq -r .Id)

current() {
  "$here/jf.sh" GET "/Items?userId=$user&recursive=true&includeItemTypes=Movie,Episode,Series,Season,BoxSet&limit=2000" |
    jq '[.Items[] | {Id, Name, Played: .UserData.Played, PlaybackPositionTicks: .UserData.PlaybackPositionTicks,
          IsFavorite: .UserData.IsFavorite}] | sort_by(.Id)'
}

differing() {
  jq -n --slurpfile old "$file" --argjson now "$(current)" \
    '$old[0] - $now | map(select(.Id as $id | $now | map(.Id) | index($id)))'
}

case "$1" in
  snapshot)
    mkdir -p "$(dirname "$file")"
    current >"$file"
    echo "saved $(jq length "$file") items to $file" ;;
  diff) differing | jq -r '.[] | "\(.Id) \(.Name): played=\(.Played) pos=\(.PlaybackPositionTicks) fav=\(.IsFavorite)"' ;;
  restore)
    differing | jq -c '.[]' | while read -r row; do
      id=$(jq -r .Id <<<"$row")
      body=$(jq -c '{Played, PlaybackPositionTicks, IsFavorite}' <<<"$row")
      "$here/jf.sh" POST "/UserItems/$id/UserData?userId=$user" "$body" >/dev/null
      echo "restored $(jq -r .Name <<<"$row")"
    done ;;
  *) echo "usage: $0 snapshot|diff|restore [file]" >&2; exit 2 ;;
esac
