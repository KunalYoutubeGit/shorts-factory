You are running unattended in a cloud session. Never ask me anything; make every decision yourself. Make and publish one YouTube Short with the faceless-shorts skill, then report. Do the steps in order. Your final message is the report.

FIXED SETTINGS
- Skill: .claude/skills/faceless-shorts/ in this repo (read SKILL.md first). Helper scripts: scripts/preflight.sh and scripts/data-branch.sh.
- Projects go in ~/faceless-shorts/<topic-slug>/. Videos and the log live on the branch claude/shorts-videos, checked out at ./data by data-branch.sh. Never push anywhere else.
- Zapier connector: YouTube (selected_api YouTubeV4CLIAPI, tool youtube_upload_video). Call inspect_zapier_actions for it before the first upload to get the exact parameters.
- Schedule: this routine starts at 7:30 p.m. India time, so the Short goes live around 8:00 p.m. Do not wait or sleep to hit an exact minute; publish as soon as the video is checked.

0. PREP
Run: bash scripts/preflight.sh   then: source ~/.faceless-shorts/env.sh   then: bash scripts/data-branch.sh init
If preflight prints PREFLIGHT FAILED, stop and report step 0 failed, with the FAIL lines.

1. FIND THE IDEA
Search the web for what is trending and shared right now in science, space, the human body, history, survival and "what if" questions. Pick the one topic with the strongest viral potential: a curiosity hook that stops the scroll, a surprising answer, and something a 30-40 second Short can explain. Read data/_published.md and never repeat a topic already listed.
Safety: no medical advice or health-benefit claims. Human-body topics must be plain anatomy or physiology facts. Skip any topic where you cannot confirm every claim in at least two reliable sources.

2. CHOOSE THE STYLE
Pick the best style for the topic with the skill's own guide. Read that style's STYLE.md in full.

3. WRITE THE SCRIPT
Follow the skill's script rules: about 100 words, a hook question first, a twist, and a last line that loops back to the start. Write it originally. Check every fact against a reliable source and list the sources in script.json. Change or remove any unsourced claim.
Title: short, curious, under 60 characters, ending in " #shorts".

4. MAKE THE VIDEO
Skip the skill's intake and "Build it?" steps. Use its defaults (AI voice, built-in music). Create the project, generate the voiceover and word timings (if the Whisper model is unavailable, the estimated timing fallback is fine), write the shots, and run the skill's full QA: render the contact sheet, look at every frame, and fix every problem before the final render. Specifically check: captions all in the same bold sans font; no pill, card or label overlapping the caption zone (y 1250-1550); no tiny, clipped or unreadable elements; each visual matches its spoken line. Then check the final MP4 itself (1080x1920, duration, a frame sheet taken from the file). Never publish a video you have not checked.

5. PUT THE FILE ONLINE
File name: <YYYY-MM-DD>-<topic-slug>.mp4 (ASCII, no spaces). Run:
  bash scripts/data-branch.sh publish <path-to-final.mp4> <file-name>
It prints a public URL once the file is reachable. If it prints an ERROR, stop and report step 5 failed.

6. PUBLISH
Zapier YouTube "Upload Video". For the video field pass the URL from step 5. Settings:
   - privacy_status: public
   - title: the step 3 title, unchanged
   - description: one or two catchy sentences plus 3 to 5 hashtags
   - tags: 5 relevant tags
   - category_id: best fit, "28" Science & Technology or "27" Education; never the default
   - made_for_kids: false, embeddable: true, notify_subscribers: false, default_language: en
Confirm the result shows an id and uploadStatus "uploaded". The link is https://www.youtube.com/watch?v=<id>.
If the upload fails, retry once; if it still fails, stop and report step 6 failed with the exact error, and do not claim success.

7. LOG IT
bash scripts/data-branch.sh log "<date> | <topic> | <style> | <title> | <YouTube link>"

8. REPORT
Final message: the title, the link, and anything you fixed during QA. If any step failed, say which step and why, and do not publish a half-finished video.
