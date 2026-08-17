# Asset Delta — Forest Survival v0.26

## Update gameplay

v0.26 memperdalam hunting dan weather di Forest tanpa menambah autoload baru.

### Hunting sekarang memiliki harvest loop

Alur baru:

1. ambil Hunting Bow + Hunting Knife + Fishing Rod dari Ranger Survival Cache;
2. tembak wildlife menggunakan Arrow;
3. hewan yang terluka kabur lebih agresif dan meninggalkan blood trail;
4. ikuti blood trail;
5. setelah hewan tumbang, carcass tetap berada di dunia;
6. dekati carcass dan interact;
7. Hunting Knife wajib untuk harvest;
8. loot baru masuk Inventory setelah harvest;
9. carcass tidak bisa dipanen dua kali pada multiplayer;
10. carcass membusuk/hilang setelah beberapa waktu.

Loot tetap mengikuti hewan:
- Rabbit: Raw Meat + Hide;
- Deer: Raw Meat + Hide + Bone + Animal Fat;
- Boar: lebih banyak Raw Meat/Fat/Bone;
- Wolf: Hide/Bone/Fat.

### Blood tracking

Wildlife yang selamat dari hit meninggalkan blood mark secara berkala selama fase wounded.
Blood mark sekarang procedural dan otomatis fade.

Tujuan gameplay:
- tembakan yang tidak langsung membunuh tetap menghasilkan tracking gameplay;
- pemain harus memilih mengejar atau membiarkan prey kabur;
- malam/cuaca buruk membuat blood trail lebih sulit diikuti;
- multiplayer dapat mengikuti jejak yang sama karena mark disinkronkan dari host.

### Weather visual v0.26

Rain dan Storm sekarang memiliki rain streak procedural di sekitar local player.
Storm juga memiliki lightning screen flash dengan interval acak.

Rain berhenti ketika player berada di area shelter dekat cabin sehingga interior tidak terasa seperti hujan menembus atap.

Gameplay Wetness/Cold/Stamina dari v0.25 tetap digunakan.

---

# Runtime files

- `scripts/forest_survival_system_v26.gd`
- `scripts/wildlife_carcass.gd`
- `scripts/wildlife_blood_mark.gd`
- `scripts/wildlife_animal.gd` updated
- `scripts/forest_supply_cache.gd` updated
- `scripts/inventory_menu_system_v25.gd` updated
- `scripts/survival_system.gd` now loads v0.26 runtime

`project.godot` tidak membutuhkan autoload baru.

---

# Asset produksi yang dibutuhkan setelah v0.26

## P0 — Hunting Knife
- first-person Hunting Knife model;
- world/remote-player knife model;
- idle/inspect simple animation;
- harvest/cutting animation;
- knife draw/holster SFX;
- cutting/harvest SFX.

## P0 — Carcass models
Dibutuhkan carcass final untuk:
- Deer;
- Rabbit;
- Boar;
- Wolf.

Minimal:
- fresh carcass;
- harvested/skinned state.

P1 kemudian:
- decay state;
- partial harvest variants;
- wound decals pada model.

## P0 — Blood tracking
- blood drop decal atlas;
- small smear decal;
- larger wound pool decal;
- wet/rain-diluted blood variant.

Catatan mobile:
- gunakan decal sederhana dan jumlah terbatas;
- blood trail harus tetap terbaca pada layar kecil tanpa memenuhi ground.

## P0 — Rain / Storm final
Placeholder v0.26 menggunakan rain streak procedural.
Untuk final art dibutuhkan:
- rain drop/streak texture;
- heavy rain texture;
- splash particle texture;
- puddle ripple texture;
- wet ground material variants;
- storm cloud/sky layer;
- optional lightning bolt texture/mesh.

Audio:
- light rain loop;
- heavy rain loop;
- roof rain loop;
- distant thunder;
- close thunder;
- strong wind;
- branch/tree creak during storm.

## P1 — Tracking polish
- footprint decals Deer/Rabbit/Boar/Wolf;
- broken grass / disturbed leaves;
- arrow sticking into animal/world;
- recoverable arrow model;
- tracking inspect animation;
- optional hunting skill/perk UI later.

---

# Asset status

Tidak ada asset eksternal wajib agar prototype v0.26 dapat dijalankan: carcass, blood mark, dan rain streak memakai placeholder procedural Godot.

Untuk kualitas produksi, prioritas asset berikutnya adalah:
1. Hunting Knife;
2. carcass + harvested wildlife models;
3. blood decal atlas;
4. rain/heavy-rain particles;
5. thunder/rain audio;
6. animal footprints.
