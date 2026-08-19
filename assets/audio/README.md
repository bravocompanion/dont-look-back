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

The MP3 binary itself is intentionally not represented by a placeholder text file. Add the actual licensed/source audio using the exact filename above.
