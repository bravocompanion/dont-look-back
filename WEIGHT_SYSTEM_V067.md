# v0.67 — Weight-Based Inventory

## Carry contract

The expedition pack no longer uses a unique-item slot limit or per-item stack caps.

- Base capacity: **32.0 kg** per survivor.
- Weight is derived from `inventory_counts`; no separate weight value is saved.
- Equipment remains physical carry weight.
- Cabin stash is not limited by the personal 32 kg cap.
- Normal pickup/grant/withdrawal cannot raise carried weight above 32 kg.
- A legacy save already above 32 kg keeps every item, cannot collect additional physical weight, and may still consume/store/craft transactions that reduce weight.

## Encumbrance

| Pack ratio | Status | Movement effect |
| --- | --- | --- |
| <= 70% | NORMAL | no penalty |
| >70% to 90% | LOADED | sprint drain x1.15, stamina regen x0.90 |
| >90% to 100% | HEAVY | move speed x0.92, sprint drain x1.35, stamina regen x0.75 |
| >100% | OVERWEIGHT | sprint disabled, move speed x0.78 |

The carry HUD indicator is hidden while NORMAL and appears only from LOADED upward. Inventory and Field Status always expose current/max weight.

## Approved item weights

| Item | kg/unit |
| --- | ---: |
| Canned Food | 0.45 |
| Bottled Water | 1.00 |
| Dirty Water | 1.00 |
| Medkit | 1.25 |
| Bandage | 0.15 |
| Flashlight Battery | 0.30 |
| Generator Fuel Can | 5.00 |
| Firewood Bundle | 3.50 |
| Wood | 0.75 |
| Cloth | 0.12 |
| Scrap | 0.55 |
| Plastic Sheet | 0.30 |
| Rubber | 0.25 |
| Electronics | 0.35 |
| Lead Plate | 1.80 |
| Copper Wire | 0.40 |
| Industrial Filter | 0.80 |
| Arrow | 0.07 |
| Raw Meat | 0.65 |
| Cooked Meat | 0.60 |
| Raw Fish | 0.50 |
| Cooked Fish | 0.45 |
| Animal Hide | 0.90 |
| Bone | 0.30 |
| Animal Fat | 0.35 |
| Raincoat | 1.10 |
| Radiation Suit | 6.00 |
| Hunting Bow | 1.30 |
| Hunting Knife | 0.40 |
| Fishing Rod | 1.00 |

Unknown physical inventory ids default to 0.25 kg until authored. Dedicated investigation/quest progression remains outside the physical pack; compatibility objective ids are weightless.

## Crafting

Crafting uses **net transaction weight**:

`final = current - consumed_input_weight + output_weight`

This prevents false rejections when a recipe consumes heavy resources and produces a lighter item. It also allows an overweight legacy save to use a recipe only when that transaction reduces carried weight.

## Multiplayer and save compatibility

Weight is deterministic from item id + count. Existing network inventory mirrors therefore do not need a new continuously synchronized float. Save/load continues storing the existing inventory dictionaries; v0.67 recalculates weight after restore.
