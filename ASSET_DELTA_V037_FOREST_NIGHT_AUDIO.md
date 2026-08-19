# Asset Delta — v0.37 Forest Night Audio

## Asset wajib baru

P0 — `res://assets/audio/forest_night.mp3`

- Format: MP3 yang dapat di-import Godot 4.
- Fungsi: ambience malam khusus scene Forest.
- Runtime window: 20:00 sampai sebelum 05:00 waktu in-game.
- Fade-in: 2 detik.
- Fade-out: 2 detik.
- Loop: aktif selama window malam.
- Playback: layer terpisah; background music yang sudah ada tidak di-pause, tidak dihentikan, dan tidak di-duck oleh sistem ini.

## Mixing

Runtime target volume ambience malam: -7 dB. Ini dapat diubah kemudian setelah balancing audio di perangkat desktop dan mobile.

## Tidak berubah

Tidak ada kebutuhan model, texture, animation, UI, atau VFX baru dari update ini.

## Testing

- Masuk Forest sebelum 20:00: Forest Night tidak terdengar.
- Melewati 20:00: fade-in berlangsung sekitar 2 detik.
- Antara 20:00–04:59: track loop terus.
- Melewati 05:00: fade-out berlangsung sekitar 2 detik lalu player ambience stop.
- Pindah dari Forest saat malam: fade-out 2 detik.
- BGM existing harus terus terdengar tanpa pause selama ambience Forest Night aktif.
