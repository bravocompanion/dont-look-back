# Asset Delta — v0.34 Full ID / EN Localization

## Required new assets

Tidak ada aset 3D, texture, animation, atau audio baru yang wajib untuk update localization v0.34.

## Localization coverage

- Bahasa Indonesia dan English dapat diganti saat runtime.
- Pilihan bahasa disimpan lokal dan dipakai kembali saat game dibuka.
- Main menu, settings, HUD, objective, tooltip, inventory, Journal, notes, evidence, investigation route, Forest/Mine/Labyrinth/Research Facility, shelter, crafting, cooking, hunting, fishing, water treatment, wound/infection UI, multiplayer lobby, downed/revive feedback, save/front-end, dan Arc/Labyrinth legacy UI masuk dalam localization pass.
- Ranger investigation objective dan Labyrinth mission timer dibuat langsung dalam bahasa aktif agar dynamic text tidak menunggu translation sweep.
- Journal evidence/lore mempunyai body ID dan EN terpisah.

## Optional production UI assets

- Globe/language icon untuk toggle bahasa.
- Compact ID / EN badge untuk mobile.
- Localized baked signage hanya jika future art memakai text langsung di texture. Untuk signage gameplay sebaiknya tetap memakai Label3D/localized UI agar tidak perlu membuat texture duplikat.

## Font guidance

Tidak perlu menambahkan font file baru untuk Bahasa Indonesia/English selama font UI production mendukung Latin dasar. Jangan bake kalimat gameplay utama ke texture jika ingin localization tetap mudah diperluas.

## Existing production asset priorities unchanged

- Ranger Cabin production kit dan props interior.
- Forest vegetation/terrain LOD.
- Old Mine modular kit.
- Labyrinth/facility modular kit.
- Tenant dan monster production models.
- Wildlife models + carcass variants.
- Ranger survivor variants.
- Flashlight first-person/world model dan lighting polish assets.
