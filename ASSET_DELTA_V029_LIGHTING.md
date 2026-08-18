# Asset Delta — v0.29 Lighting Balance

## Perubahan gameplay/visual
- Flashlight runtime range: 13m -> 65m (5x).
- Flashlight base energy: 3.5 -> 4.2 (+20%).
- Forest daylight/readability fill: target 20% dan memudar saat malam.
- Full-darkness ambient floor: 5% pada Forest night, Mine, Labyrinth, dan Research Facility.
- Darkness gameplay tetap bergantung pada protective lights; natural directional fill tidak dihitung sebagai safe light.

## Asset wajib baru
Tidak ada asset baru yang wajib untuk update ini.

## Asset opsional untuk production pass
- Flashlight lens / cookie texture untuk bentuk beam yang lebih natural.
- Low-cost volumetric beam/dust card untuk desktop.
- Mobile beam variant tanpa volumetric particles.
- Subtle moon/cloud sky texture atau cubemap untuk night readability.
- Light fixture emissive textures untuk Mine / Labyrinth / Research Facility.

## Catatan performa
Range flashlight 65m dengan shadow dapat lebih berat di mobile. Uji Android/iOS nyata diperlukan sebelum production lock; bila perlu buat quality toggle untuk flashlight shadows tanpa mengurangi gameplay range.
