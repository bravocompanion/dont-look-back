# Asset Delta v0.24 — Dynamic Horror Audio

Update v0.24 menggunakan audio asset yang sudah disiapkan pengguna untuk empat fungsi runtime utama.

## P0 — audio yang harus tersedia di project

Sistem mencari file audio secara recursive di folder umum seperti `res://assets`, `res://audio`, `res://sounds`, `res://sfx`, dan `res://music` (termasuk variasi huruf besar). Format yang didukung oleh resolver v0.24: `.wav`, `.ogg`, `.mp3`.

Nama file boleh persis atau mengandung keyword berikut:

- `music` — background music gameplay. Contoh: `assets/music.ogg`, `assets/background_music.mp3`.
- `hurt` — one-shot ketika pemain menerima damage besar/serangan. Contoh: `assets/hurt.wav`, `assets/player_hurt.ogg`.
- `monster` — proximity threat layer. Contoh: `assets/monster.ogg`, `assets/monster_near.mp3`.
- `battery` — warning baterai senter rendah. Contoh: `assets/battery.wav`, `assets/low_battery.ogg`.

Exact basename (`music`, `hurt`, `monster`, `battery`) mendapat prioritas sebelum partial-name match.

## Runtime use

### Music
- Gameplay BGM mulai saat masuk map gameplay.
- Berhenti saat kembali ke dedicated main menu.
- Jika audio selesai, diputar ulang sebagai background loop behavior.
- Base volume internal: sekitar `-16 dB` sebelum Master Volume.
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

### Low battery
- Trigger saat flashlight battery melewati low threshold player (`22%` saat ini).
- Selama senter masih digunakan pada low battery, reminder sekitar setiap `9 s`.
- Di bawah `10%`, reminder menjadi sekitar setiap `4.8 s` dengan sedikit pitch naik.
- Setelah mengganti battery dan charge kembali di atas threshold, warning cycle reset.

## Mobile / desktop

Tidak ada audio graph khusus platform. Seluruh channel mengikuti Master Volume existing, sehingga behavior desktop dan mobile konsisten. Untuk HP, audio asset final sebaiknya dikompres secara wajar; BGM panjang lebih cocok `.ogg`, sedangkan SFX pendek dapat `.wav` atau `.ogg`.

## Repository status saat implementasi

Pada saat v0.24 dibuat, branch `main` GitHub belum memiliki folder `assets/`. Karena itu file audio binary belum dapat dimasukkan oleh update kode ini. Jika file tersebut sudah ada secara lokal di folder project, resolver v0.24 akan menemukannya setelah Godot meng-import asset. Agar audio ikut saat clone ke PC lain / build dari repository, empat audio tersebut perlu ikut di-commit ke repository.

## Test checklist

1. Masuk gameplay: `music` mulai terdengar.
2. Ubah MASTER VOLUME: semua audio ikut berubah.
3. Terkena serangan Mourner/Crawler/Warden/Tenant: `hurt` berbunyi sekali per hit besar.
4. Dekati monster dari >22 m sampai dekat: `monster` muncul/fade dan makin kuat ketika dekat.
5. Menjauh atau monster hilang: proximity layer fade dan berhenti.
6. Turunkan battery ke <=22%: `battery` berbunyi.
7. Tetap gunakan senter low battery: reminder berkala, bukan setiap frame.
8. Battery <=10%: warning lebih sering.
9. Ganti battery: warning reset.
10. Return to title: gameplay BGM/proximity/hurt/battery berhenti.
