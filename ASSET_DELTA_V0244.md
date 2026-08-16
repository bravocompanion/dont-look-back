# Asset Delta v0.24.4 — Tenant Beam Pursuit

v0.24.4 tidak menambah asset wajib baru untuk menjalankan prototype. Perubahan utamanya adalah logic movement Tenant saat terkena flashlight dan shock PANIC saat player terkena pukulan monster.

## P0 retained — Tenant presentation

Asset produksi yang sudah dibutuhkan sebelumnya tetap relevan, tetapi sekarang harus mendukung locomotion saat terkena beam:

- low-panic locomotion sekitar 1.65 m/s
- medium-panic locomotion sekitar 2.3 m/s
- high-panic locomotion sampai 3.0 m/s
- flashlight-hit locomotion/reaction blend pada sekitar 50% movement speed
- jangan membuat flashlight-hit animation mengunci root motion; navigation tetap code-driven
- 3-second burn/banish reaction
- death/dissolve VFX dan `tenant death` SFX

## P0 retained — audio

Tidak ada file audio baru wajib.

Tetap digunakan:

- `music.*` — BGM
- `hurt.*` — player hurt
- `monster.*` — proximity layer
- `baterai.mp3` — flashlight/monster interference, termasuk saat beam mengenai Tenant
- `tenant death.*` — one-shot saat Tenant berhasil dibanish

## P1 — panic hit feedback

Optional polish berikutnya:

- short heartbeat punch ketika monster hit memberi +40 PANIC
- restrained vignette/pulse pada sudden panic gain
- separate stronger feedback jika hit membuat PANIC mencapai 100
- mobile-safe haptic pulse optional

Jangan tambahkan flash layar berat karena Tenant flashlight interaction sudah memakai rapid flicker.

## Mobile / desktop constraints

- locomotion 50% speed harus tetap terlihat natural di 30 FPS mobile
- animation playback speed boleh menyesuaikan, tetapi position tetap dimiliki navigation
- rapid flashlight flicker tetap perlu Reduce Flashing accessibility pass
- panic hit feedback jangan menutupi `hurt` SFX atau `baterai.mp3`

## Asset status

**Asset baru wajib v0.24.4: tidak ada.**

Backlog aktif tetap: final Tenant model/rig, flashlight reaction, locomotion blends, attack/recovery, banish VFX, `tenant death`, survivor/monster production audio, dan mobile LOD.