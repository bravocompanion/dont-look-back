# DON'T LOOK BACK — Gameplay Canon v0.60

Dokumen ini adalah arah gameplay utama untuk runtime Ranger-first. Jika dokumen lama bertentangan dengan runtime aktif dan file ini, gunakan runtime + canon v0.60 sebagai sumber utama.

## Premis

Player adalah ranger yang menyelidiki hilangnya tim survey di hutan terpencil. Ranger Cabin menjadi base operasi. Jejak kasus membawa tim ke Old Mine, Facility Level 03 / Labyrinth, lalu Restricted Research Facility dan jaringan anomali yang lebih besar.

## Core loop

**Prepare → Investigate → Expose yourself to danger → Recover evidence/resources → Survive encounter → Unlock deeper anomaly.**

Setiap sistem survival harus menghasilkan keputusan horror. Jika hanya menambah administrasi, sistem harus disederhanakan.

---

# 1. RANGER FOREST — BASE + INVESTIGATION

Opening investigation:

1. Abandoned House → Survey Manifest
2. Old Gas Station → Radio Trace
3. kedua clue dapat ditemukan dalam urutan berbeda
4. Ranger Case Board → synthesis kedua clue
5. Warehouse → Maintenance Map
6. Water Pump → optional Water Sample
7. Old Mine terbuka setelah clue synthesis + Maintenance Map

Water Sample tetap optional tetapi memberi stabilized junction light di Mine.

Ranger Yard bukan safe zone permanen. Yard hanya protected jika generator hidup atau campfire masih menyala.

### v0.60 shelter authority rule

Dalam co-op, resource untuk shared shelter tidak boleh dikonsumsi client sebelum host menerima transaksi.

Flow canonical:

1. inventory mutation client dicerminkan ke host dengan revision berurutan;
2. client mengirim pending inventory diff sebelum shelter request;
3. host memvalidasi scene, target, jarak, downed state, world state, dan resource;
4. host mengurangi resource pada mirror inventory;
5. host mengubah shared generator/campfire state;
6. host mengirim authoritative item count kembali;
7. client mengoreksi inventory ke hasil host.

Target v0.60:

- generator fuel;
- campfire Firewood Bundle;
- campfire loose Wood;
- generator repair 2 Scrap + 1 Electronics.

Legacy shelter RPC yang dapat mengubah state tanpa resource transaction tidak boleh dipakai lagi.

Batas authority saat ini: initial inventory snapshot peer masih berasal dari peer tersebut. Jadi ini transaction authority untuk normal co-op clients, bukan competitive anti-cheat inventory server.

---

# 2. OLD MINE — DESCENT + LIGHT ALLOCATION

Evidence route:

1. Foreman's Log
2. Sealed Shaft Report
3. Facility Access Badge
4. Labyrinth gate

Mine signature rule:

- UPPER SHAFT circuit menerangi early shaft;
- DEEP SHAFT circuit menerangi lower route;
- hanya satu main circuit aktif;
- entrance + junction routing station dapat mengubah pilihan;
- state shared dan host-authoritative;
- Water Sample menjaga stabilized junction light tetap tersedia.

Mine harus terasa seperti transisi dari survival exploration ke fasilitas horror yang lebih mekanis.

---

# 3. LABYRINTH / FACILITY LEVEL 03

Tujuan:

- aktifkan emergency relays;
- pulihkan Maintenance/Flooded/Archive systems;
- pahami hubungan T-03 dengan kasus survey;
- survive Lockdown;
- lanjutkan data ke Restricted Research Facility.

Current Arc 1 memiliki fuse, valves, breaker sequence, alarm/fault pressure, checkpoints, enemies, dan 120-second Lockdown.

Next design rule: tiap stage Labyrinth harus mengubah cara bermain, bukan hanya mengganti checklist objective. Contoh perubahan rule: visibility, sound masking, split-team requirement, route safety, atau power allocation.

---

# 4. RESTRICTED RESEARCH FACILITY

Facility adalah investigation node yang menghubungkan kasus ini ke jaringan anomaly routes.

Future routes dapat mencakup:

- Hospital
- Museum
- Laboratory
- Cave
- other anomaly/Labyrinth nodes

Jangan membuka major map baru hanya untuk breadth. Facility terlebih dahulu membutuhkan payoff encounter/choice yang benar-benar menyelesaikan satu beat campaign.

---

# 5. SURVIVAL HIERARCHY

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

Background survival tidak boleh mengambil perhatian lebih besar daripada horror utama.

FOOD/WATER/MED adalah vulnerable timed actions. Item baru dikonsumsi saat action selesai. Menu/gameplay action menggunakan central input lock agar input tidak tembus di belakang UI.

---

# 6. MONSTER IDENTITIES

## The Tenant

Identity: **panic + observation**.

- stillness/panic dapat memicu kemunculan;
- watched/freeze harus tetap terbaca;
- panic menaikkan pursuit pressure;
- flashlight contact adalah counter/banish route.

Tenant tidak boleh menjadi generic chaser.

## Darkness Creature

Identity: **fear of losing protective light**.

- Darkness Exposure memicu pressure;
- protective light adalah counter utama;
- visual/audio/behavior harus berbeda jelas dari Tenant.

## Horror pacing

Major Tenant dan Darkness encounters menggunakan shared threat budget:

- satu major threat mendapatkan pressure penuh pada satu waktu;
- selesai encounter → RECOVERY;
- subsystem kecil boleh tetap memberi unease selama recovery;
- major chase baru tidak boleh langsung bertumpuk.

Target states:

CALM → UNEASE → STALK → THREAT → HUNT → RECOVERY

---

# 7. CHECKPOINT / FINITE LOOT CANON

Checkpoint adalah **time snapshot**, bukan hanya respawn transform.

Pada solo death atau co-op team wipe:

- scene reload;
- shared world rollback ke snapshot;
- masing-masing peer memulihkan inventory/stats miliknya sendiri;
- pre-checkpoint finite claim tetap claimed;
- post-checkpoint finite claim rollback dan pickup muncul kembali;
- inventory yang didapat setelah checkpoint juga rollback;
- investigation, shelter, Arc 1, Journal, Mine power, renewable/radiation state ikut konsisten.

Normal map transition tidak boleh memicu old checkpoint restore.

---

# 8. CO-OP CANON

Target party: **2–4 survivors**.

2 players:

- coordination + revive pressure;
- limited simultaneous objectives.

3 players:

- separation pressure;
- resource demand;
- lebih banyak simultaneous decision.

4 players:

- multi-location objective;
- split/regroup tension;
- rescue pressure;
- resource scaling agar tetap playable.

Difficulty tidak boleh diselesaikan dengan monster HP inflation.

Shared world/objective/monster/interactable state penting harus host-owned atau host-validated.

Current authority layers mencakup:

- remote movement sanity filter;
- evidence validation;
- finite pickup claim;
- relay validation;
- Mine power routing;
- main co-op monster state/damage;
- checkpoint/team-wipe world restore;
- v0.60 shelter resource transaction ordering.

---

# 9. PLATFORM / INPUT CANON

Game harus playable pada:

- Desktop keyboard/mouse
- Native Android touch
- Web demo where supported

Responsive target:

- viewport 1280×720;
- `canvas_items` stretch;
- `gl_compatibility` desktop/mobile;
- mobile target minimum stable 30 FPS pada hardware realistis;
- desktop target normal 60 FPS.

v0.60 committed export presets:

- Web
- Windows Desktop
- Linux Desktop
- Android Debug
- Android Release

Native CI harus boot canonical scenes sebelum build dan menghasilkan Linux release, Windows release, dan Android Debug APK. Android Release signing credential tidak boleh disimpan di repository.

---

# 10. REGRESSION POLICY

Mulai v0.60, update gameplay besar harus menjaga automated smoke berikut:

- Forest loads + player + shelter targets;
- Mine loads;
- Labyrinth loads + Arc 1 runtime;
- Research Facility loads;
- v0.59 checkpoint snapshot API tetap ada;
- Mine power persistence API tetap ada;
- v0.60 shelter authority API aktif;
- required export presets tersedia.

Regression smoke bukan pengganti manual co-op test. Manual matrix tetap wajib untuk:

- host + 1 client;
- host + 3 clients;
- team wipe;
- simultaneous interaction;
- network latency/race-sensitive shelter spending;
- Android touch + thermals/performance.

---

# 11. PRODUCTION PRIORITY AFTER v0.60

1. manual co-op verification untuk shelter authority;
2. remote Shared Stash transaction authority;
3. automated checkpoint/finite-loot transaction tests;
4. Android real-device profiling + safe-area polish;
5. deeper Labyrinth rule changes;
6. 3–4 player split/regroup objective design;
7. Research Facility payoff encounter/choice;
8. monster brain/navigation/motor/network consolidation;
9. LightRegistry / authored protection volumes;
10. production character/monster/environment/audio pass;
11. major content expansion.

---

# 12. ASSET POLICY

Setiap update harus mencatat:

- new required assets;
- new recommended assets;
- existing pending assets;
- status: available / prototype / missing.

v0.60 membutuhkan **0 mandatory runtime asset baru**.

Recommended baru:

- Android launcher/adaptive/monochrome icon set;
- Windows app `.ico`;
- Linux app icon;
- optional shelter transaction accepted/rejected feedback.

Lihat `ASSET_DELTA_V060_AUTHORITY_NATIVE_TESTS.md` dan `ASSET_BACKLOG.md`.
