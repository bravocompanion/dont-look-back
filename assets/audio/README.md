# Audio Assets

## Forest night ambience

Place the production MP3 at exactly:

`res://assets/audio/forest_night.mp3`

Runtime behavior is handled by `res://scripts/forest_night_audio_system.gd`:

- Forest scene only.
- Starts at in-game 20:00.
- Stops at in-game 05:00.
- 2 second fade-in.
- 2 second fade-out.
- Loops while the night window is active.
- Uses a separate `AudioStreamPlayer`; existing background music is not paused or stopped.
- Default mix target is -7 dB so the night layer can sit under/alongside the existing soundtrack.

## v0.49 bow / arrow audio

Place these production MP3 files at exactly:

- `res://assets/audio/draw.mp3`
- `res://assets/audio/shoot.mp3`
- `res://assets/audio/impact.mp3`

Runtime behavior is handled by `res://scripts/forest_survival_system_v49.gd`:

- `draw.mp3` starts once when a valid bow draw begins.
- The clip is not looped or retriggered while the mouse/touch button remains held.
- Playback speed is adjusted so one copy of `draw.mp3` lasts approximately the configured maximum draw duration (`bow_full_draw_seconds`, currently 1.35 s).
- Releasing early stops the remaining draw clip immediately.
- `shoot.mp3` plays once only after a valid arrow release actually consumes/fires an arrow.
- `impact.mp3` is emitted in 3D at the authoritative arrow impact point and is synchronized to connected peers.
- Runtime also checks `res://draw.mp3`, `res://shoot.mp3`, and `res://impact.mp3` as compatibility fallbacks.

The MP3 binaries themselves are intentionally not represented by placeholder text files. Add the actual licensed/source audio using the exact filenames above.
