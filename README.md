# Shorts factory (cloud version)

A daily, fully automatic faceless YouTube Short that runs in Anthropic's cloud as a **Claude Code routine**, so your laptop can stay off.
Every day at 7:30 p.m. India time it finds a topic, writes and checks the script, builds and QA-checks the video, puts the MP4 on a GitHub branch,
and uploads it to your channel through Zapier. The Short goes live around 8:00 p.m.

## What was tested, and what was not

Tested (in my sandbox): all scripts parse; the publish flow (create the data branch, reuse it on a fresh clone, copy the video, log line, delete videos older than 3 days, leave the default branch untouched) against a local git remote; the preflight checks for ffmpeg, Node, Chrome, the Python env and the voice model; the raw-file URL format on a real public repo.

**Not tested, so the first run is the real test:**
- Anything inside Anthropic's cloud VM: that apt works, that Chrome can be downloaded from storage.googleapis.com, that the setup finishes inside the ~5 minute caching window.
- That a routine may push repeatedly to the existing branch `claude/shorts-videos` (the docs say pushes are limited to `claude/`-prefixed branches by default, which this fits).
- That Zapier's YouTube upload accepts a `raw.githubusercontent.com` link. Your earlier uploads used a Drive file, not a GitHub link.
- How much of your plan's usage one daily run consumes. Watch it for the first week.
- Routines are a research preview, so the feature can change.

## One-time setup (about 20 minutes)

1. **GitHub repo.** Create a new **public** repo (the video link must be readable without a login). Put the contents of this folder in it, including the hidden `.claude` folder:
   ```
   cd faceless-shorts-cloud
   git init -b main && git add -A && git commit -m "Shorts factory"
   git remote add origin https://github.com/YOUR-NAME/YOUR-REPO.git && git push -u origin main
   ```
   Heads up: this puts a copy of the faceless-shorts skill into a public repo. Its README says its code, drawings and sound are free to use in your videos but does not mention redistribution. Check that you are comfortable with that.
2. **Connect GitHub to Claude Code on the web** (claude.ai/code): install the Claude GitHub App on that repo, or run `/web-setup` in the Claude Code CLI. Routines need a paid plan with Claude Code on the web.
3. **Create an environment** (environment selector at claude.ai/code → New environment):
   - Network access: **Trusted** (the default). It already allows GitHub, PyPI, npm, Ubuntu packages and storage.googleapis.com.
   - Environment variables (one per line):
     ```
     SHORTS_REPO=YOUR-NAME/YOUR-REPO
     BASH_DEFAULT_TIMEOUT_MS=600000
     BASH_MAX_TIMEOUT_MS=1200000
     ```
   - Setup script: paste `ENVIRONMENT_SETUP_SCRIPT.sh`.
4. **Create the routine** (claude.ai/code/routines → New routine):
   - Prompt: paste `ROUTINE_PROMPT.md`.
   - Repository: your repo. Leave **Allow unrestricted branch pushes** OFF.
   - Environment: the one from step 3.
   - Connectors: **Zapier** only (the same connection you use in chat, with YouTube enabled).
   - Trigger: schedule, daily at **7:30 p.m.**, and check that the time zone shown is India Standard Time.
5. **Run it once now** and watch the session. Runs have no approval prompts, so it will not stop to ask.

## First-run checklist

- [ ] The log shows `PREFLIGHT PASSED` (a skipped Whisper line is fine).
- [ ] The session looks at the contact sheet and fixes anything it finds before the final render.
- [ ] `data-branch.sh publish` printed a raw.githubusercontent.com URL (it waits until the link works).
- [ ] The Zapier upload returns an id and `uploadStatus: uploaded`, and the video plays on YouTube.
- [ ] `_published.md` on the `claude/shorts-videos` branch has a new line.

## If something fails

| Symptom | Likely cause and fix |
|---|---|
| `chrome FAIL` | The download from storage.googleapis.com was blocked. Switch the environment to Custom network access, tick "include default list", and add the domain your error names. |
| `voice FAIL` | The Kokoro model comes from GitHub releases. Check the environment allows github.com and release-assets.githubusercontent.com (Trusted does). |
| `repo FAIL (HTTP 404)` | The repo is not public, `SHORTS_REPO` is wrong, or the repo has no `README.md` on the default branch. |
| `publish` prints ERROR | The push was rejected. Make sure the branch name is `claude/shorts-videos` and unrestricted pushes are not needed. |
| Zapier rejects the video link | Tell me the exact error. The fallback is to upload the file to Drive and pass Zapier the Drive "file" value. |
| Run is slow or stops | Setup took over ~5 minutes so the cache was not used. The routine still works but takes longer each day. |

## Daily result

The routine's last message (the report) appears in the run's session on claude.ai/code. It does not send a notification by itself; add an email or Slack connector to the routine and a line in the prompt if you want one.
