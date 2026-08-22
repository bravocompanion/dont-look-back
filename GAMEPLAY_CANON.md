# DON'T LOOK BACK — Gameplay Canon v0.57

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

### Jalur bukti utama

1. Abandoned House → Survey Manifest
2. Old Gas Station → Radio Trace
3. Warehouse → Maintenance Map
4. Water Pump → optional anomaly evidence
5. Old Mine unlocked

### Aturan horror

Safe space tidak permanen. Ranger Yard hanya mendapat perlindungan penuh ketika generator hidup atau campfire masih menyala. Kehabisan fuel berarti base dapat kembali terekspos.

---

# 2. OLD MINE — DESCENT

Mine adalah jembatan antara kasus permukaan dan fasilitas bawah tanah.

### Jalur bukti

1. Foreman's Log
2. Sealed Shaft Report
3. Facility Access Badge
4. Gate menuju Level 03 / Labyrinth

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

### Contoh keputusan horror yang benar

- Fishing membuat player diam dan terekspos.
- Hunting/harvesting menghasilkan noise.
- Generator membutuhkan fuel sehingga player harus meninggalkan base.
- Medkit/bandage membutuhkan waktu dan menciptakan vulnerability.
- Crafting dilakukan saat player memilih berhenti bergerak.
- Resource bernilai ditempatkan di luar protected light.

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

Target jangka berikutnya adalah high-level threat budget, bukan AI super-controller.

Suggested pacing states:

- CALM
- UNEASE
- STALK
- THREAT
- HUNT
- RECOVERY

Setelah chase/lockdown/major hit, player membutuhkan recovery window. Horror yang terus menerus aktif kehilangan kekuatan.

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

World/objective/monster state yang penting harus host-authoritative. Client boleh meminta interaction, tetapi host harus memvalidasi scene, target, distance, state, dan ownership sebelum world state berubah.

---

# 9. INPUT / PLATFORM CANON

Game harus playable pada:

- Desktop keyboard/mouse
- Native Android touch
- Web demo where supported

UI harus responsive terhadap ukuran viewport. Gameplay menu yang memblokir kontrol harus menggunakan `GameplayInputLock` atau abstraction yang sama, bukan menambahkan dependency menu khusus ke MovementSystem satu per satu.

Mobile performance target minimum: stable 30 FPS pada target hardware yang realistis. Desktop target normal: 60 FPS.

---

# 10. PRODUCTION PRIORITY

Sebelum map/monster besar berikutnya:

1. multiplayer authority;
2. save/checkpoint/finite-loot consistency;
3. input ownership;
4. native platform export + CI smoke tests;
5. mobile performance;
6. monster ownership cleanup;
7. horror pacing;
8. production assets;
9. content expansion.

Gameplay foundation harus stabil sebelum breadth bertambah.

---

# 11. ASSET POLICY

Setiap update harus mencatat:

- New required assets
- New recommended assets
- Existing pending assets
- Status: available / prototype / missing

v0.57 sendiri tidak membutuhkan asset production baru; update ini berfokus pada stability dan authority. Lihat `ASSET_DELTA_V057_STABILITY_AUTHORITY.md`.
