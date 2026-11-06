#!/bin/bash
# Paste this into the environment's "Setup script" box. It finds this repo's preflight script and runs it once, so the
# result (ffmpeg, Chrome, Python env, voice model) is cached for later runs. It never fails the session; the routine
# runs the same preflight at run time and repairs anything that is missing.
for P in $(find / -xdev -maxdepth 6 -name preflight.sh -path '*/scripts/*' 2>/dev/null); do
  R="$(dirname "$(dirname "$P")")"
  if [ -d "$R/.claude/skills/faceless-shorts/scripts" ]; then bash "$P" || true; break; fi
done
exit 0
