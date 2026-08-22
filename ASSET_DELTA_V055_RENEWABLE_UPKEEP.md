# Asset Delta v0.55 — Renewable Survival + Late-Game Upkeep

## Gameplay changes

v0.55 implements the next P1 items from the survival/crafting/resource audit after the v0.54 carry-limit and sleep rework.

### Hunting and fishing economy

Wildlife no longer becomes increasingly farmable on later days.

At the default 720-second full day, wildlife respawn targets are now approximately:

- Day 1: 8 in-game hours = 240 real seconds.
- Day 2–3: 10 in-game hours = 300 real seconds.
- Day 4+: 12 in-game hours = 360 real seconds.

Fishing cooldown changes from 18 seconds to 75 seconds per survivor.

Fishing success chances:

- Clear/default: 55%.
- Rain: 70%.
- Storm: 35%.
- Double catch: 10% after a successful catch.

Carry limits from v0.54 still apply to all fish/meat output.

### Renewable Wood loop

Eight procedural Fallen Branch gathering sites are distributed along the forest expedition routes.

Interaction:

- Desktop: aim at the branch pile and press E.
- Mobile: aim and press USE.
- Solo / 2-player: Wood x2 per successful site.
- 3–4 player session: Wood x3 per successful site.
- Solo / 2-player recovery: 8 in-game hours.
- 3–4 player recovery: 6 in-game hours.

The HOST owns availability, distance validation, cooldowns, and multiplayer claims. Cooldown state is persisted in the world save. This gives the forest a renewable fuel/material loop without turning every decorative tree into a physics-heavy harvest node.

### Radiation Suit filter degradation

The Radiation Suit is no longer a permanent 0.22x radiation solution with no upkeep.

- Filter charge starts at 100%.
- Filter drains only during Day-3+ forest radiation exposure when the survivor is outside powered protection.
- Generator/tower-protected time does not drain the suit filter.
- Base drain is 0.14 charge/second and increases with later days and rain/storm pressure.
- Protection scales gradually from about 0.22x at a full cartridge toward about 0.70x when exhausted.
- The suit still provides partial shielding at 0% instead of becoming useless instantly.
- Inventory shows the current Radiation Suit filter percentage.
- An Industrial Filter row becomes a REPLACE action when a suit is carried and charge is below full.
- Replacing consumes Industrial Filter x1 and restores filter charge to 100%.
- Filter charge is included in the existing radiation save state.

### Generator condition and repair

Generator mechanical wear begins on Day 3.

- Day 1–2: no mechanical wear.
- Day 3: base condition drain 0.075/second while running.
- Day 4: 0.095/second.
- Day 5+: starts at 0.12/second and rises gradually, capped at 0.16/second.
- Storm multiplies wear by 1.45.
- A built Anti-Radiation Tower multiplies wear by 1.25 while the generator is running.
- At 0% condition the generator shuts down and becomes broken.
- Repair cost: Scrap x2 + Electronics x1.
- Repair restores 70 condition and leaves the generator off until manually restarted.
- Existing fuel remaining in the tank can restart the repaired generator without consuming another Fuel Can.
- Shelter HUD now shows Generator Condition.
- Condition/broken state is saved and synchronized from HOST to clients.

Sleep checks projected generator wear. If the generator is too worn but the campfire alone has enough burn time, sleep preserves the generator and uses campfire-only protection. This also means Day-3+ radiation can increase during that campfire-only sleep segment.

## Party-size balance

v0.55 does not multiply all finite POI loot by player count. Instead, the first renewable shared loop scales modestly:

- 3–4 player teams receive one extra Wood per branch site.
- Branch recovery is shorter for 3–4 player teams.
- Fishing cooldown remains per survivor.

This preserves shared-supply pressure while preventing larger parties from being permanently starved of the renewable fuel needed for campfire/crafting.

## Required new assets

None. All v0.55 features have procedural/runtime visuals and reuse the existing Industrial Filter item/icon.

## Production assets recommended after v0.55

- Fallen branch / small log world model variants.
- Branch gathering / chopping hand animation.
- Wood snap, branch pickup, and light chopping SFX.
- Radiation filter cartridge world/inventory model.
- Filter removal/insertion animation and seal-click SFX.
- Generator repair animation, wrench/metal SFX, sparks/smoke VFX for failure state.
- Production bow / arrow / Hunting Knife models and animations.
- Wildlife hit, flee, death and carcass animations.
- Existing pending `res://assets/audio/draw.mp3`, `shoot.mp3`, `impact.mp3`, and `forest_night.mp3` if not already added.

## QA checklist

1. Kill wildlife on Day 1 and verify the respawn is roughly 4 real minutes at the default day length, not 120 seconds.
2. Verify later days do not shorten wildlife recovery.
3. Fish once and verify the next attempt is blocked for about 75 seconds.
4. Gather a Fallen Branch site, receive Wood, and verify the site disappears until its cooldown finishes.
5. Fill Wood to its carry cap and confirm branch gathering fails without consuming the site.
6. Save after gathering branches, reload, and confirm unavailable sites remain unavailable until their saved cooldown ends.
7. In 3–4 player HOST mode, verify branch yield is Wood x3 and HOST prevents duplicate simultaneous claims.
8. On Day 3+, carry a Radiation Suit and leave powered protection; verify filter percentage falls over time.
9. Verify generator/tower protection stops filter drain.
10. Use REPLACE on Industrial Filter in Inventory and confirm one filter is consumed and suit charge returns to 100%.
11. Run the generator on Day 3+ and verify Condition decreases; storm/tower load should accelerate wear.
12. Break the generator, confirm it shuts off, then repair with 2 Scrap + 1 Electronics and restart using remaining tank fuel if present.
13. Attempt sleep with low generator condition; if campfire can cover the full night, generator should be preserved and sleep should use fire-only protection.
14. Co-op: verify clients receive generator condition updates and branch availability from HOST.
