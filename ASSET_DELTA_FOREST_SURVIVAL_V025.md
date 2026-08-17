# Asset Delta — Forest Survival v0.25

## Gameplay yang ditambahkan

### Wildlife
Prototype wildlife procedural sekarang tersedia di Forest:
- Deer / Rusa
- Rabbit / Kelinci
- Boar / Babi hutan
- Wolf / Serigala

Perilaku dasar:
- rusa/kelinci kabur ketika player mendekat;
- boar/wolf bersifat predator/hostile pada jarak tertentu;
- wildlife dapat diburu memakai Hunting Bow + Arrow;
- animal respawn setelah periode tertentu;
- state wildlife disinkronkan oleh host pada multiplayer.

Loot:
- Raw Meat
- Animal Hide
- Bone
- Animal Fat

### Hunting
- Ranger Survival Cache dekat cabin memberikan Hunting Bow, Fishing Rod, dan 8 Arrow.
- Desktop: klik kiri saat mouse captured untuk menembakkan bow.
- Mobile: tombol HUNT muncul jika bow dimiliki.
- Arrow adalah item inventory dan berkurang setiap tembakan.
- Hunting mengurangi sedikit stamina.

### Fishing
- Dua Fishing Spot prototype ditambahkan ke daerah hutan dalam.
- Fishing Rod diperlukan.
- Ada cooldown per pemain.
- Hujan sedikit meningkatkan peluang mendapat ikan; badai menguranginya.
- Hasil: Raw Fish.

### Cooking
- Cooking Rack ditambahkan dekat campfire shelter.
- Campfire harus menyala.
- Raw Meat -> Cooked Meat.
- Raw Fish -> Cooked Fish.
- Cooked Meat / Cooked Fish dapat dimakan dari Inventory.

### Weather + Wetness
Weather runtime:
- Clear
- Cloudy
- Rain
- Storm

Dampak gameplay:
- rain/storm menaikkan Wetness;
- berada dekat shelter mengeringkan Wetness;
- wetness tinggi mengurangi stamina;
- wetness tinggi saat hujan/badai mempercepat Cold Exposure;
- weather disinkronkan host pada multiplayer;
- HUD menampilkan cuaca dan Wetness secara responsive di mobile/desktop.

Visual cuaca sekarang masih berupa atmospheric screen tint + status UI. Particle rain, cloud layer, lightning, dan wet surface final menunggu asset produksi.

## Runtime integration
- `scripts/forest_survival_system.gd`
- `scripts/wildlife_animal.gd`
- `scripts/fishing_spot.gd`
- `scripts/forest_supply_cache.gd`
- `scripts/forest_cooking_station.gd`
- `scripts/inventory_menu_system_v25.gd`
- dipasang melalui existing `scripts/survival_system.gd`
- `project.godot` tidak perlu autoload baru.

# Asset yang sekarang dibutuhkan

## P0 — ganti placeholder wildlife
| Asset | Kebutuhan |
| --- | --- |
| Deer | rig + idle/graze/walk/run/hit/death |
| Rabbit | idle/hop/run/hit/death |
| Boar | idle/walk/run/charge/hit/death |
| Wolf | idle/walk/run/growl/attack/hurt/death |

## P0 — Hunting
| Asset | Kebutuhan |
| --- | --- |
| Hunting Bow | first-person + remote/world model |
| Arrow | projectile/world/pickup model |
| Bow draw/release SFX | desktop/mobile feedback |
| Arrow impact SFX | dirt/wood/flesh/metal variants |
| Animal hit/death SFX | per wildlife type |

## P0 — Fishing
| Asset | Kebutuhan |
| --- | --- |
| Fishing Rod | first-person + world model |
| Fishing line + bobber | visible casting setup |
| Freshwater Fish | minimal 2 species |
| Water ripple/splash | bite/catch feedback |
| Fishing SFX | cast, bite, reel, catch |

## P0 — Food / harvesting
- Raw Meat icon/model
- Cooked Meat icon/model
- Raw Fish icon/model
- Cooked Fish icon/model
- Hide icon/model
- Bone icon/model
- Animal Fat icon/model
- harvesting/butchering interaction animation later

## P0 — Weather visual/audio
- rain particle texture;
- heavy rain particle texture;
- cloud/storm sky layer;
- lightning flash + optional bolt texture;
- wet ground/material variants;
- puddle decals;
- light rain loop;
- heavy rain loop;
- distant thunder;
- close thunder;
- strong wind loop;
- forest storm ambience.

## P1 — polish berikutnya
- hunting knife + harvesting animation;
- animal tracks/footprints;
- blood trail decal;
- bait item;
- fishing mini interaction / tension meter;
- animal carcass model;
- skinning/harvest duration;
- drying rack / smoker;
- food spoilage models/icons;
- weather forecast object/radio at cabin.
