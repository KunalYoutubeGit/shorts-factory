#!/usr/bin/env bash
# Preflight for the cloud Shorts routine. Idempotent: fast when the environment cache is warm, self-heals when it is not.
# Prints PASS/FAIL per check, writes ~/.faceless-shorts/env.sh (exports CHROME), exits 1 on a blocking failure.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/.claude/skills/faceless-shorts"
FH="${FACELESS_HOME:-$HOME/.faceless-shorts}"; mkdir -p "$FH"
fail=0; line() { printf '%-11s %s\n' "$1" "$2"; }; bad() { line "$1" "FAIL  $2"; fail=1; }

# 1 ── system packages (ffmpeg + the libraries headless Chrome needs)
PKGS="ffmpeg unzip curl ca-certificates fonts-liberation libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2t64 libpango-1.0-0 libcairo2 libxshmfence1"
MISSING=""; for p in $PKGS; do dpkg -s "$p" >/dev/null 2>&1 || MISSING="$MISSING $p"; done
if [ -n "$MISSING" ]; then (apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends $MISSING) >"$FH/apt.log" 2>&1 || true; fi
if command -v ffmpeg >/dev/null && command -v ffprobe >/dev/null; then line ffmpeg PASS; else bad ffmpeg "not installed (see $FH/apt.log)"; fi
if node -v 2>/dev/null | grep -qE '^v(2[2-9]|[3-9][0-9])'; then line node "PASS ($(node -v))"; else bad node "Node.js 22+ needed"; fi

# 2 ── headless Chrome (Chrome for Testing from storage.googleapis.com, which the Trusted network level allows)
CHROME_VERSIONS="${CHROME_VERSIONS:-131.0.6778.204 130.0.6723.116 129.0.6668.100 128.0.6613.137 126.0.6478.182}"
find_chrome() { for p in "${CHROME:-}" /usr/bin/google-chrome /usr/bin/google-chrome-stable "$FH"/chrome/*/chrome-headless-shell-linux64/chrome-headless-shell /opt/pw-browsers/chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell; do [ -n "$p" ] && [ -x "$p" ] && { echo "$p"; return 0; }; done; return 1; }
CH="$(find_chrome || true)"
if [ -z "$CH" ]; then
  for v in $CHROME_VERSIONS; do
    url="https://storage.googleapis.com/chrome-for-testing-public/$v/linux64/chrome-headless-shell-linux64.zip"
    if curl -fsSL --retry 2 -o "$FH/chrome.zip" "$url"; then mkdir -p "$FH/chrome/$v" && unzip -qo "$FH/chrome.zip" -d "$FH/chrome/$v"; rm -f "$FH/chrome.zip"; CH="$(find_chrome || true)"; [ -n "$CH" ] && break; fi
  done
fi
if [ -n "$CH" ] && "$CH" --no-sandbox --disable-gpu --dump-dom about:blank 2>/dev/null | grep -qi "<html"; then line chrome "PASS ($CH)"; else bad chrome "no working headless Chrome (is storage.googleapis.com reachable?)"; CH=""; fi
[ -n "$CH" ] && printf 'export CHROME=%q\nexport PATH="$HOME/.local/bin:$PATH"\n' "$CH" > "$FH/env.sh"

# 3 ── Python env + Kokoro voice, using the skill's own setup (a missing Whisper model is tolerated: word timings are then estimated)
if [ -d "$SKILL/scripts" ]; then
  CHROME="$CH" bash "$SKILL/scripts/setup.sh" >"$FH/setup.log" 2>&1 || true
  grep -qE '^python-env +ok' "$FH/setup.log" && line python-env PASS || bad python-env "see $FH/setup.log"
  grep -qE '^voice +ok' "$FH/setup.log" && line voice PASS || bad voice "Kokoro model download failed (see $FH/setup.log)"
  grep -qE '^whisper +ok' "$FH/setup.log" && line whisper PASS || line whisper "SKIPPED (model not reachable; word timings will be estimated, fine)"
else bad skill "folder .claude/skills/faceless-shorts is missing from the repo"; fi

# 4 ── publishing path (public GitHub repo, raw file URL)
if [ -z "${SHORTS_REPO:-}" ]; then bad repo "environment variable SHORTS_REPO (owner/repo) is not set"
else
  code="$(curl -s -o /dev/null -w '%{http_code}' -IL "https://raw.githubusercontent.com/$SHORTS_REPO/HEAD/README.md" || true)"
  [ "$code" = 200 ] && line repo "PASS ($SHORTS_REPO is public and readable)" || bad repo "raw.githubusercontent.com/$SHORTS_REPO/HEAD/README.md returned HTTP $code (repo must be PUBLIC and have a README.md)"
fi

[ $fail = 0 ] && { echo "PREFLIGHT PASSED"; exit 0; } || { echo "PREFLIGHT FAILED"; exit 1; }
