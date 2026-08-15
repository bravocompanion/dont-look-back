# DON'T LOOK BACK — Godot v0.12

A first-person survival-horror prototype for Godot 4.x with desktop controls, responsive touch controls, LAN co-op, shared survival systems, host-authoritative horror encounters, and an expanded outdoor survival area.

## v0.12 — Exterior Expansion
v0.12 extends the forest beyond the original cabin zone. The old far boundary is opened and the playable exterior continues deeper into the abandoned region.

### Expanded exterior
The outdoor map now continues beyond the old z≈-132 boundary to roughly z≈-204 and widens to approximately ±56 meters.

New paths connect the shelter region to several risk/reward locations:
- Abandoned House
- Old Gas Station
- Warehouse
- Old Water Pump
- Deep forest loot route

The expansion uses runtime primitive geometry and collisions so it remains compatible with the existing generated world and does not require an external art pack.

### Abandoned House
A damaged house sits west of the deeper road.

It contains:
- Canned Food
- Medkit
- Flashlight Battery

The building has multiple interior sections and narrow entrances, making it more dangerous to search when Darkness Exposure is already high.

### Old Gas Station
The gas station is one of the most valuable supply locations.

Loot includes:
- Two Fuel Cans
- Bottled Water
- Scrap

A weak emergency light remains inside the store. It creates a small protective-light pocket, but it does not replace the cabin as a safe base.

### Warehouse
The far warehouse is designed as a high-risk crafting-resource route.

Loot includes:
- Scrap
- Wood
- Flashlight Battery

Shelves and interior walls break sight lines, making the shared Darkness Creature more dangerous at night.

### Renewable water source
The Old Water Pump is the first renewable exterior water source.

- Interact with E on desktop or USE on mobile.
- A successful use adds one Bottled Water to the local survivor inventory.
- The pump has a short recovery cooldown before that survivor can draw again.
- It is renewable rather than a finite shared pickup.

Water purification/dirty-water processing is intentionally reserved for the deeper survival update after v0.12.

### More shared loot
All normal v0.12 loot objects still use the existing `survival_pickup.gd` flow.

In LAN co-op this means Food, Medkits, Batteries, Fuel, Wood, and Scrap in the new landmarks are still coordinated through the host: if one survivor claims a finite pickup, the same pickup is removed for the other peers.

### Stronger night encounters
The deeper exterior becomes more dangerous after sunset.

Normal outdoor values are retained near the cabin, but at night:
- Entering the expanded zone lowers the Darkness Creature spawn threshold.
- Moving into the far/deep zone lowers the threshold further.
- Shared co-op Darkness Creature movement becomes faster in the deeper region.
- Its attack damage increases modestly in the far zone.
- Solo Darkness encounters also receive shorter spawn cooldowns and stronger active-creature tuning.

The strongest current deep-zone values are approximately:
- Darkness spawn threshold: 52 instead of 72
- Shared Darkness movement: 2.85 instead of 2.15
- Shared Darkness attack: 22 instead of 18

These bonuses only apply when the outdoor world is in the night phase and survivors are exploring beyond the original forest boundary.

### Daylight coverage
A second daylight-protection volume covers the new exterior region so the expanded outdoor map behaves like the original forest during daylight. The weak gas-station emergency light remains a small night refuge.

## Co-op horror retained from v0.11
While LAN multiplayer is active:
- The Tenant is host-authoritative.
- The Darkness Creature is host-authoritative.
- Monsters can switch between standing survivors.
- Any standing survivor can freeze The Tenant by watching it.
- Nearby protective light from another survivor can repel the shared Darkness Creature.
- Lethal damage causes DOWNED rather than immediate death.
- Teammates can revive using E/USE and staying close for about 3 seconds.
- All-survivor downed state triggers a team wipe/reload.

## Existing multiplayer systems
- Host / Join LAN using Godot ENet
- 2–4 survivor target
- Remote survivor interpolation and flashlight state
- Health/Hunger/Thirst/Stamina/Battery snapshots
- Shared finite survival pickups
- Shared emergency relay progress
- Shared day/night clock
- Shared generator and campfire fuel
- Shared host shelter storage state
- Touch-operable CO-OP lobby

LAN remains the intended multiplayer test environment.

## Mobile gameplay retained
- Left virtual joystick — Move
- Right-side swipe — Camera look
- RUN — Sprint
- USE — Interact / pick up / revive / water pump
- LIGHT — Flashlight
- BATT — Replacement battery
- FOOD — Eat
- WATER — Drink
- MED — Heal
- RESTART — Restart when available
- CO-OP — Host/Join lobby

HUD and controls continue to resize for narrow/mobile viewports while keyboard/mouse controls remain active on desktop builds.

## Desktop controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact / revive / collect water
- F — Flashlight
- B or 4 — Replace Flashlight Battery
- 1 — Eat Canned Food
- 2 — Drink Bottled Water
- 3 — Use Medkit
- M — Open/close CO-OP lobby
- Esc — Release/capture mouse
- R — Solo death restart / restore active checkpoint

## Current survival loop
1. Survive the opening labyrinth and The Tenant.
2. Search Apartment 03.
3. Restore the emergency relays.
4. Exit into the forest.
5. Find and power the cabin shelter.
6. Gather/craft supplies and maintain generator/campfire light.
7. Push beyond the original forest boundary.
8. Search the Abandoned House for medical/food supplies.
9. Raid the Gas Station for fuel.
10. Search the Warehouse for Wood, Scrap, and Batteries.
11. Use the Old Water Pump as a renewable water route.
12. Return to shelter before deep-zone night threat becomes overwhelming.
13. In co-op, keep teammates alive and revive downed survivors.

## Testing v0.12
1. Pull the latest `main` branch.
2. Open the existing Godot project and press F5.
3. Progress through the labyrinth and reach The Outside.
4. From the cabin, travel past the old far edge of the forest.
5. Confirm the previous far wall is gone and the new ground continues.
6. Visit the Abandoned House, Gas Station, Warehouse, and Water Pump.
7. Verify new finite loot can be picked up normally.
8. Use the Water Pump twice and confirm its cooldown message appears.
9. Wait until night, enter the deep exterior, and verify Darkness encounters become more aggressive.
10. For co-op, repeat on two devices and confirm finite expansion loot disappears for the other peer after one survivor claims it.

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
- Downed crawling and revive progress UI are not implemented yet.
- Story-key ownership is not globally synchronized.
- Shared checkpoint authority is still per-peer/local rather than one host world save.
- Outdoor enemies still use direct movement rather than full navigation/pathfinding through complex structures.
- Internet matchmaking/NAT traversal is not implemented.

## Next targets
- v0.12.1 — fixes from exterior/mobile/co-op testing
- v0.13 — Survival Depth: dirty/clean water, boiling, bleeding/bandages, infection, and resource processing
- v0.14 — persistent world/save foundation
- Later — multiplayer polish, reconnect/session recovery, stronger outdoor AI/pathfinding, and internet-session support
