# DON'T LOOK BACK — v0.24.3.1 PANIC INPUT SOURCE FIX

Bugfix ini membuat PANIC benar-benar player-input driven.

## Sumber PANIC yang valid

PANIC hanya boleh berubah dari:

- horizontal movement speed player
- input mouse look asli pada desktop
- input right-side touch look asli pada mobile

Monster proximity, AI state, camera transform drift, procedural flashlight sway, monster audio, flashlight interference, dan posisi Tenant tidak menjadi sumber PANIC.

## Tuning tetap

- movement mulai menambah PANIC di atas sekitar 4.75 m/s
- full movement contribution sekitar 6.75 m/s
- movement maksimum +16 PANIC/s
- look mulai menambah PANIC di atas sekitar 95 deg/s
- full look contribution sekitar 420 deg/s
- look maksimum +20 PANIC/s
- combined gain maksimum +32 PANIC/s
- jika movement/look tidak melewati threshold, PANIC turun sekitar 6/s

## Perubahan implementasi

`PanicTenantSystem` lama masih dipakai untuk runtime Tenant dan flashlight banish, tetapi perhitungan PANIC dan keputusan idle-spawn lama dinonaktifkan.

`PanicInputSystem` sekarang menjadi single source of truth:

- membaca velocity horizontal untuk movement
- membaca raw mouse delta untuk desktop
- membaca `MobileControls.look_delta` sebelum dikonsumsi Player pada mobile
- menulis nilai final ke `player.flashlight_panic`
- menyinkronkan nilai yang sama kembali ke `PanicTenantSystem`
- berjalan sebelum `TenantPanicNetworkBridge`, sehingga co-op mengirim nilai PANIC yang sudah dikoreksi

## Rule diam 2 detik

Rule Tenant muncul setelah player diam 2 detik juga dipindahkan ke input-authoritative path.

Stationary berarti:

- movement <= 0.12 m/s
- real look input <= 3 deg/s

Camera movement yang bukan berasal dari input player tidak mereset timer ini.

## Regression test

1. Berdiri diam dekat Tenant/musuh tanpa menggerakkan mouse: PANIC harus turun, bukan naik.
2. Berdiri diam jauh dari musuh: hasil harus sama.
3. Jalan normal sekitar 4 m/s: PANIC tidak naik.
4. Sprint: PANIC naik.
5. Diam lalu flick mouse cepat: PANIC naik.
6. Mobile: swipe look cepat menaikkan PANIC; joystick movement normal tidak dianggap touch-look.
7. Dekati monster sambil tidak bergerak/tidak melihat cepat: proximity sendiri tidak boleh menaikkan PANIC.
8. Diam penuh 2 detik: Tenant tetap dapat muncul.
9. Camera/visual effect dari monster tidak boleh dianggap input look.
10. Co-op: host/client mengirim PANIC player-input yang sama ke host authority.

## Runtime validation

Static logic audit dilakukan di repository. Godot F5/device testing tetap diperlukan pada development PC/HP.
