# DON'T LOOK BACK — Gameplay Canon v0.59

Dokumen ini adalah arah gameplay utama untuk runtime Ranger-first. Jika dokumen lama bertentangan dengan file ini dan runtime aktif, gunakan canon ini.

## Premis utama

Player adalah ranger yang menyelidiki hilangnya tim survey di hutan terpencil. Ranger Cabin menjadi base operasi pertama. Investigasi permukaan membuka Old Mine, kemudian Facility Level 03 / Labyrinth, lalu Restricted Research Facility.

## Loop utama

**Prepare → Investigate → Expose yourself to danger → Recover evidence/resources → Survive encounter → Unlock deeper anomaly.**

Survival harus memperkuat keputusan horror. Sistem yang hanya menambah administrasi tanpa risiko, pilihan, atau tension harus disederhanakan.

---

# 1. RANGER FOREST — BASE + INVESTIGATION

Opening investigation:

1. Abandoned House → Survey Manifest
2. Old Gas Station → Radio Trace
3. kedua clue dapat ditemukan dalam urutan berbeda
4. Ranger Case Board → synthesis Manifest + Radio Trace
5. Warehouse → Maintenance Map
6. Water Pump → optional anomaly evidence
7. Old Mine terbuka setelah clue synthesis + Maintenance Map

Aturan investigation:

- mengumpulkan evidence tidak sama dengan memahami evidence;
- clue penting boleh membutuhkan synthesis/cross-check;
- optional evidence harus memberi manfaat gameplay;
- host memvalidasi scene, target fisik, state, dan distance sebelum shared progression berubah.

Water Sample tetap opsional tetapi memberi stabilized emergency light di Mine junction.

Ranger Yard bukan safe zone permanen. Perlindungan penuh hanya ada saat generator hidup atau campfire masih menyala.

---

# 2. OLD MINE — DESCENT + LIGHT ALLOCATION

Jalur bukti:

1. Foreman's Log
2. Sealed Shaft Report
3. Facility Access Badge
4. Gate menuju Level 03 / Labyrinth

Signature rule:

- UPPER SHAFT circuit menerangi bagian awal;
- DEEP SHAFT circuit menerangi bagian bawah;
- hanya satu main circuit aktif;
- routing station tersedia di entrance dan junction;
- pilihan circuit shared dan host-authoritative di co-op;
- Water Sample mengaktifkan stabilized junction light tambahan.

Mine harus terasa lebih sempit, industrial, dan tidak stabil daripada Forest.

---

# 3. LABYRINTH / FACILITY LEVEL 03

Tujuan:

- aktifkan emergency relays;
- pulihkan Maintenance/Flooded/Archive;
- temukan data T-03;
- kelola Darkness Exposure dan panic;
- survive Lockdown;
- bawa data menuju Restricted Research Facility.

Labyrinth harus membuat player takut bergerak cepat sekaligus takut terlalu lama diam. Cahaya, panic, stamina, orientasi, dan suara saling menekan.

Maintenance objective tidak boleh berhenti sebagai checklist tombol. Iterasi berikutnya harus membuat stage mengubah rule bermain: visibility, sound masking, team split, route safety, atau threat pressure.

---

# 4. CHECKPOINT / DEATH CANON — v0.59

Checkpoint adalah **time snapshot**, bukan hanya titik teleport.

Saat checkpoint aktif, snapshot menyimpan state yang dibutuhkan agar rollback konsisten:

- transform checkpoint;
- inventory dan survival state masing-masing survivor;
- finite-pickup claims;
- investigation/evidence progression;
- Labyrinth Arc 1 progression;
- shelter/generator/campfire/storage;
- renewable/radiation state yang sudah dimiliki SaveSystem;
- Mine UPPER/DEEP power-routing state;
- Journal/world save data yang relevan.

### Aturan rollback

Jika solo player mati atau seluruh party wipe:

1. current scene reload;
2. shared world kembali ke snapshot checkpoint;
3. setiap survivor kembali ke inventory/stats checkpoint miliknya;
4. supply yang diambil **setelah** checkpoint muncul kembali;
5. supply yang sudah diambil **sebelum** checkpoint tetap hilang;
6. objective yang diselesaikan setelah checkpoint kembali belum selesai;
7. Mine/support/world state kembali ke state checkpoint;
8. major horror mendapat recovery singkat setelah restore.

Dengan model ini, finite loot tidak boleh terduplikasi dan tidak boleh hilang tanpa kembali ke inventory.

### Aturan map transition

Pindah map normal **tidak** memicu checkpoint restore dan tidak boleh menarik player kembali ke checkpoint map lama.

### Save/load

Checkpoint snapshot ikut disimpan ke persistent save. Save lama tanpa snapshot v0.59 menggunakan best-effort migration dari world state yang berhasil dimuat.

---

# 5. RESTRICTED RESEARCH FACILITY

Facility menunjukkan bahwa kasus lebih besar daripada Forest/Mine/Labyrinth.

Tujuan saat ini:

- inspect routing terminal;
- hubungkan data T-03 dengan insiden lain;
- buka daftar ekspedisi masa depan.

Potential future routes:

- Hospital
- Museum
- Laboratory
- Cave
- other Labyrinth/anomaly nodes

Sebelum major map baru, Facility sebaiknya menerima payoff encounter/choice agar campaign tidak berakhir hanya sebagai “coming soon terminal”.

---

# 6. SURVIVAL RULE

Primary horror resources:

- Health
- Flashlight Battery
- Darkness Exposure
- Panic

Secondary expedition pressure:

- Stamina
- Bleeding
- Temperature
- Radiation

Background survival:

- Hunger
- Thirst
- Infection

FOOD/WATER/MED adalah vulnerable actions, bukan instant resolution:

- Food sekitar 2.0 detik
- Water sekitar 1.4 detik
- Medkit sekitar 3.5 detik

Player berhenti bergerak selama channel. Damage/downed/death/invalid footing membatalkan action dan item hanya dikonsumsi saat action selesai.

Contoh keputusan horror yang benar:

- fishing membuat player diam dan terekspos;
- hunting/harvesting menghasilkan noise;
- generator memaksa fuel run;
- medkit menciptakan vulnerability;
- resource bernilai berada di luar protected light;
- Mine support power memaksa pilihan area terang;
- checkpoint menentukan seberapa jauh risiko expedition yang siap diulang jika gagal.

---

# 7. MONSTER IDENTITIES

## The Tenant

Identity: **panic + observation**.

- Stillness dapat memicu kemunculan.
- Gerakan/look agresif menaikkan panic.
- Watched/freeze rule harus terbaca.
- Flashlight continuous contact dapat banish.

Tenant tidak boleh menjadi generic chaser.

## Darkness Creature

Identity: **fear of losing light**.

- Darkness Exposure dan area tanpa protective light memicu ancaman.
- Cahaya adalah counter utama.
- Visual/audio harus berbeda jelas dari Tenant.

Warden/Mourner/Crawler/hazard tetap boleh punya rule sendiri, tetapi major encounter harus tunduk pada pacing global.

---

# 8. HORROR PACING

Current co-op rule:

- hanya satu major Tenant/Darkness threat mendapat full budget;
- selesai encounter menghasilkan RECOVERY window;
- checkpoint restore juga memberi short recovery agar monster tidak langsung respawn di atas survivor yang baru hidup;
- pacing system tidak mengatur navigation/motor/combat AI.

Target states:

- CALM
- UNEASE
- STALK
- THREAT
- HUNT
- RECOVERY

Solo integration lebih luas masih follow-up.

---

# 9. CO-OP CANON

Target party: **2–4 survivors**.

Co-op harus menambah keputusan, bukan hanya menaikkan monster HP.

### 2 player

- coordination;
- revive pressure;
- limited simultaneous objectives.

### 3 player

- target switching;
- separation pressure;
- resource demand meningkat.

### 4 player

- multi-location decisions;
- secondary pressure;
- regroup decisions;
- resource scaling agar survival tetap playable.

Checkpoint v0.59 adalah shared world snapshot, tetapi setiap peer menyimpan local survivor payload miliknya sendiri. Team wipe harus mengembalikan semua peer ke checkpoint yang sama tanpa menyalin inventory host ke client.

World/objective/monster state penting harus host-authoritative.

---

# 10. INPUT / PLATFORM CANON

Target:

- Desktop keyboard/mouse
- Native Android touch
- Web demo where supported

`GameplayInputLock` menjadi sumber block state untuk movement, desktop camera/actions, mobile movement/look/actions, dan vulnerable actions.

Mobile target minimum: stable 30 FPS pada target hardware realistis. Desktop target normal: 60 FPS.

---

# 11. PRODUCTION PRIORITY SETELAH v0.59

1. manual real-device + 2–4 player checkpoint regression validation;
2. server-authoritative shared shelter inventory;
3. Android + Windows/Linux export presets dan CI smoke build;
4. automated save/checkpoint/co-op regression tests;
5. Labyrinth rule-depth pass;
6. solo horror pacing integration;
7. 3–4 player split/regroup objective scaling;
8. Research Facility payoff encounter/choice;
9. monster ownership cleanup;
10. LightRegistry / authored protection volumes;
11. Reduce Flashing;
12. production assets;
13. content expansion.

Jangan menambah major map baru sebelum fail-state, platform, dan regression foundation cukup stabil.

---

# 12. ASSET POLICY

Setiap update harus mencatat:

- New required assets
- New recommended assets
- Existing pending assets
- Status: available / prototype / missing

v0.59 membutuhkan **0 mandatory production asset**. Recommended polish: checkpoint activation sting, checkpoint pulse, wipe/restore ambience, checkpoint-restored icon, dan synchronized co-op confirmation cue.

Lihat `ASSET_DELTA_V059_CHECKPOINT_CONSISTENCY.md` dan `ASSET_BACKLOG.md`.
