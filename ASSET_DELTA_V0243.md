# Asset Delta v0.24.3 — Tenant Flashlight Kill Feedback

v0.24.3 menambah feedback khusus ketika flashlight mengenai The Tenant dan ketika Tenant berhasil dihilangkan setelah continuous flashlight hold 3 detik.

## P0 — audio wajib

Asset audio yang dipakai mechanic ini:

- `baterai.mp3` — flashlight/monster electrical interference; nama utama yang dipakai project.
- `tenant death` — one-shot ketika Tenant berhasil dihilangkan oleh flashlight 3 detik.

Runtime resolver memprioritaskan `baterai` untuk interference. Alias `battery` tetap diterima hanya sebagai fallback kompatibilitas agar file lama tidak langsung rusak.

Resolver menerima `.wav`, `.ogg`, atau `.mp3` dan menormalkan spasi, underscore, dan dash. Contoh nama Tenant death yang valid:

- `assets/tenant death.mp3`
- `assets/tenant_death.mp3`
- `assets/tenant-death.ogg`
- `assets/tenantdeath.wav`
- nama lebih panjang yang masih mengandung `tenantdeath` setelah normalisasi.

Rekomendasi produksi:

- death cue pendek dan jelas sebagai death/banish confirmation
- jangan terlalu panjang agar tidak menutupi monster proximity atau objective audio
- hindari clipping pada speaker HP
- peak boleh lebih kuat daripada `baterai.mp3`, tetapi tetap mengikuti Master Volume

## Existing audio retained

- `music.*` — gameplay BGM
- `hurt.*` — damage reaction
- `monster.*` — proximity threat layer
- `baterai.mp3` — flashlight/monster electrical interference

`baterai.mp3` tetap berlaku pada monster lain seperti mechanic v0.24.1. Saat beam mengenai Tenant, cue yang sama tetap aktif dan pitch/volume dapat meningkat mengikuti hold 0–3 detik.

## Tenant rapid flashlight flicker

Tidak membutuhkan texture/VFX baru untuk prototype. Runtime system memberi tambahan rapid modulation khusus Tenant:

- sekitar 8 Hz pada awal flashlight contact
- meningkat sampai sekitar 12 Hz mendekati 3 detik
- brightness tidak dipaksa benar-benar 0; minimum factor sekitar 0.22 pada puncak effect
- procedural flashlight sway dan generic monster interference tetap aktif
- system diproses setelah flashlight baseline/interference sehingga effect tidak tertimpa pada frame yang sama

Untuk production/accessibility pass berikutnya disarankan menambah opsi **Reduce Flashing** yang menurunkan frekuensi dan kedalaman flicker tanpa mengubah mechanic 3-second kill.

## Tenant death behavior

Death cue hanya dimaksudkan untuk Tenant yang hilang setelah flashlight hold hampir mencapai 3 detik. Scene transition atau Tenant yang berhenti karena state non-kill tidak seharusnya memainkan cue.

Solo:

- local 3-second flashlight banish memicu `tenant death` sekali.

Co-op:

- host mengawasi hold flashlight survivor
- host mengonfirmasi Tenant berubah active → inactive setelah kill-arm condition
- host memainkan death cue lokal dan mengirim reliable death-feedback RPC ke client
- setiap peer memainkan asset lokalnya satu kali

## Mobile / desktop

Tidak ada tombol baru. Mechanic sama pada desktop dan mobile.

Perlu diuji pada HP:

- rapid flicker tetap terbaca pada 30 FPS
- `baterai.mp3` dan `tenant death` tidak clipping pada speaker kecil
- death cue tidak tertutup BGM/proximity layer
- rapid flicker tidak membuat readability corridor terlalu buruk

## Test checklist

1. Sorot Tenant: `baterai.mp3` mulai terdengar.
2. Sorot monster lain: existing `baterai.mp3` interference tetap bekerja.
3. Sorot Tenant: flicker harus lebih cepat daripada generic monster flicker.
4. Lepas beam sebelum 3 detik: Tenant tetap hidup dan `tenant death` tidak berbunyi.
5. Tahan beam 3 detik: Tenant hilang dan `tenant death` berbunyi sekali.
6. Setelah death cue, `baterai.mp3` berhenti.
7. Tenant muncul lagi pada encounter berikutnya: death cue bisa dipicu lagi setelah kill berikutnya.
8. Pindah map ketika Tenant aktif: `tenant death` tidak boleh berbunyi hanya karena scene berubah.
9. Co-op host/client: satu Tenant kill menghasilkan satu death cue pada masing-masing peer.
10. Return to title: semua gameplay audio berhenti.

## Asset priority setelah update

P0 baru:

- final `tenant death` SFX

P0 retained:

- `baterai.mp3` interference cue
- final Tenant model/rig
- emergence animation
- low/medium/high panic locomotion
- fast attack/recovery variants
- flashlight reaction animation/VFX
- 3-second dissolve/banish VFX
- panic-scaled footsteps/breath/body-creak
- production flashlight/first-person hand rig

Tidak ada model, texture, atau material baru yang wajib hanya untuk menjalankan v0.24.3 prototype.
