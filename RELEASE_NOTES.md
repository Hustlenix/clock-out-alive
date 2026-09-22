# CLOCK OUT ALIVE 1.0

[Play in your browser](https://hustlenix.github.io/clock-out-alive/)

Ten interactive horror microgames across eighteen escalating challenges, with three safety marks, collected clues, score streaks, optional Camera 4 evidence, and distinct win/death endings.

## Release audit fixes

- Briefings and intermissions explain the upcoming objective and controls. READY NOW starts gameplay immediately.
- Pause and nested settings preserve the original screen, controls, note position, and countdown.
- The clipboard retains all collected employee notes with previous/next navigation.
- Long buttons and the menu logo fit their panels. Hidden menu copy and a stray HUD heading were removed.
- Replay resets audio pitch and escalation; returning to the menu stops shift ambience.
- Shelf rearrangement appears on the standard harder round, even without earlier failures.
- The custom cursor is released cleanly on native shutdown.

## Downloads

- **ClockOutAlive-Windows.zip**: extract and run ClockOutAlive.exe. No Godot installation needed.
- **ClockOutAlive-Godot.zip**: editable project, original asset source, tests, and export presets. Import project.godot in Godot 4.7.1 and press F5.
- **ClockOutAlive-Web.zip**: exported site for any static HTTP host. Open through a server, not file://.
- **SHA256SUMS.txt**: checksums for the three archives.

## Validation and limits

1,843 automated assertions pass across gameplay, full-shift input, integration, and layout checks. Native Compatibility-renderer captures cover the menu, next-challenge card, clipboard, and both endings. Browser mouse/keyboard and release loading are checked separately.

Desktop keyboard and mouse are required. Touch controls are not implemented. The 9:23 reference run is simulated with reading time, not a timed human playthrough. Six hours of active development were not reliably recorded and are not claimed.
