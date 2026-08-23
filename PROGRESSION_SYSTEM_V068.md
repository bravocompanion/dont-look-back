# v0.68 — Major Survivor Progression

## Design goal

Progression represents a survivor becoming experienced, prepared and informed. It is deliberately not a power-fantasy damage ladder. The Tenant and Darkness remain dangerous at high level; progression improves efficiency, information, resource planning and teamwork rather than granting immunity.

## Level contract

- Maximum level: **30**.
- Level 1 starts with 0 Talent Points and 0 Stat Points.
- Every level gained grants **+1 Talent Point**.
- Every even level grants **+1 Stat Point**.
- XP threshold for level `L`: `120 + (L-1)*55 + (L-1)^2*4`.
- XP stops accumulating at Level 30.
- Normal resource farming and threat kills do not produce repeatable XP.

### Authored XP events

| Event | Base XP | Repeat policy |
| --- | ---: | --- |
| First Forest discovery | 20 | once/profile |
| First Mine discovery | 120 | once/profile |
| First Labyrinth discovery | 180 | once/profile |
| First Research Facility discovery | 220 | once/profile |
| Evidence logged | 30 | once/evidence/profile |
| Forest clue synthesis | 100 | once/profile |
| First craft of each recipe | 25 | once/recipe/profile |
| Generator first started that day | 40 | once/game-day |
| Generator repair | 40 | once/game-day |
| Survive a night | 75 | once/night |
| Observe Tenant | 20 | once/profile |
| Observe Darkness | 20 | once/profile |
| Revive teammate | 45 | once/target/game-day |

Evidence Analyst modifies evidence XP on the receiving survivor. Other event categories remain fixed.

## Core Stats

Each stat starts at 0 and caps at 15.

### Endurance
- +1 maximum stamina per point.
- +0.10 kg effective carry tolerance per point.
- +0.4% stamina regeneration per point.

### Fitness
- +0.2% movement speed per point.

### Fortitude
- hunger/thirst drain -0.5% per point.

### Focus
- effective flashlight-panic influence -1% per point.

### Dexterity
- vulnerable supply-use duration -0.5% per point.
- participates in the technical-interaction modifier contract.

Stat bonuses are intentionally conservative. They do not add large health/damage scaling.

## Talent Trees

### SURVIVAL

| Talent | Rank | Unlock | Effect |
| --- | ---: | --- | --- |
| Efficient Metabolism | 3 | Lv1 | hunger/thirst drain -3%/rank |
| Field Medic | 2 | Lv1 | vulnerable supply-use time -8%/rank |
| Pack Discipline | 1 | Lv5 + Efficient Metabolism 1 | LOADED begins at 75% instead of 70% |
| Load Bearing | 2 | Lv10 + Pack Discipline | +1.0 kg max carry/rank |
| Last Reserve | 1 | Lv20 + Load Bearing 2 | low-stamina recovery reserve; no unlimited sprint |

### SCOUT

| Talent | Rank | Unlock | Effect |
| --- | ---: | --- | --- |
| Runner | 3 | Lv1 | sprint stamina drain -4%/rank |
| Quiet Steps | 3 | Lv1 | player-generated AI noise -4%/rank |
| Pathfinder | 2 | Lv5 + Runner 1 | movement speed +0.5%/rank |
| Escape Instinct | 1 | Lv10 + Pathfinder 2 | pursuit/escape knowledge guidance |
| Ghost Trail | 1 | Lv20 + Escape Instinct | higher-detail movement/noise guidance; no invisibility |

### TECHNICIAN

| Talent | Rank | Unlock | Effect |
| --- | ---: | --- | --- |
| Quick Repair | 3 | Lv1 | technical-duration contract -6%/rank |
| Fuel Economy | 2 | Lv5 + Quick Repair 1 | generator fuel effectiveness +6%/rank |
| Salvager | 2 | Lv5 | salvage knowledge/future material hooks |
| Circuit Memory | 1 | Lv10 + Fuel Economy 1 | exact learned electrical/circuit notes |
| Emergency Power | 1 | Lv20 + Circuit Memory | emergency-power knowledge contract; never free permanent power |

Fuel Economy applies both to real-time generator burn and sleep simulation while the inherited shelter system keeps authoritative on/off/resource ownership. Generator condition still matters.

### INVESTIGATOR

| Talent | Rank | Unlock | Effect |
| --- | ---: | --- | --- |
| Steady Hands | 3 | Lv1 | effective flashlight panic -5%/rank |
| Evidence Analyst | 2 | Lv1 | evidence XP +10%/rank |
| Pattern Recognition | 2 | Lv5 + Evidence Analyst 1 | increasingly explicit threat notes |
| Threat Familiarity | 2 | Lv10 + Pattern Recognition 2 | learned protection rules become visible |
| Cold Reader | 1 | Lv20 + Threat Familiarity 2 | high-tier anomaly interpretation |

No Investigator talent gives threat resistance, immunity, permanent radar, or damage bonuses.

## Knowledge Journal

Knowledge is distinct from stats and talents. It records what the survivor has learned.

Categories:
- SURVIVAL
- TECHNOLOGY
- WILDLIFE
- WORLD
- THREAT
- ANOMALY

Initial authored entries: 20.

Knowledge comes from map discovery, evidence, first crafting, generator operation, surviving nights and observing major threats. Pattern Recognition / Threat Familiarity can expose the advanced analysis paragraph of already learned entries.

Notable threat knowledge retains the existing game contracts:
- Tenant: stable authored world/protected light matters; flashlight alone is not a global Tenant safe-zone.
- Darkness: flashlight or valid world protection can force withdrawal if maintained.

Knowledge explains those rules; it does not change them into immunity.

## Weight-system integration

v0.67's 32 kg expedition pack remains the base.

Effective maximum carry:
`32 kg + Endurance*0.10 kg + Load Bearing*1.0 kg`

Maximum authored progression bonus is 3.5 kg, for a maximum current design capacity of 35.5 kg.

Pack Discipline changes only the LOADED threshold from 70% to 75%. HEAVY stays >90% and OVERWEIGHT stays >100%.

Equipment still counts toward weight and all old per-item stack/type caps remain disabled.

## Save and checkpoint semantics

Progression contains only survivor experience data:
- level
- XP
- talent points
- stat points
- stat allocation
- talent ranks
- knowledge unlocks
- anti-grind event claims

Derived gameplay modifiers are recalculated at runtime and are not serialized.

### World save
The host world save stores `progression_v68` for the host profile and remains compatible with saves that predate v0.68.

### Local survivor profile
Each installation also stores a local survivor progression profile at:
`user://dont_look_back_progression_v68.json`

This lets multiplayer clients retain their own level/talents/knowledge even though clients do not own the host world save.

### Checkpoint death/team wipe
Shared checkpoint rollback does **not** roll survivor progression backward. World/resources continue to use existing checkpoint snapshot semantics.

Deleting the normal save resets progression and removes the local progression profile.

## Multiplayer

Progression is personal per survivor, not shared party progression.

Host-authoritative world interactions can award XP/knowledge to the correct remote collector/reviver through reliable RPC 68. The remote survivor applies their own local talent modifiers (for example Evidence Analyst).

This remains cooperative progression, not competitive anti-cheat. Existing prototype trust assumptions for broader inventory/player state remain unchanged.

## UI

Desktop:
- `P` opens/closes Survivor Progression.
- `ESC` closes it.
- `K` remains Save and `L` remains Load.

Mobile:
- responsive `PROG` button.
- full-width compact panel.
- touch buttons for stat allocation and talent unlocks.

Tabs:
1. Overview
2. Stats
3. Talents
4. Knowledge

Progression UI is mutually exclusive with Inventory, Crafting, Shared Stash, Field Status and Journal. Gameplay input is locked while the panel is open.

## Horror guardrails

v0.68 intentionally does **not** add:
- damage multipliers;
- large max-health growth;
- Tenant/Darkness immunity;
- permanent monster radar;
- unlimited sprint;
- instant revive;
- free permanent generator power.

Progression should make an experienced team better prepared without making the horror systems irrelevant.
