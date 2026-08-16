# Asset Delta v0.24.2 — Panic-Driven Tenant

Update ini tidak membutuhkan model monster baru, tetapi The Tenant sekarang mempunyai mechanic movement-panic dan flashlight banish yang membutuhkan production polish tambahan.

## P0 — Tenant animation / presentation

Tambahan yang dibutuhkan untuk final production Tenant:

- idle/freeze pose yang tetap readable saat player menatap Tenant
- low-panic stalk locomotion untuk sekitar 1.65 m/s
- medium-panic locomotion blend untuk sekitar 2.3 m/s
- high-panic chase locomotion untuk sampai sekitar 3.0 m/s
- attack animation yang dapat mengikuti cooldown dari 2.40 s sampai minimum sekitar 1.05 s
- attack recovery pendek untuk panic tinggi
- near-player emergence / materialize animation untuk spawn setelah player diam 2 detik
- flashlight-hit reaction loop selama beam ditahan
- 3-second banish / dissolve / distortion animation

## P0 — Tenant VFX

- subtle appearance distortion saat muncul sekitar 4.2 m dari player
- light-reactive surface/edge response ketika flashlight mengenai Tenant
- intensitas reaction yang meningkat selama 0–3 detik flashlight hold
- final dissolve/pop-out effect pada 3 detik
- low-overdraw mobile version

## P0 — Tenant audio

Recommended new layers:

- near-player emergence sting
- low/medium/high panic footstep cadence variants
- panic-scaled breathing/body-creak loop
- attack swing/impact variants yang cocok dengan attack cadence cepat
- flashlight burn/interference layer khusus Tenant
- 3-second banish release/dissolve sound

`battery.mp3` tetap dipakai sebagai generic flashlight-monster interference dari v0.24.1, jadi tidak wajib membuat file battery baru.

## P1 — Panic feedback

Optional UI/audio polish:

- subtle PANIC meter pulse at 50%+
- stronger pulse at 75%+
- restrained heartbeat/breath layer driven by movement panic
- small warning tick when panic crosses 75% / 100%
- do not add constant loud alarm; player still needs to hear monster proximity and footsteps

## Mobile / desktop constraints

- high-panic attack animation harus tetap terbaca pada 30 FPS mobile
- emergence/banish VFX harus punya low-overdraw version
- no required volumetric effect
- animation root motion should not fight host-authoritative navigation
- Tenant movement speed remains code-driven; animation playback speed may adapt visually but must not drive network position
- flashlight reaction must remain readable at low phone brightness

## Existing assets retained

No replacement required for:

- `music.*`
- `hurt.*`
- `monster.*`
- `battery.mp3`
- existing flashlight model backlog
- existing Tenant production model requirement

## Recommended production order after v0.24.2

1. Tenant emergence + banish animation/VFX
2. Tenant locomotion blend across panic levels
3. Tenant attack/recovery variants for 1.05–2.40 s cadence
4. Tenant flashlight reaction audio
5. panic HUD pulse/heartbeat polish
6. continue existing Warden/environment/flashlight production backlog
