# DON'T LOOK BACK — Godot v0.13

A first-person survival-horror prototype for Godot 4.x with desktop controls, responsive touch controls, LAN co-op, host-authoritative horror encounters, an expanded exterior, and deeper survival conditions.

## v0.13 — Survival Depth
v0.13 turns wounds and water into resource-processing decisions. The new `SurvivalDepthSystem` adds Bleeding and Infection without replacing the existing Health/Hunger/Thirst/Stamina/Battery/Darkness/Cold systems.

### Bleeding
Large single hits now create Bleeding. Small starvation, dehydration, exposure, infection, and bleed ticks do not recursively create new wounds.

- Monster-sized damage raises Bleeding.
- Bleeding slowly clots naturally but remains dangerous for a long time.
- At meaningful Bleeding levels, periodic Health damage begins.
- An untreated bleeding wound slowly raises Infection.
- The responsive HUD now shows `BLEEDING` and `INFECTION` percentages.

In LAN co-op, monster damage remains decided by the host. The survivor who receives that authoritative damage then tracks their own wound condition locally.

### Infection
Infection rises from untreated wounds and unsafe water.

- Infection at 60% or higher continuously pressures Stamina.
- Infection at 90% or higher begins periodic Health damage.
- Low residual Infection can slowly recover after Bleeding has stopped.
- Bandages reduce a small amount of Infection while treating the wound.
- Medkits reduce Infection much more strongly.

### Bandages and Cloth
`Cloth` is a new finite survival resource.

Cloth can be found in:
- Apartment 03 / the early interior route
- Abandoned House
- Old Gas Station
- Warehouse

Normal Cloth pickups use the existing shared-pickup system, so in LAN co-op one finite Cloth pickup cannot be duplicated by every survivor.

The shelter workbench now rotates through three recipes:
- 2 Wood → Firewood Bundle
- 1 Wood + 2 Scrap → Flashlight Battery
- 2 Cloth → Bandage

Bandage is the cheaper treatment for Bleeding. Medkits remain the stronger emergency treatment.

### Medical Aid control
The existing medical control stays compact instead of adding another mobile button.

Desktop:
- `3` — Medical Aid

Mobile:
- `MED` — Medical Aid

Medical Aid behavior:
1. If the survivor is bleeding and has a Bandage, a Bandage is used first.
2. Otherwise, when Health/Infection/Bleeding requires stronger treatment and a Medkit is available, the Medkit is used.
3. A Medkit heals Health, stops Bleeding, and significantly reduces Infection.

### Dirty Water
The Old Water Pump no longer produces automatically safe drinking water.

It now produces:
- `Dirty Water`

The pump remains renewable and keeps its short per-survivor recovery cooldown.

### Drinking water
The existing WATER / `2` control now prefers safe water automatically.

- If Clean Water is available, it is consumed first and restores more Thirst.
- If only Dirty Water is available, it can still be consumed in an emergency.
- Drinking Dirty Water restores less Thirst and sharply increases Infection.

### Boiling water
A boiling pot is now placed beside the shelter campfire.

To process water:
1. Collect Dirty Water from the Old Water Pump.
2. Return to the shelter.
3. Light the campfire with Wood or a Firewood Bundle.
4. Interact with the boiling pot using E / USE.
5. One Dirty Water becomes one safe Clean Water.

The boiling pot requires the campfire to be actively burning.

### Inventory capacity
The survival-depth layer raises the effective unique-item capacity to at least 12 slots so Cloth, Bandages, and Dirty Water can coexist with the existing food, fuel, battery, medical, and crafting resources.

## Exterior retained from v0.12
The extended forest still includes:
- Abandoned House
- Old Gas Station
- Warehouse
- Old Water Pump
- Deep forest loot route
- Stronger Darkness Creature tuning after sunset in the far zone

At the deepest current night zone, the shared Darkness Creature can still use the stronger v0.12 tuning of approximately 52 Darkness threshold, 2.85 movement speed, and 22 attack damage.

## Co-op horror retained from v0.11
While LAN multiplayer is active:
- The Tenant is host-authoritative.
- The Darkness Creature is host-authoritative.
- Monsters can switch between standing survivors.
- Any standing survivor can freeze The Tenant by watching it.
- Nearby protective light from another survivor can repel the shared Darkness Creature.
- Lethal damage causes DOWNED rather than immediate game over.
- Teammates can revive using E/USE and staying close for about 3 seconds.
- All-survivor downed state triggers a team wipe/reload.

## Existing multiplayer systems
- Host / Join LAN using Godot ENet
- 2–4 survivor target
- Remote survivor interpolation and flashlight state
- Health/Hunger/Thirst/Stamina/Battery snapshots
- Shared finite survival pickups, including Cloth
- Shared emergency relay progress
- Shared day/night clock
- Shared generator and campfire fuel
- Shared host shelter storage state
- Touch-operable CO-OP lobby

Dirty Water from the renewable pump and individual wound-condition values are survivor-local rather than finite shared pickups.

## Mobile gameplay
- Left virtual joystick — Move
- Right-side swipe — Camera look
- RUN — Sprint
- USE — Interact / pick up / revive / pump / boil water
- LIGHT — Flashlight
- BATT — Replacement battery
- FOOD — Eat
- WATER — Drink Clean Water first, Dirty Water only if necessary
- MED — Bandage/Medkit medical aid
- RESTART — Restart when available
- CO-OP — Host/Join lobby

HUD and controls remain responsive on narrow/mobile viewports while keyboard/mouse controls remain active on desktop.

## Desktop controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact / revive / collect or process water
- F — Flashlight
- B or 4 — Replace Flashlight Battery
- 1 — Eat Canned Food
- 2 — Drink Water
- 3 — Medical Aid
- M — Open/close CO-OP lobby
- Esc — Release/capture mouse
- R — Solo death restart / restore active checkpoint

## Current survival loop
1. Survive the opening labyrinth and The Tenant.
2. Search Apartment 03 and collect early supplies/Cloth.
3. Restore the emergency relays.
4. Exit into the forest and power the cabin shelter.
5. Gather Wood, Scrap, Fuel, Food, Batteries, Cloth, and medical supplies.
6. Craft Firewood, Batteries, and Bandages at the workbench.
7. Explore the Abandoned House, Gas Station, Warehouse, and deep forest.
8. Collect Dirty Water from the renewable hand pump.
9. Return to a lit campfire and boil Dirty Water into Clean Water.
10. Treat Bleeding before Infection becomes severe.
11. Survive the stronger deep-zone night encounters.
12. In co-op, use team light and revive downed survivors.

## Testing v0.13
1. Pull the latest `main` branch.
2. Open the existing Godot project and press F5.
3. Verify two Cloth pickups are available along the Apartment 03 interior route.
4. Take a heavy monster hit and confirm BLEEDING rises.
5. Craft a Bandage at the shelter workbench and press 3 / MED while bleeding.
6. Confirm Bleeding drops significantly.
7. Use the Old Water Pump and confirm it gives Dirty Water.
8. Press 2 / WATER with only Dirty Water and confirm Infection rises.
9. Light the shelter campfire, use the boiling pot, and confirm Dirty Water becomes Clean Water.
10. Let Infection reach 60%+ and confirm Stamina pressure appears; very high Infection should eventually damage Health.
11. In co-op, confirm Cloth finite pickups disappear for the other peer after being claimed.
12. Confirm host-authoritative monsters and revive behavior from v0.11 still work.

## Android/iOS export note
Generating APK/AAB or iOS builds still requires the appropriate Godot export templates and platform setup on the development machine.

For Android LAN multiplayer, enable the INTERNET permission in the Android export preset.

## Update in Godot
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If local changes would be overwritten, discard them only when you did not intentionally edit those files yourself.
4. Fetch origin and Pull origin.
5. Return to the existing Godot project.
6. Press F5.

## Current limitations
- Runtime Godot validation still needs to be performed on the development machine.
- Bleeding/Infection are not yet persisted to disk or shared as host world-save data.
- Shelter chest priority does not yet automatically cycle Cloth/Bandage/Dirty Water.
- Downed crawling and revive progress UI are not implemented yet.
- Story-key ownership is not globally synchronized.
- Shared checkpoint authority is still per-peer/local rather than one host world save.
- Outdoor enemies still use direct movement rather than full navigation/pathfinding through complex structures.
- Internet matchmaking/NAT traversal is not implemented.

## Next targets
- v0.13.1 — fixes from wound/water/mobile/co-op testing
- v0.14 — persistent world/save foundation: player survival state, shelter resources, world time, conditions, and progress
- v0.15 — multiplayer polish / shared checkpoint authority / reconnect work
- Later — stronger outdoor AI/pathfinding and internet-session support
