# DON'T LOOK BACK — Gameplay Canon v0.58

Dokumen ini adalah arah gameplay utama untuk runtime Ranger-first. Jika dokumen lama atau catatan versi lama bertentangan dengan file ini dan runtime aktif, gunakan canon ini.

## Premis utama

Player adalah seorang ranger yang menyelidiki hilangnya tim survey di wilayah hutan terpencil. Ranger Cabin menjadi base operasi pertama. Investigasi di permukaan membuka jejak menuju Old Mine, kemudian fasilitas bawah tanah Level 03 / Labyrinth, lalu Restricted Research Facility.

Game bukan cerita tentang menemukan satu pintu keluar. Player bertahan hidup agar bisa terus mengumpulkan bukti, memahami fenomena, dan membuka jaringan lokasi anomali yang lebih besar.

## Loop utama

**Prepare → Investigate → Expose yourself to danger → Recover evidence/resources → Survive encounter → Unlock deeper anomaly.**

Setiap sistem survival harus mendukung keputusan horror. Jika sebuah sistem hanya menambah pekerjaan administratif tanpa menambah risiko, pilihan, atau tension, sistem tersebut harus disederhanakan.

---

# 1. RANGER FOREST — BASE + INVESTIGATION

Forest adalah titik awal campaign aktif dan base survival utama.

### Tujuan awal

- stabilkan Ranger Cabin;
- kelola generator/campfire;
- cari food, water, medicine, battery, fuel, dan material;
- pahami weather/night pressure;
- selidiki hilangnya survey team.

### Jalur bukti v0.58

Opening tidak lagi harus sepenuhnya linear:

1. Abandoned House → Survey Manifest
2. Old Gas Station → Radio Trace
3. kedua bukti di atas dapat ditemukan dalam urutan berbeda
4. Ranger Case Board → sintesis Manifest + Radio Trace
5. Warehouse → Maintenance Map
6. Water Pump → optional anomaly evidence
7. Old Mine unlocked setelah clue synthesis + Maintenance Map

### Aturan investigation

- mengumpulkan bukti tidak sama dengan memahami bukti;
- clue penting boleh memerlukan synthesis/cross-check;
- optional evidence harus memberi manfaat gameplay nyata, bukan hanya teks Journal;
- multiplayer host memvalidasi scene, physical target, state, dan distance sebelum shared progression berubah.

Water Sample tetap opsional, tetapi v0.58 memberi manfaat nyata: stabilized emergency light di Mine junction.

### Aturan horror

Safe space tidak permanen. Ranger Yard hanya mendapat perlindungan penuh ketika generator hidup atau campfire masih menyala. Kehabisan fuel berarti base dapat kembali terekspos.

---

# 2. OLD MINE — DESCENT + LIGHT ALLOCATION

Mine adalah jembatan antara kasus permukaan dan fasilitas bawah tanah.

### Jalur bukti

1. Foreman's Log
2. Sealed Shaft Report
3. Facility Access Badge
4. Gate menuju Level 03 / Labyrinth

### Signature rule v0.58

Mine mempunyai shared support-power routing:

- UPPER SHAFT circuit menerangi bagian awal;
- DEEP SHAFT circuit menerangi bagian bawah;
- hanya satu main circuit aktif pada satu waktu;
- routing station tersedia di entrance dan junction;
- dalam co-op, pilihan circuit adalah shared host-authoritative world state;
- Water Sample optional evidence mengaktifkan stabilized junction light yang tetap menyala di antara kedua circuit.

Tujuannya adalah membuat traversal Mine menjadi keputusan light allocation, bukan hanya koridor evidence.

Mine harus terasa lebih sempit, industrial, dan tidak stabil daripada Forest. Resource run tetap penting, tetapi tujuan utamanya adalah investigasi dan descent.

---

# 3. LABYRINTH / FACILITY LEVEL 03

Labyrinth adalah fasilitas horror utama, bukan titik awal campaign saat ini.

### Tujuan

- aktifkan emergency relays;
- pulihkan sistem Maintenance/Flooded/Archive;
- temukan hubungan T-03 dengan kasus survey;
- kelola Darkness Exposure dan panic;
- survive Lockdown;
- bawa data menuju Restricted Research Facility.

### Prinsip desain

Labyrinth harus membuat player takut bergerak cepat sekaligus takut terlalu lama diam. Cahaya, panic, orientasi, stamina, dan suara harus saling menekan.

Objective maintenance tidak boleh berhenti pada checklist tombol. Iterasi berikutnya harus membuat setiap stage mengubah rule bermain: visibility, sound masking, team split, route safety, atau threat pressure.

---

# 4. RESTRICTED RESEARCH FACILITY

Facility berfungsi sebagai node investigasi yang menunjukkan bahwa kasus ini lebih besar daripada satu Forest/Mine/Labyrinth.

### Tujuan

- inspect routing terminal;
- hubungkan data T-03 dengan insiden lain;
- buka daftar ekspedisi masa depan.

Potential future routes:

- Hospital
- Museum
- Laboratory
- Cave
- other Labyrinth/anomaly nodes

Lokasi baru tidak boleh ditambahkan hanya untuk memperbesar map. Setiap ekspedisi harus memberi jawaban baru, aturan horror baru, atau keputusan survival baru.

Sebelum major map baru, Research Facility sebaiknya menerima payoff encounter/choice agar campaign tidak berakhir sebagai sekadar “coming soon terminal”.

---

# 5. SURVIVAL RULE

Survival adalah tekanan yang memperkuat horror.

Current / intended pressure includes:

- Health
- Hunger
- Thirst
- Stamina
- Panic
- Darkness Exposure
- Temperature / Cold
- Bleeding
- Infection
- Weather
- Generator/campfire upkeep
- Hunting/fishing/resource economy

### Hierarki tekanan

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

Background survival tidak boleh menutupi horror utama dengan terlalu banyak administrasi HUD.

### Vulnerable consumables v0.58

FOOD/WATER/MED bukan lagi instant resolution dari normal gameplay input.

- Food: sekitar 2.0 detik
- Water: sekitar 1.4 detik
- Medkit: sekitar 3.5 detik

Player berhenti bergerak selama channel. Damage, downed/death, player replacement, atau kehilangan footing membatalkan action. Item baru dikonsumsi ketika action selesai.

Prinsip: memakai supply harus menjadi keputusan timing dan vulnerability.

### Contoh keputusan horror yang benar

- Fishing membuat player diam dan terekspos.
- Hunting/harvesting menghasilkan noise.
- Generator membutuhkan fuel sehingga player harus meninggalkan base.
- Medkit/bandage membutuhkan waktu dan menciptakan vulnerability.
- Crafting dilakukan saat player memilih berhenti bergerak.
- Resource bernilai ditempatkan di luar protected light.
- Mine support power memaksa player memilih area mana yang lebih aman untuk diterangi.

### Yang harus dihindari

- grind tanpa risiko;
- crafting tree besar yang tidak mengubah keputusan horror;
- resource management yang hanya menjadi spreadsheet;
- monster HP scaling sebagai pengganti co-op tension.

---

# 6. MONSTER IDENTITIES

## The Tenant

Identity: **panic + observation**.

- Stillness dapat memicu kemunculannya.
- Gerakan/look agresif menaikkan panic.
- Panic meningkatkan pressure pursuit/attack.
- Watched/freeze rule harus tetap terbaca.
- Flashlight dapat digunakan untuk banish setelah continuous contact yang valid.

Tenant tidak boleh berubah menjadi generic sprinting enemy.

## Darkness Creature

Identity: **fear of losing light**.

- Darkness Exposure dan area tanpa protective light memicu ancaman.
- Cahaya adalah counter utama.
- Creature harus terlihat dan terdengar berbeda dari Tenant.

## Ancaman lain

Warden/Mourner/Crawler/hazard boleh tetap memiliki aturan masing-masing, tetapi major encounter harus tunduk pada pacing horror global agar beberapa subsystem tidak menghasilkan spike bersamaan tanpa recovery.

---

# 7. HORROR PACING

v0.58 mulai menerapkan high-level threat budget untuk major co-op Tenant/Darkness encounters.

Current principle:

- hanya satu major co-op threat mendapat budget penuh pada satu waktu;
- setelah encounter selesai ada RECOVERY window;
- pacing system tidak mengatur pathfinding/motor/combat AI;
- subsystem kecil masih boleh memberi ambience/pressure selama RECOVERY, tetapi major encounter baru tidak langsung menumpuk.

Target pacing states tetap:

- CALM
- UNEASE
- STALK
- THREAT
- HUNT
- RECOVERY

Setelah chase/lockdown/major hit, player membutuhkan recovery window. Horror yang terus menerus aktif kehilangan kekuatan.

Solo integration dengan budget yang sama masih follow-up.

---

# 8. CO-OP CANON

Target party: **2–4 survivors**.

Co-op harus menambah keputusan, bukan hanya menaikkan monster HP.

### 2 player

- classic coordination;
- revive pressure;
- limited simultaneous objectives.

### 3 player

- lebih banyak target switching;
- separation pressure;
- resource demand meningkat.

### 4 player

- multi-location decisions;
- secondary pressure;
- regroup decisions;
- resource scaling agar survival tetap playable.

Mine power routing v0.58 adalah contoh shared co-op decision: satu circuit aktif memengaruhi seluruh tim.

World/objective/monster state yang penting harus host-authoritative. Client boleh meminta interaction, tetapi host harus memvalidasi scene, target, distance, state, dan ownership sebelum world state berubah.

---

# 9. INPUT / PLATFORM CANON

Game harus playable pada:

- Desktop keyboard/mouse
- Native Android touch
- Web demo where supported

UI harus responsive terhadap ukuran viewport.

`GameplayInputLock` adalah sumber utama block state. v0.58 memperluas efek lock ke:

- movement;
- desktop camera / legacy action input;
- mobile movement;
- mobile look;
- mobile gameplay action buttons;
- temporary vulnerable consumable action.

Gameplay menu tidak boleh membiarkan gameplay action “tembus” di belakang UI.

Mobile performance target minimum: stable 30 FPS pada target hardware yang realistis. Desktop target normal: 60 FPS.

---

# 10. PRODUCTION PRIORITY

Setelah v0.58, urutan prioritas:

1. checkpoint/finite-loot consistency;
2. server-authoritative shared shelter inventory;
3. native platform export + CI smoke tests;
4. automated gameplay/co-op regression tests;
5. solo horror pacing integration;
6. Labyrinth rule-depth pass;
7. 3–4 player split/regroup objective scaling;
8. Research Facility payoff encounter/choice;
9. monster ownership cleanup;
10. LightRegistry / authored protection volumes;
11. production assets;
12. content expansion.

Gameplay foundation harus stabil dan dalam sebelum breadth bertambah.

---

# 11. ASSET POLICY

Setiap update harus mencatat:

- New required assets
- New recommended assets
- Existing pending assets
- Status: available / prototype / missing

v0.58 tidak membutuhkan mandatory production asset baru. New recommended production needs mencakup consumable-use animation/audio, Ranger Case Board synthesis presentation, Mine power-routing consoles/fixtures/audio, stabilized junction-light presentation, dan subtle recovery ambience.

Lihat `ASSET_DELTA_V058_GAMEPLAY_DEPTH.md` dan `ASSET_BACKLOG.md`.
