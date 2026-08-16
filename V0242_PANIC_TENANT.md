# DON'T LOOK BACK — v0.24.2 PANIC-DRIVEN TENANT

v0.24.2 mengubah PANIC dan The Tenant menjadi mechanic berbasis perilaku player, bukan proximity monster.

## PANIC source

PANIC tidak lagi meningkat hanya karena monster/Tenant berada dekat player.

PANIC sekarang membaca dua jenis gerakan lokal:

- horizontal movement speed
- camera look angular speed dari mouse/touch look

Default tuning:

- movement mulai menghasilkan panic di atas sekitar `4.75 m/s`
- full movement contribution sekitar `6.75 m/s`
- movement contribution maksimum `16 panic/s`
- mouse/touch look mulai menghasilkan panic di atas sekitar `95 deg/s`
- full look contribution sekitar `420 deg/s`
- look contribution maksimum `20 panic/s`
- kombinasi movement + look dibatasi maksimum `32 panic/s`
- jika tidak melewati threshold cepat, PANIC turun sekitar `6/s`

Implikasi gameplay:

- jalan normal sekitar 4 m/s tidak otomatis menaikkan panic
- sprint kuat menaikkan panic
- flick mouse/swipe sangat cepat menaikkan panic
- sprint sambil melakukan camera flick cepat dapat memenuhi panic jauh lebih cepat
- bergerak tenang memberi kesempatan panic turun

## 2-second stillness rule

Jika player memenuhi kedua kondisi berikut terus-menerus selama `2.0 s`:

- horizontal speed <= `0.12 m/s`
- camera look <= `3 deg/s`

maka The Tenant dipanggil dekat player jika Tenant belum aktif.

Spawn menggunakan arah belakang player dan mencoba posisi dekat sekitar `4.2 m`, lalu memakai navigation clamp agar lebih cocok dengan corridor/lower Labyrinth daripada clamp lorong lama.

Pause, menu, Journal, transition, death, dan downed state tidak menghitung idle timer.

HorrorTrigger lama tidak lagi memunculkan Tenant secara scripted. Trigger tersebut sekarang hanya memberi lighting/event feedback.

## PANIC → Tenant movement speed

Tenant movement speed naik secara linear sesuai panic player yang sedang diburu:

| PANIC | Movement |
|---:|---:|
| 0% | 1.65 m/s |
| 25% | 1.99 m/s |
| 50% | 2.33 m/s |
| 75% | 2.66 m/s |
| 100% | 3.00 m/s |

Pada 100% panic Tenant sekitar `1.82x` lebih cepat daripada pada 0% panic.

Tenant tetap mengikuti rule freeze ketika benar-benar diawasi player. Speed ini berlaku ketika ia diperbolehkan bergerak.

## PANIC → Tenant attack speed

Damage per pukulan tetap `28 HP`.

Yang berubah adalah cooldown antar serangan:

| PANIC | Attack cooldown | Approx attacks/s |
|---:|---:|---:|
| 0% | 2.40 s | 0.42 |
| 25% | 2.06 s | 0.48 |
| 50% | 1.73 s | 0.58 |
| 75% | 1.39 s | 0.72 |
| 100% | 1.05 s | 0.95 |

Pada panic penuh Tenant dapat mencoba menyerang sekitar `2.29x` lebih sering dibanding panic nol.

Spawn encounter masih punya initial grace singkat sebelum Tenant mulai bergerak/menyerang agar kemunculannya tidak menjadi hit instan.

## Flashlight banish — 3 seconds

The Tenant tidak lagi otomatis hilang ketika player memasuki old SafeZone trigger.

Untuk mengusir Tenant:

1. flashlight harus ON dan punya battery
2. beam harus benar-benar mengarah ke Tenant
3. Tenant harus berada di dalam cone/range flashlight
4. tidak boleh ada wall/geometry yang menutup line-of-sight
5. beam harus dipertahankan terus selama `3.0 s`

Jika beam lepas dari Tenant, hold timer Tenant reset.

Mechanic ini berjalan bersamaan dengan v0.24.1 flashlight monster interference:

- `battery.mp3` aktif ketika beam mengenai monster
- flashlight flicker selama interference
- battery drain meningkat dari 1x menuju maksimum 2x sampai 3 detik
- setelah 3 detik pada Tenant, Tenant menghilang

Jadi mengusir Tenant sengaja menghabiskan battery lebih cepat dan membuat beam tidak stabil.

## Co-op

Setiap survivor menghitung PANIC lokalnya sendiri.

Saat online:

- panic lokal dan status flashlight-on-Tenant dikirim ke host melalui runtime bridge channel 17
- host memakai panic survivor yang sedang diburu sebagai movement/attack scaling Tenant
- host menghitung continuous flashlight hold 3 detik
- host yang menghapus Tenant setelah banish tervalidasi oleh state session
- transform Tenant tetap mengikuti existing host AI/navigation replication

Tidak ada tambahan tombol mobile/desktop.

## Test checklist

1. Jalan normal tanpa mouse flick: panic seharusnya stabil/turun.
2. Sprint lurus beberapa detik: panic naik.
3. Diam tetapi flick mouse cepat: panic naik.
4. Sprint + flick mouse cepat: panic naik paling cepat, capped sekitar 32/s.
5. Berhenti bergerak dan jangan gerakkan camera selama 2 detik: Tenant muncul dekat player.
6. Bergerak atau menggerakkan camera sebelum 2 detik: idle timer reset.
7. Uji PANIC 0/25/50/75/100 dan bandingkan chase Tenant.
8. Pastikan damage Tenant tetap 28 per hit.
9. Panic tinggi harus menghasilkan cooldown pukul lebih pendek.
10. Lihat Tenant tanpa flashlight: ia freeze ketika watched tetapi tidak hilang.
11. Sorot Tenant <3 detik lalu lepaskan: Tenant tetap ada dan hold reset.
12. Sorot Tenant terus 3 detik: Tenant hilang.
13. Sorot Tenant di balik dinding: banish timer tidak boleh maju.
14. Setelah Tenant hilang, panic player tidak otomatis kembali ke 0.
15. Co-op host/client: masing-masing punya panic lokal, Tenant memakai panic target yang sedang diburu.

## Runtime validation

Perubahan ini telah mendapat static code/logic audit, tetapi Godot F5/device runtime validation tetap perlu dilakukan pada development machine karena environment assistant tidak memiliki Godot executable.
