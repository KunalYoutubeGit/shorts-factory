# Shorts factory

This repo runs one unattended job a day: make and publish a faceless YouTube Short. The job's instructions are the routine prompt (ROUTINE_PROMPT.md).

Rules for every session here:
- The skill is `.claude/skills/faceless-shorts/` (read its SKILL.md and the chosen style's STYLE.md in full).
- Work only in `~/faceless-shorts/<slug>/` and in `data/` (a worktree of the branch `claude/shorts-videos`). Never edit the default branch.
- Before any skill script: `bash scripts/preflight.sh && source ~/.faceless-shorts/env.sh`.
- Never publish a video you have not checked frame by frame. If anything fails, stop and report which step failed and why.
