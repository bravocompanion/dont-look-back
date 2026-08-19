# Gameplay Plan v0.41 — Radiation Survival Arc

## Design goal

v0.41 mengubah Ranger Forest dari sekadar area survival/investigation menjadi home base yang harus dipelihara beberapa hari. Investigation tetap mendorong pemain menuju House → Gas Station → Warehouse → Old Mine, tetapi setiap lokasi sekarang juga memiliki fungsi survival dan crafting.

Game tetap English-only untuk teks yang terlihat player. Dokumen ini memakai Bahasa Indonesia untuk planning internal.

## Core timeline

### Day 1 — Preparation
- New Game dan Host mulai pukul 12:00.
- Belum ada ambient radiation.
- Hunger/thirst sedikit lebih ringan dari baseline dan stamina regen sedikit lebih cepat.
- Darkness/night threat sedikit lebih lunak untuk memberi ruang belajar.
- Prioritas pemain: aktifkan base, cari food/water/fuel, ambil evidence House, kumpulkan cloth/plastic/rubber, dan buat Raincoat atau senjata hunting awal.
- Karena start 12:00, pemain hanya punya setengah hari untuk ekspedisi pertama sebelum malam.

### Day 2 — Pressure / Warning
- Belum ada ambient radiation, tetapi objective warning memberi tahu bahwa radiation akan mulai Day 3.
- Difficulty kembali ke baseline.
- Gas Station menjadi sumber fuel + electrical salvage.
- Warehouse menjadi target penting karena menyediakan scrap, electronics, lead, copper wire, dan industrial filters.
- Target ideal sebelum tidur Day 2: generator memiliki cadangan fuel dan host sudah memiliki material Anti-Radiation Tower atau Radiation Suit.

### Day 3 — Contamination begins
- Radiation aktif di Ranger Forest.
- Ranger yard tidak menambah radiation selama shelter generator menyala.
- Anti-Radiation Tower yang sudah dibangun memperluas protection field sampai 42 m dari tower selama generator menyala.
- Tower menambah beban generator +35% dibanding generator tanpa tower.
- Radiation Suit mengurangi radiation gain sekitar 78% di luar protection field.
- Rain/storm meningkatkan radiation intensity.
- Enemy pressure naik: Darkness threshold turun, cooldown lebih pendek, speed/damage naik, wildlife respawn lebih cepat.
- Investigation ke Mine menjadi lebih berisiko karena perjalanan jauh harus direncanakan terhadap battery, weather, radiation, dan return route.

### Day 4 — Escalation
- Radiation rate meningkat.
- Hunger/thirst drain +12% dari baseline, stamina regen menurun.
- Darkness creature pressure dan damage naik lagi.
- Pemain yang belum mempunyai powered tower atau Radiation Suit harus bergantung pada ekspedisi pendek dan generator timing.

### Day 5+ — Collapse phase
- Radiation terus naik secara bertahap sampai cap.
- Survival drain sekitar +18% baseline.
- Darkness spawn pressure, speed, damage, dan wildlife respawn berada pada tier tertinggi v0.41.
- Tujuannya bukan membuat Forest menjadi tempat tinggal permanen tanpa biaya: pemain harus bergerak ke Mine/Labyrinth/Facility sambil tetap menjaga Ranger Base sebagai logistics hub.

## Radiation rules

Radiation hanya mulai pada `day_index >= 3`.

Protection priority:
1. Powered Anti-Radiation Tower field — no radiation gain, radiation slowly decays.
2. Ranger yard + running generator — no radiation gain, radiation slowly decays.
3. Radiation Suit — 78% reduction to incoming radiation.
4. No protection — full ambient radiation rate.

Radiation thresholds:
- 0–34%: no direct condition penalty.
- 35%+: small continuous stamina pressure.
- 55%+: additional thirst pressure.
- 72%+: periodic radiation damage.
- 90%+: severe periodic radiation damage.

Underground/non-Forest maps currently stop new ambient radiation gain and slowly clear accumulated radiation. Dedicated contaminated Mine/Facility zones can be added later as authored hazards.

## Anti-Radiation Tower

- Fixed construction position inside Ranger Base logistics area.
- Built from the Ranger Workbench.
- Shared infrastructure: in co-op only HOST can construct it in v0.41.
- Requires generator power.
- Protection radius: 42 m.
- Has visible powered aura and emitter glow.
- Adds 0.35 fuel-seconds drain per real second on top of normal generator use.
- Tower built state and local radiation state are persistent through SaveSystem.
- Tower state syncs to joining co-op peers.

## Expanded crafting

### Survival
- Firewood Bundle: Wood x2.
- Improvised Battery: Scrap x2 + Electronics x1.
- Bandage: Cloth x2.

### Protection
- Raincoat: Cloth x3 + Plastic Sheet x2 + Rubber x1.
  - Reduces rain/storm wetness gain by 75%.
- Radiation Suit: Cloth x4 + Lead Plate x4 + Industrial Filter x2 + Rubber x2 + Electronics x1.
  - Reduces incoming ambient radiation by 78%.
  - Also gives partial rain protection.

### Weapons
- Hunting Bow: Wood x3 + Cloth x2 + Scrap x1.
- Arrow Pack x5: Wood x2 + Scrap x1.
- Hunting Knife: Scrap x3 + Cloth x1.

These are existing gameplay-compatible weapon/tool IDs: the bow consumes arrows for hunting, and the knife is required to harvest carcasses.

### Infrastructure
- Anti-Radiation Tower: Scrap x8 + Electronics x4 + Lead Plate x4 + Copper Wire x3 + Industrial Filter x2.

## Resource route

### Abandoned House
Purpose: early clothing/weather protection.
- Cloth
- Plastic Sheet
- Rubber
- small Scrap reserve

### Old Gas Station
Purpose: base power and electrical salvage.
- Fuel Cans
- Rubber
- Electronics
- Copper Wire
- Scrap

### Warehouse
Purpose: Day-3 preparation / tower components.
- large Scrap cache
- Electronics
- Lead Plates
- Copper Wire
- Industrial Filters

### Water Pump
Purpose: secondary protection components.
- Industrial Filters
- Plastic Sheet

### Old Mine
Purpose: late backup shielding and electronics.
- Lead Plate
- Electronics
- Scrap
- Filter

New special resources are finite and persistent when collected. They do not respawn randomly inside the Ranger yard.

## Resource economy / intended choices

The pre-Mine Forest route intentionally does not provide enough Lead Plate to comfortably build every radiation item immediately. A solo player should normally choose one of these paths before Day 3:
- Tower-first: maximize safe-base area and logistics, but spend more generator fuel.
- Suit-first: preserve mobility outside the base, but Ranger yard protection still depends on generator power.
- Co-op split: host prioritizes tower while another survivor carries protection gear and scavenges farther out.

Additional lead/electronics in the Mine allow the missing option to be built later.

## Difficulty progression

### Survival drain
- Day 1: hunger/thirst 90% baseline, stamina regen 106%.
- Day 2: baseline.
- Day 3: hunger/thirst 108%, stamina regen 96%.
- Day 4: hunger/thirst 112%, stamina regen 93%.
- Day 5+: hunger/thirst 118%, stamina regen 90%.

### Darkness threat
- Day 1: higher spawn threshold, longer cooldown, lower speed/damage.
- Day 2: near baseline.
- Day 3: lower threshold, shorter cooldown, +8% speed / +10% damage.
- Day 4: stronger escalation.
- Day 5+: highest v0.41 tier, but still constrained by Ranger Safe Zone rules.

### Wildlife
- Day 1 wildlife respawn is slower.
- Day 3+ wildlife/hostile animal repopulation becomes faster.
- Safe-zone eviction remains active, so wildlife cannot spawn/settle inside the Ranger yard.

## Revised core gameplay loop

1. Wake/deploy at Ranger Base and check Field Status.
2. Decide expedition goal: evidence, food, fuel, crafting material, hunting, or Mine progression.
3. Select protection gear and inventory loadout.
4. Check generator fuel / tower status / weather / radiation.
5. Leave safe yard and complete expedition objective.
6. Return before night/radiation/resource condition becomes unsafe.
7. Store material, craft upgrades, refuel generator/campfire.
8. Update Case evidence and prepare the next expedition.
9. From Day 3 onward, every long trip must account for radiation protection and powered-base return planning.

## Multiplayer roles

Suggested natural roles without hard classes:
- Base Engineer: generator, storage, tower materials.
- Scout/Investigator: evidence and route discovery.
- Hunter: bow, arrows, carcass harvesting and food supply.
- Hazard Runner: Radiation Suit, deep salvage, Mine access.

Objectives remain shared. Personal inventory remains local; shelter/tower infrastructure is shared.

## Next gameplay milestones after v0.41

P0 follow-up:
- Dedicated Forest Tenant/Warden spawner with day-based caps and host authority.
- Dedicated equipment slots instead of 'gear active while carried'.
- Tower repair/durability and electrical failure events.
- Radiation medicine / decontamination shower.
- Shared workbench contribution from shelter storage in co-op.

P1 follow-up:
- Irradiated wildlife variants after Day 4.
- Authored radiation pockets in Mine and Research Facility.
- Geiger-counter audio rate driven by radiation level.
- Protective suit visual on remote player model.
- Advanced weapons only after their combat mechanics exist; avoid crafting decorative weapons that have no gameplay function.

## QA targets

- New Game and Host start Day 1 at 12:00.
- Continue preserves saved day/time/radiation/tower state.
- Day 2 shows radiation preparation warning once.
- Day 3 starts radiation accumulation outside protection.
- Running generator prevents radiation gain anywhere inside Ranger yard.
- Generator OFF removes yard radiation protection but monster safe-zone rules remain.
- Powered tower aura is visible and protects to 42 m.
- Tower stops protecting immediately when generator stops.
- Radiation Suit reduces incoming radiation rate.
- Raincoat materially reduces Wet gain in Rain/Storm.
- Workbench opens responsive crafting menu on desktop/mobile.
- Inventory/Journal/Status/Co-op menus do not overlap crafting.
- All new resource pickups persist after save/load.
- Co-op joining peer receives tower built state and host time.
