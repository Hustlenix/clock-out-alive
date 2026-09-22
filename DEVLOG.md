# DEVLOG — CLOCK OUT ALIVE

## 2026-09-22 — release audit

- Fixed pause rebuilding screens and resetting countdowns; retained the original controls through nested clipboard/settings flows, including notes and results.
- Added a complete collected-note archive, immediate READY NOW gameplay, button text fitting, correctly sized menu artwork, and earlier shelf rearrangement on the normal second round.
- Reset audio pitch/escalation on replay and stop ambience at the menu. Released the custom cursor on shutdown after a native-render audit exposed a texture leak.
- Added regression coverage: 158 integration assertions and 988 rendered-control layout assertions. Existing microgame suites pass 342 and 261 assertions; the full input-driven shift passes 94.
- Visually reviewed real native OpenGL captures of the menu, intermission, clipboard, winner, and death screens. Added reproducible tested exports, engine notices, and release packaging instructions.
- Actual active elapsed development time remains unclaimed; no artificial time entries were added.

## 2026-09-21

- Built the Godot 4.7.1 Compatibility project, main scene, loading/menu/briefing flow, schedule, HUD, pause, settings, persistence, notes, endings, credits, and replay.
- Implemented all ten microgames with reusable base lifecycle, genuine mouse/keyboard input, difficulty variations, timers, immediate feedback, guarded single completion, and clean teardown.
- Added the intentional rule contradiction: the manager says not to answer the phone while Task 09 orders the player to answer it. Camera 4 and the employee notes provide the clues for the final response.
- Authored original raster scenes, props, characters, endings, editable source layers, and synthesized WAV cues. Validation reports 30 RGBA images and 18 PCM WAV files.
- Fixed texture lifetime in the drawing helper, cleaned held input on pause/focus loss, mapped the footsteps cue, and added a custom cursor with persistent texture ownership.
- Automated QA: first five microgames 342/342 assertions; last five 261/261; integration 138/138; full input-driven shift 94/94. Browser smoke checks verified the loading screen, menu, real stock dragging, and typed ALEX/0417 sign-out.
- Exported the Web build to `docs/index.html` and the Windows preset to `builds/windows/ClockOutAlive.exe`.
- Actual active development elapsed time was not tracked reliably across resumed sessions. The six-hour brief requirement is therefore recorded as unclaimed rather than fabricated.

## 2026-09-21 — feedback pass

- Replaced the generic loading backdrop with a dark arcade briefing card that previews the upcoming challenge, shows its controls and goal, and cycles through the first three challenge teasers while assets load.
- Reframed the task cards and HUD around arcade challenges: quick-clear bonuses, streak multipliers, optional Camera 4 risk bonus, and energetic names such as Shadow Slalom, Voltage Memory, Rat Race, and Escape the Shift.
- Rebuilt the between-assignment intermission as a centered next-challenge card. It now keeps the store readable, explains the upcoming game and controls, shows the quick-clear reward, and offers READY NOW, clipboard, and glass-clue actions without stale task HUD overlap.
- Kept the evidence-driven horror and deliberate rule contradiction intact while making the player’s moment-to-moment goal more playful and score-driven.
