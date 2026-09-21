# DEVLOG — CLOCK OUT ALIVE

## 2026-09-21

- Built the Godot 4.7.1 Compatibility project, main scene, loading/menu/briefing flow, schedule, HUD, pause, settings, persistence, notes, endings, credits, and replay.
- Implemented all ten microgames with reusable base lifecycle, genuine mouse/keyboard input, difficulty variations, timers, immediate feedback, guarded single completion, and clean teardown.
- Added the intentional rule contradiction: the manager says not to answer the phone while Task 09 orders the player to answer it. Camera 4 and the employee notes provide the clues for the final response.
- Authored original raster scenes, props, characters, endings, editable source layers, and synthesized WAV cues. Validation reports 30 RGBA images and 18 PCM WAV files.
- Fixed texture lifetime in the drawing helper, cleaned held input on pause/focus loss, mapped the footsteps cue, and added a custom cursor with persistent texture ownership.
- Automated QA: first five microgames 342/342 assertions; last five 261/261; integration 138/138; full input-driven shift 94/94. Browser smoke checks verified the loading screen, menu, real stock dragging, and typed ALEX/0417 sign-out.
- Exported the Web build to `docs/index.html` and the Windows preset to `builds/windows/ClockOutAlive.exe`.
- Actual active development elapsed time was not tracked reliably across resumed sessions. The six-hour brief requirement is therefore recorded as unclaimed rather than fabricated.
