# DON'T LOOK BACK — v0.24.4 TENANT BEAM PURSUIT

v0.24.4 mengubah respons The Tenant terhadap flashlight dan menambah shock PANIC ketika player benar-benar terkena pukulan monster.

## Tenant tetap mengejar saat disenter

Flashlight tidak lagi menghentikan Tenant sepenuhnya.

Aturan final:

- melihat Tenant tanpa beam flashlight tetap dapat membuat Tenant freeze sesuai watched rule lama
- jika beam flashlight benar-benar mengenai Tenant, Tenant tetap bergerak mengejar player
- selama beam contact aktif, movement speed Tenant dikalikan `0.50`
- attack cooldown Tenant tetap mengikuti PANIC; flashlight hanya mengurangi movement speed, bukan attack speed
- 3-second flashlight banish tetap berlaku
- `baterai.mp3`, rapid flicker, dan battery-drain interference tetap aktif selama beam mengenai Tenant

Movement examples:

| PANIC | Normal speed | Saat disenter |
|---:|---:|---:|
| 0% | 1.65 m/s | 0.825 m/s |
| 25% | ~1.99 m/s | ~0.995 m/s |
| 50% | ~2.33 m/s | ~1.165 m/s |
| 75% | ~2.66 m/s | ~1.33 m/s |
| 100% | 3.00 m/s | 1.50 m/s |

Jadi flashlight memberi waktu tambahan untuk menjaga beam 3 detik, tetapi tidak membuat encounter aman.

## Monster hit → PANIC shock

Setiap pukulan monster yang benar-benar masuk memberi default `+40 PANIC`.

Contoh:

- PANIC 0 → sekitar 40 setelah satu hit
- PANIC 30 → sekitar 70
- PANIC 65 → 100

PANIC tetap capped di 100.

Sumber PANIC lain tidak berubah:

- movement cepat di atas threshold
- mouse/touch-look cepat
- calm movement/look menurunkan PANIC sekitar 6/s
- proximity monster saja tidak menaikkan PANIC

Damage survival seperti starvation/dehydration tidak dimaksudkan memicu monster-hit shock.

## Co-op

Tenant flashlight slowdown dibaca host dari flashlight-contact state survivor. Jika salah satu survivor benar-benar menahan beam pada Tenant, movement simulation host memakai 50% speed selama contact masih valid.

PANIC lokal tetap dimiliki masing-masing survivor dan dikirim melalui existing Tenant panic bridge.

## Test checklist

1. Spawn Tenant dan lihat tanpa flashlight: watched/freeze lama tetap bekerja.
2. Nyalakan flashlight dan tahan beam pada Tenant: Tenant harus mulai/terus bergerak dengan kira-kira setengah speed.
3. PANIC 0%: bandingkan 1.65 m/s normal vs ~0.825 m/s beam.
4. PANIC 100%: bandingkan 3.00 m/s normal vs 1.50 m/s beam.
5. Tahan beam 3 detik: Tenant tetap dapat dibanish.
6. Pastikan `baterai.mp3` + rapid flicker tetap aktif selama hold.
7. Biarkan Tenant memukul: PANIC naik sekitar 40 poin sekali per hit.
8. Biarkan Mourner/Crawler/Warden/Darkness memukul: PANIC juga harus naik drastis.
9. Ambil damage lapar/haus tanpa monster: tidak boleh mendapat +40 PANIC monster-hit shock.
10. Co-op host/client: flashlight slowdown dan PANIC hit shock tetap konsisten pada survivor lokal.

## Runtime validation

Perubahan sudah mendapat static code/logic audit. Godot F5/device validation tetap diperlukan pada development machine.