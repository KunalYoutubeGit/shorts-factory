#!/usr/bin/env bash
# Keeps finished videos and the published log on their own branch (claude/shorts-videos), so the default branch stays clean
# and every push stays inside the claude/ prefix that routines are allowed to push to.
#   data-branch.sh init                        create or refresh the ./data worktree
#   data-branch.sh publish <file.mp4> <name>   copy the video in, commit, push, wait until its raw URL works, print the URL
#   data-branch.sh log "<line>"                append a line to data/_published.md, prune old videos, commit, push
# Env: SHORTS_REPO=owner/repo (required)   SKIP_URL_CHECK=1 (tests only)
set -euo pipefail
BR="claude/shorts-videos"; ROOT="$(cd "$(dirname "$0")/.." && pwd)"; DATA="$ROOT/data"
: "${SHORTS_REPO:?set SHORTS_REPO=owner/repo in the environment variables}"
cd "$ROOT"
gc() { git -C "$DATA" -c user.name="Shorts routine" -c user.email="shorts-routine@users.noreply.github.com" "$@"; }
push() { for i in 1 2 3; do gc push origin "HEAD:refs/heads/$BR" && return 0; gc pull --rebase origin "$BR" >/dev/null 2>&1 || true; sleep 3; done; return 1; }
init() {
  [ -e "$DATA/.git" ] && return 0
  if git fetch origin "$BR" >/dev/null 2>&1; then git worktree add -B "$BR" "$DATA" "origin/$BR" >/dev/null
  else
    git worktree add --orphan -b "$BR" "$DATA" >/dev/null
    printf '# Published Shorts\n\ndate | topic | style | title | link\n' > "$DATA/_published.md"; mkdir -p "$DATA/videos"; touch "$DATA/videos/.keep"
    gc add -A; gc commit -qm "init data branch"
  fi
  echo "data branch ready: $DATA"
}
prune() {
  local cutoff f b; cutoff="$(date -u -d '3 days ago' +%F)"
  for f in "$DATA"/videos/*.mp4; do
    [ -e "$f" ] || continue; b="$(basename "$f")"
    if [[ "${b:0:10}" < "$cutoff" ]]; then rm -f "$f"; fi
  done
  return 0
}
publish() {
  local src="$1" name="$2" url code=000
  init; mkdir -p "$DATA/videos"; cp "$src" "$DATA/videos/$name"
  gc add -A; gc commit -qm "video: $name"; push
  url="https://raw.githubusercontent.com/$SHORTS_REPO/refs/heads/$BR/videos/$name"
  [ "${SKIP_URL_CHECK:-0}" = 1 ] && { echo "$url"; return 0; }
  for i in $(seq 1 12); do code="$(curl -s -o /dev/null -w '%{http_code}' -I "$url" || true)"; [ "$code" = 200 ] && { echo "$url"; return 0; }; sleep 5; done
  echo "ERROR: $url not reachable (last HTTP $code). Is $SHORTS_REPO public?" >&2; return 1
}
logline() { init; printf '%s\n' "$1" >> "$DATA/_published.md"; prune; gc add -A; gc commit -qm "log"; push; }
case "${1:-}" in
  init) init ;;
  publish) publish "${2:?mp4 path}" "${3:?file name like 2026-11-07-topic.mp4}" ;;
  log) logline "${2:?log line}" ;;
  *) echo "usage: $0 init | publish <mp4> <name> | log <line>" >&2; exit 2 ;;
esac
