# Asset Delta v0.54 — P0 Survival Economy

## Runtime changes

v0.54 implements the P0 items from the survival/crafting/resource audit before moving to the P1 content pass.

### Expedition stack limits

Core survival supplies now have per-item carry caps in addition to the existing unique-item slot capacity:

- Canned Food: 5
- Clean/Bottled Water: 4
- Dirty Water: 3
- Medkit: 2
- Bandage: 4
- Flashlight Battery: 3
- Generator Fuel: 2
- Firewood Bundle: 4
- Wood: 10
- Cloth: 10
- Scrap: 12
- Plastic Sheet: 8
- Rubber: 8
- Electronics: 8
- Lead Plate: 8
- Copper Wire: 8
- Industrial Filter: 6
- Arrow: 20
- Raw Meat / Cooked Meat: 4 each
- Raw Fish / Cooked Fish: 4 each
- Hide: 6
- Bone: 8
- Animal Fat: 6
- Unique survival gear: 1 each

Limits are enforced by world pickups, crafting output, water collection/boiling, cooking, fishing loot, carcass harvest, arrow recovery, and Shared Stash withdrawals. Inventory rows show `current / limit`. Existing old saves with legacy over-cap stacks keep those items but cannot add more until the stack falls below the new cap.

### Starter progression

The Ranger Survival Cache no longer grants a free Hunting Bow or Hunting Knife. It now provides:

- Fishing Rod
- up to 4 Arrows
- 1 Cloth
- 1 Scrap

The player must scavenge additional Wood / Cloth / Scrap and craft the Hunting Bow and Hunting Knife at the ranger workbench. This makes those existing recipes part of the actual progression instead of dead recipes.

### Sleep rework

Sleep still advances to 07:00, but it is no longer a cheap night skip:

- requires at least 25 Health, 15 Hunger, and 20 Thirst;
- significant bleeding or infection blocks sleep;
- an active Darkness Creature blocks sleep;
- light-fuel consumption has a 1.35× sustained-night overhead;
- a running generator is consumed first;
- an active anti-radiation tower adds its 0.35 generator draw during the time skip;
- campfire burn time can cover the remaining sleep period;
- Hunger and Thirst are advanced using the current day survival escalation curve;
- Day-3+ Radiation is simulated during sleep;
- generator-covered sleep segments protect the ranger yard from radiation;
- campfire-only sleep segments do not provide radiation protection;
- in co-op, only HOST starts sleep, but the resulting Hunger / Thirst / Radiation time-skip costs are sent to every connected survivor instead of applying only to HOST.

At 20:00 with the default 720-second game day, a full 11-hour sleep represents about 330 simulated real seconds. With the 1.35× sleep overhead, one 360-second Fuel Can no longer covers the full night by itself. With the radiation tower active, generator demand is higher again.

### Stash logistics

The cabin stash can now store the capped survival/crafting materials including cooked food. Withdrawals obey the same carry limits, closing the previous direct `add_item()` bypass in the stash UI.

## Required new assets

None. v0.54 is a code/balance update and uses the existing UI/icon/resource set.

## Production assets still recommended

- Production bow / arrow / Hunting Knife models and animations.
- Wildlife hit, flee, death and carcass animations.
- Chopping / branch-gathering animation and SFX for the planned P1 renewable wood loop.
- Radiation filter item/icon if the planned P1 degradation mechanic is adopted.
- Generator repair interaction assets if the planned P1 infrastructure failures are adopted.
- Existing pending `res://assets/audio/draw.mp3`, `shoot.mp3`, `impact.mp3`, and `forest_night.mp3` if not already added.

## QA checklist

1. New game: Ranger Cache must not grant Hunting Bow or Hunting Knife.
2. Craft Hunting Bow and Hunting Knife after scavenging the required materials.
3. Fill Arrows to 20; crafting/recovering/picking another Arrow must fail without deleting the world arrow/pickup.
4. Fill Clean Water to 4 and Dirty Water to 3; pump/boiler must refuse additional stacks cleanly.
5. Fill Raw Meat to 4, kill wildlife, and confirm a carcass remains harvestable until enough carry space exists.
6. Verify inventory rows show current stack / cap.
7. Store capped food/materials in Shared Stash, then confirm TAKE 1 stops at the carry cap.
8. At 20:00, confirm one fresh 360-second Fuel Can is insufficient for a full protected sleep.
9. Add enough generator/campfire fuel and sleep; verify Hunger/Thirst advance.
10. On Day 3+, sleep with generator protection and compare radiation against campfire-only sleep.
11. Build the anti-radiation tower, sleep with generator running, and verify the extra tower generator draw is included.
12. Co-op: only HOST should be able to start sleep; every connected survivor must receive the shared Hunger/Thirst/Radiation time-skip cost and end at 07:00.
