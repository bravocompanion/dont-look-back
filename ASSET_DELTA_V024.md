# Asset Delta v0.24.1 — Dynamic Horror Audio + Flashlight Monster Interference

Update v0.24.1 mengubah fungsi `battery` audio. `battery.mp3` **tidak lagi digunakan sebagai low-battery warning**. Asset tersebut sekarang menjadi feedback khusus ketika flashlight beam benar-benar mengenai monster.

## P0 — audio yang harus tersedia di project

Sistem mencari file audio secara recursive di folder umum seperti `res://assets`, `res://audio`, `res://sounds`, `res://sfx`, dan `res://music` (termasuk variasi huruf besar). Format resolver: `.wav`, `.ogg`, `.mp3`.

Nama file boleh persis atau mengandung keyword berikut:

- `music` — background music gameplay. Contoh: `assets/music.ogg`, `assets/background_music.mp3`.
- `hurt` — one-shot ketika pemain menerima damage besar/serangan. Contoh: `assets/hurt.wav`, `assets/player_hurt.ogg`.
- `monster` — proximity threat layer. Contoh: `assets/monster.ogg`, `assets/monster_near.mp3`.
- `battery` — **flashlight/monster interference** ketika beam mengenai monster. Contoh utama: `assets/battery.mp3`.

Exact basename (`music`, `hurt`, `monster`, `battery`) mendapat prioritas sebelum partial-name match.

## Runtime use

### Music
- Gameplay BGM mulai saat masuk map gameplay.
- Berhenti saat kembali ke dedicated main menu.
- Jika audio selesai, diputar ulang sebagai background loop behavior.
- Base volume internal sekitar `-16 dB` sebelum Master Volume.
- Di-duck sampai sekitar `5.5 dB` ketika monster sangat dekat agar proximity cue tidak tertutup musik.

### Hurt
- Dipakai untuk hit/damage besar (`>= 3 HP` dalam satu update), sehingga pukulan monster dan hazard keras terbaca.
- Damage tick kecil seperti starvation/bleeding/infection tidak seharusnya men-spam SFX ini.
- Sedikit random pitch (`~0.96–1.04`) untuk mengurangi repetisi identik.

### Monster proximity
- Mulai terdengar ketika monster aktif berada sekitar `22 m` atau lebih dekat.
- Semakin dekat monster, volume meningkat halus.
- Near target sekitar `-3 dB`; outer edge sekitar `-27 dB`.
- Mengikuti Tenant, Darkness Creature, Mourner, Crawler, Warden, dan Evacuation Warden yang sedang visible/aktif.
- Saat tidak ada monster dekat, audio fade lalu berhenti.

### Battery / flashlight monster interference
- `battery.mp3` tidak diputar hanya karena battery <=22%.
- Audio mulai ketika flashlight ON dan beam mengenai monster yang visible serta tidak terhalang dinding.
- Deteksi memakai arah beam, cone flashlight, range aktual, dan line-of-sight; tidak membutuhkan collider produksi pada monster prototype.
- Saat beam keluar dari target, terdapat grace sekitar `0.16 s` agar procedural flashlight sway tidak memotong audio setiap beberapa frame.
- Selama interference aktif, volume/pitch `battery.mp3` sedikit meningkat sesuai durasi exposure.
- Jika file audio selesai sementara beam masih mengenai monster, player audio memutarnya kembali.
- Begitu interference berakhir, audio berhenti.

### Battery drain saat menyenter monster
Durasi continuous beam terhadap monster di-clamp pada maksimum **3 detik** untuk perhitungan multiplier:

- awal contact: sekitar `1.0x` normal drain
- `~0.75 s`: sekitar `1.25x`
- `~1.5 s`: sekitar `1.5x`
- `~2.25 s`: sekitar `1.75x`
- `3.0 s+`: maksimum `2.0x`

Dengan base drain player saat ini `1.15 battery/s`, maximum monster-interference drain menjadi sekitar `2.30 battery/s`. Multiplier tidak naik lebih dari `2.0x` meskipun monster terus disenter lebih dari 3 detik.

### Flashlight flicker saat menyenter monster
- Flicker dimulai segera setelah monster masuk beam.
- Flicker menjadi lebih cepat dan lebih dalam semakin dekat exposure ke 3 detik.
- Flicker mengalikan output energy yang sudah dihitung oleh battery/panic system, jadi tidak mengganti baseline full battery `6.7`.
- Saat beam lepas dari monster, interference state reset dan drain kembali `1.0x`.
- Low battery masih dapat memiliki visual weakness/flicker dari sistem player, tetapi tidak lagi memanggil `battery.mp3`.

## Monster coverage

Interference check mencakup:

- The Tenant
- Darkness Creature
- The Mourner
- The Crawler
- The Warden
- Evacuation Warden

Mourner/Crawler prototype saat ini tidak membutuhkan collider untuk mechanic ini karena beam contact dihitung secara geometris dan dikonfirmasi dengan ray line-of-sight ke environment.

## Mobile / desktop

Mechanic sama di desktop dan mobile. Procedural flashlight motion mobile tetap memakai amplitude yang lebih kecil, tetapi beam hit, 3-second exposure cap, flicker, dan battery multiplier tetap sama agar balance multiplayer tidak berbeda antar-device.

Seluruh audio tetap mengikuti Master Volume existing.

## Asset status / kebutuhan setelah update

Tidak ada audio baru yang wajib ditambahkan untuk v0.24.1. Update ini **me-repurpose `battery.mp3` yang sudah ada**.

Tetap dibutuhkan di repository/build final:

- `music.*`
- `hurt.*`
- `monster.*`
- `battery.mp3` atau file lain dengan basename/keyword `battery`

Optional polish di masa depan:

- 2–3 variasi electrical interference/glitch pendek agar loop `battery.mp3` tidak terasa repetitif pada exposure panjang.
- flashlight electrical buzz layer terpisah dari battery/interference cue.
- monster-specific light reaction SFX untuk Darkness/Warden.

## Repository note

Jika folder audio hanya ada lokal dan belum di-commit ke GitHub, kode tetap dapat menemukannya di local Godot project setelah import, tetapi clone/build dari repository-only source tidak akan membawa audio tersebut. Binary audio final harus ikut di-commit sebelum Android/desktop release build.

## Test checklist

1. Masuk gameplay: `music` mulai terdengar.
2. Ubah MASTER VOLUME: semua audio ikut berubah.
3. Terkena serangan monster: `hurt` berbunyi.
4. Dekati monster tanpa menyenternya: `monster` proximity dapat terdengar, tetapi `battery.mp3` **tidak** berbunyi.
5. Battery turun <=22% tanpa menyenter monster: `battery.mp3` **tidak** berbunyi.
6. Nyalakan senter dan arahkan beam ke monster: `battery.mp3` mulai dan flashlight flicker.
7. Tahan beam sekitar 1.5 detik: battery drain terasa sekitar `1.5x` normal.
8. Tahan beam 3 detik atau lebih: drain capped `2.0x`, tidak terus naik.
9. Arahkan beam ke dinding/keluar dari monster: interference berhenti dan drain kembali `1.0x`.
10. Sorot monster di balik dinding: interference tidak boleh aktif.
11. Ulangi pada Mourner/Crawler/Warden/Darkness/Tenant.
12. Test pada mobile: behavior sama, tanpa menambah tombol baru.
