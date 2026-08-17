# Asset Delta — HUD Icon Survival

## Update
HUD survival sekarang memakai ikon visual + progress bar + angka, menggantikan label kata HEALTH / HUNGER / THIRST / STAMINA / BATTERY / DARKNESS.

## Asset baru yang sudah disertakan

| Asset | Path | Fungsi | Status |
| --- | --- | --- | --- |
| Health icon | `assets/ui/hud/icon_health.svg` | HP / kondisi luka | Included |
| Hunger icon | `assets/ui/hud/icon_hunger.svg` | Hunger | Included |
| Thirst icon | `assets/ui/hud/icon_thirst.svg` | Thirst | Included |
| Stamina icon | `assets/ui/hud/icon_stamina.svg` | Sprint / stamina | Included |
| Battery icon | `assets/ui/hud/icon_battery.svg` | Baterai flashlight | Included |
| Darkness icon | `assets/ui/hud/icon_darkness.svg` | Exposure terhadap darkness | Included |

## Runtime integration
- `scripts/hud_icon_system.gd` membangun HUD ikon saat local player aktif.
- Integrasi sekarang diluncurkan dari `SurvivalSystem`, yang memang sudah autoload sebelumnya.
- Update HUD tidak lagi menambah atau mengubah entry autoload di `project.godot`, sehingga pull lebih aman untuk project Godot yang dibuka/diedit lokal.
- HUD lama `SurvivalPanel` disembunyikan, tetapi sistem survival lama tetap berjalan sehingga tidak mengubah gameplay/network state.
- Layout compact aktif untuk mobile atau viewport di bawah 800 px.
- Layout desktop memakai bar yang lebih panjang dan ikon lebih besar.
- Kondisi kritis memberi pulse visual pada ikon dan angka.

## Asset yang masih dibutuhkan setelah update
Tidak ada asset wajib tambahan untuk HUD ini. Enam SVG di atas sudah cukup untuk runtime Godot.

### Optional polish berikutnya
- 6 ikon hand-painted/grunge 64x64 dengan siluet yang sama untuk art direction final.
- SFX UI low-health / low-battery warning jika nanti warning audio ingin ditambahkan.
- Texture frame HUD 9-slice jika ingin mengganti panel procedural menjadi skin final.

Semua optional polish harus mempertahankan silhouette sederhana agar tetap terbaca di mobile.
