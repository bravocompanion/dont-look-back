# Asset Delta — Narrative Lore & Living World

## Update
Game sekarang memiliki narrative layer yang memberi konteks, arahan scene, ambient flavor, lore discovery, dan death recap yang lebih detail.

## Sistem baru
- `scripts/narrative_lore_system.gd`
  - chapter card ketika masuk bab/area baru;
  - objective hint singkat tanpa menggantikan gameplay logic;
  - ambient narrative lines berkala agar dunia terasa hidup;
  - lore otomatis masuk ke Journal saat bab ditemukan;
  - death screen diperluas dengan cerita kematian, lokasi, kondisi survival, catatan penyebab, dan saran percobaan berikutnya;
  - layout responsive untuk mobile dan desktop.
- `scripts/journal_system_v19.gd`
  - mission guide per bab sekarang memiliki Tujuan Utama, Langkah, Risiko, dan Kenapa;
  - menambahkan lore premise, creature rules, dan route overview.
- `scripts/survival_system.gd`
  - memasang `NarrativeLoreRuntime` tanpa perubahan `project.godot`.

## Bab/area yang sekarang memiliki briefing detail
1. Apartment 03 / opening corridor
2. Lower Labyrinth / emergency relays
3. Emergency Gate
4. Arc 1 — Maintenance Wing
5. Arc 1 — Flooded Service
6. Arc 1 — Archive
7. Arc 1 — Lockdown preparation
8. Arc 1 — Lockdown holdout
9. Labyrinth final exit
10. The Outside arrival
11. Cabin / shelter without power
12. Daylight exploration window
13. Abandoned Region (gas station / warehouse / ruins / water route)
14. Night Cycle

## Death feedback
Death screen sekarang menggunakan penyebab kematian untuk membuat catatan akhir khusus, termasuk:
- The Tenant
- Darkness
- The Mourner
- The Crawler
- Warden
- Bleeding
- Infection
- Dehydration
- Starvation
- Cold / exposure
- fallback untuk penyebab lain

Death recap juga menampilkan Panic, Battery, Hunger, Thirst, Bleeding, Infection, lokasi/bab, dan waktu/hari ketika berada di The Outside.

## Asset wajib setelah update
**Tidak ada asset wajib baru.** Sistem narrative menggunakan UI procedural dan teks sehingga bisa langsung berjalan di Godot.

## Asset optional untuk membuat dunia lebih hidup lagi
### P1 — sangat direkomendasikan
- `assets/audio/voice/radio_evacuation_01.ogg` — siaran evakuasi terakhir.
- `assets/audio/voice/maintenance_log_0313.ogg` — rekaman maintenance sebelum insiden.
- `assets/audio/voice/cabin_owner_log_01.ogg` — voice log pemilik cabin.
- `assets/audio/ambient/whisper_distant_01.ogg` sampai `03.ogg` — bisikan jauh yang sangat halus.
- `assets/audio/ambient/radio_static_burst_01.ogg` — static pendek untuk lore event.
- `assets/audio/ambient/pipe_knock_01.ogg` — ketukan pipa labyrinth.
- `assets/audio/ambient/warehouse_metal_shift_01.ogg` — suara logam warehouse.

### P2 — environmental storytelling
- Kertas laporan Apartment 03.
- Blueprint fasilitas bawah tanah dengan cap `VOID`.
- Folder Archive `SUBJECT T-03`.
- Lockdown order sheet bertanda waktu `03:13`.
- Poster emergency: `KEEP LIGHTS OVERLAPPING`.
- Foto kru maintenance dengan satu wajah dicoret.
- Radio tua untuk cabin dan gas station.
- Papan warehouse dengan warning tulisan tangan.

### P3 — death presentation polish
- Vignette / film grain texture untuk death screen.
- Low heartbeat / tinnitus SFX saat death recap muncul.
- 2–3 sting audio berbeda untuk death karena creature, survival condition, dan darkness.

Semua asset optional harus ringan untuk mobile. Audio mono/ogg dan texture UI kecil lebih diprioritaskan daripada video/cutscene besar.
