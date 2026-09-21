# Original artwork and audio

Every image and sound distributed in `assets/art` and `assets/audio` was created specifically for **CLOCK OUT ALIVE: THE GRAVEYARD SHIFT**. No stock artwork, downloaded audio samples, icon packs, 3D models, or generative-image outputs were used.

## Raster artwork

The artwork was constructed with original, individually specified Pillow raster drawing commands: flat polygons, uneven line segments, hard-edged brush marks, a custom stroke-lettering alphabet, and low-resolution silhouettes. MS Paint was not used; the accessible rendering tool was Pillow. The artwork is intended to resemble an intentionally rough Microsoft Paint illustration, without claiming that it was painted in that application.

The authoring source is `source_art/create_assets.py`. It keeps the original shape coordinates, custom lettering strokes, restrained shared palette, and deterministic mark placements. Individual source PNGs and separate scene layers are preserved in `source_art/layers`, independently of the imported runtime PNGs in `assets/art`. `source_art/art_manifest.json` lists dimensions and paths.

The original scenes include the rainy store exterior, the store interior, a dawn exterior with former employees waving behind the glass, and an employee noticeboard. Original transparent artwork covers the logo, clipboard, note, button, safety shield, cursor, checkout, scanner, four products, shelves, freezer, customer, employee, monster, rat, mop, breaker, door, telephone, and CCTV monitor. Semantic aliases for loading, the noticeboard, and an anomaly reuse those original source images.

## Synthesized audio

All WAV files are original oscillator/noise synthesis recipes in the same source script. They do not contain recordings of voices or third-party music. Each file is mono, 16-bit PCM, 22,050 Hz.

| File | Original synthesis |
| --- | --- |
| rain.wav | Filtered pseudorandom noise and small transient droplets |
| hum.wav | Modulated refrigerator fundamental and harmonic |
| buzz.wav | Fluorescent electrical harmonics and light noise |
| music.wav | Sparse, original four-chord detuned electric-piano phrase |
| tension.wav | Slowly beating sub-bass oscillators |
| scanner.wav | Short electronic checkout tone |
| footstep.wav | Low filtered impact noise and damped thump |
| breaker.wav | Short switch-click noise and damped metallic resonance |
| phone.wav | Pulsed telephone-ringer oscillators |
| bang.wav | Low door-panel resonance with impact noise |
| scrape.wav | Rough filtered noise and a wavering metallic tone |
| breath.wav | Slowly enveloped filtered noise |
| paper.wav | Modulated high-frequency noise rustle |
| printer.wav | Mechanical pulse train, noise, and motor tones |
| success.wav | Brief ascending three-note phrase |
| failure.wav | Brief descending three-note phrase |
| winner.wav | Original five-note completion phrase |
| death.wav | Falling low tone, dissonant harmonic, and noise |

Duration and sample-format details are in `source_art/audio_manifest.json`. Rain, hum, buzz, music, and tension are designed as repeating ambience beds; the runtime controls their levels and playback.

## AI usage disclosure

An AI coding assistant authored the GDScript, supporting code, raster drawing instructions, custom lettering coordinates, and synthesis recipes. This is code-authored original artwork, not finished artwork obtained from an image-generation model. No human drawing-session claim or MS Paint provenance is made.

## Recreate and edit

Install Python, Pillow, and NumPy, then run from the project directory:

```text
python source_art/create_assets.py
```

This rebuilds the PNGs, WAVs, preserved source PNGs, and manifests. Edit coordinates, palette constants, sound envelopes, or note frequencies in the script to modify the assets. All randomness is seeded for repeatable output.
