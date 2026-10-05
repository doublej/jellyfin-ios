#!/usr/bin/env bash
# One Jellyfin API call as the admin user, for tests and probes.
#   scripts/jf.sh GET /Users/Me
#   scripts/jf.sh POST /QuickConnect/Authorize?code=123456
#   scripts/jf.sh POST /UserItems/<id>/UserData '{"PlaybackPositionTicks":0}'
# Credentials come from onenv and stay in this process: never echoed, never written.
set -euo pipefail

SERVER="${JF_SERVER:-http://192.168.178.120:8096}"
AUTH='MediaBrowser Client="jellyfin-ios scripts", Device="scripts", DeviceId="jellyfin-ios-scripts", Version="0.1.0"'

if [[ -z "${ADMIN_USERNAME:-}" ]]; then
  exec onenv export jellyfin -- "$0" "$@"
fi

method="$1" path="$2" body="${3:-}"
login=$(jq -nc --arg u "$ADMIN_USERNAME" --arg p "$ADMIN_PASSWORD" '{Username: $u, Pw: $p}')
token=$(curl -sf -X POST "$SERVER/Users/AuthenticateByName" -H "Authorization: $AUTH" \
  -H 'Content-Type: application/json' --data-binary @- <<<"$login" | jq -r .AccessToken)

args=(-sS -X "$method" "$SERVER$path" -H "Authorization: $AUTH, Token=\"$token\"")
[[ -n "$body" ]] && args+=(-H 'Content-Type: application/json' --data-binary "$body")
curl "${args[@]}"
