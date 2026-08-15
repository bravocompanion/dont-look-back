# DON'T LOOK BACK — Godot v0.14

A first-person survival-horror prototype for Godot 4.x with desktop controls, responsive mobile touch controls, LAN co-op, host-authoritative horror encounters, survival crafting, journal discoveries, and persistent world saves.

## v0.14 — Persistent World / Save Foundation
v0.14 adds a disk-backed save system so a run can survive closing and reopening the game.

The save file is stored in Godot's per-user data directory as:

`user://dont_look_back_save_v1.json`

The save file is runtime user data and is not stored inside the Git repository.

### Automatic continue
If a valid save already exists when the game starts, v0.14 automatically restores it after the generated world has initialized.

The player returns to the saved position with the saved survival and world state rather than starting the entire run from the beginning.

### Manual Save / Load
Desktop:
- `K` — Save World
- `L` — Load World

Mobile:
- `SAVE` — Save World
- `LOAD` — Load World

A compact save status message reports `AUTOSAVED`, `WORLD SAVED`, `SAVE RESTORED`, or load errors.

Manual Load reloads the current scene before applying the stored state. This allows finite loot that was collected after the save to correctly reappear when loading an older save.

Saving is blocked while the local survivor is dead/downed.

### Autosave checkpoints
The existing labyrinth and shelter checkpoints now trigger an autosave to disk.

Checkpoint state now also remembers:
- Bleeding
- Infection
- Cold Exposure

This means a checkpoint restart no longer intentionally carries a severe post-checkpoint wound back into the restored survivor state.

### Persistent player state
The v0.14 save stores:
- Player world position
- Player yaw rotation
- Health
- Hunger
- Thirst
- Stamina
- Flashlight battery
- Darkness Exposure
- Flashlight on/off state
- Inventory item names and stack counts

### Persistent survival conditions
The save stores:
- Bleeding
- Infection
- Cold Exposure

### Persistent labyrinth progress
The save stores:
- Relay A/B/C progress
- First corridor door open/closed state
- Exit door unlocked state
- Exit door open/closed state
- Active checkpoint snapshot and checkpoint name

Saving exit-door state prevents a consumed Apartment 03 key from leaving a restored run trapped behind a newly locked door.

### Persistent shelter / outdoor world
The save stores:
- Current day index
- Current world time
- Generator running state
- Remaining generator fuel
- Remaining campfire burn time
- Shelter chest item names/counts

After restoration, generator/campfire lights and relay/gate visuals receive an additional delayed synchronization pass so runtime-generated world objects can finish spawning before the final state is applied.

### Persistent finite loot
Finite survival pickups now register their node paths with `SaveSystem` when collected.

This includes normal finite supplies such as:
- Food
- Clean Water pickups
- Medkits
- Batteries
- Fuel
- Wood
- Scrap
- Cloth

The Apartment Exit Key is also registered as persistent finite loot.

Collected finite pickups remain gone after quitting and reopening the game. Loading an older save restores the pickup layout from that older save.

Renewable sources such as the Old Water Pump remain renewable and are not treated as permanently consumed loot.

### Persistent Journal
Discovered Journal entries, their order, and the currently selected entry are included in the world save.

The v0.13.1 Journal remains available with:
- Current Mission
- Tips
- Mission Notes
- Logs
- Trivia
- Warnings

Desktop: `J`
Mobile: `JOURNAL`

### Co-op save authority
Persistent world saves follow host authority.

- Solo players can Save and Load normally.
- A LAN HOST can save the shared world state.
- A connected CLIENT cannot create the authoritative world save.
- Loading is disabled while any co-op session is active.
- To continue a saved co-op world, restore the world while offline first, then HOST the LAN session.
- When peers connect, the existing NetworkManager continues synchronizing shared relays, day/night state, shelter state, and already-claimed shared pickups from the host.

Remote peer positions/individual client inventories are not yet permanent account/profile saves. v0.14 is a host-world persistence foundation rather than a full dedicated-server persistence system.

## v0.13.1 retained — Journal + Door Safety
The collectible Journal system remains active throughout the labyrinth and outdoor region.

The labyrinth door safety fix also remains active:
- Moving door collision is disabled before the door begins rotating.
- The script waits for a physics frame before the animation starts.
- Collision is restored after motion.
- When a door closes, collision restoration waits until the local player is clear of the hinge area.

This prevents the rotating AnimatableBody3D door from acting like a physics bat and launching the player outside the map.

## Survival Depth retained from v0.13
- Bleeding from large hits
- Infection from untreated wounds / unsafe water
- Cloth
- Bandage crafting
- Dirty Water
- Boiling pot beside the campfire
- Clean Water priority when drinking
- Medical Aid using Bandage before Medkit when appropriate

Workbench recipes:
- 2 Wood → Firewood Bundle
- 1 Wood + 2 Scrap → Flashlight Battery
- 2 Cloth → Bandage

## Exterior retained from v0.12
The expanded outdoor region still includes:
- Abandoned House
- Old Gas Station
- Warehouse
- Old Water Pump
- Deep forest loot route
- Stronger Darkness Creature tuning after sunset in the far zone

## Co-op horror retained from v0.11
While LAN multiplayer is active:
- The Tenant is host-authoritative.
- The Darkness Creature is host-authoritative.
- Monsters can switch between standing survivors.
- Any standing survivor can freeze The Tenant by watching it.
- Nearby protective light from another survivor can repel the Darkness Creature.
- Lethal damage causes DOWNED instead of immediate game over.
- Teammates can revive with E/USE while remaining close for about 3 seconds.
- All survivors downed triggers a team wipe/reload.

## Mobile gameplay
- Left virtual joystick — Move
- Right-side swipe — Camera look
- RUN — Sprint
- USE — Interact / pick up / revive / pump / boil water
- LIGHT — Flashlight
- BATT — Replacement battery
- FOOD — Eat
- WATER — Drink Clean Water first, Dirty Water if necessary
- MED — Bandage/Medkit medical aid
- JOURNAL — Mission / notes / tips / trivia
- SAVE — Save world
- LOAD — Load world while offline
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
- J — Journal
- K — Save World
- L — Load World (offline only)
- M — Open/close CO-OP lobby
- Esc — Release/capture mouse
- R — Death/checkpoint restart when available

## Current survival loop
1. Survive The Tenant and search Apartment 03.
2. Restore the labyrinth emergency relays.
3. Reach The Outside and power the forest cabin.
4. Gather Food, Water, Fuel, Batteries, Wood, Scrap, Cloth, and medicine.
5. Craft Firewood, Batteries, and Bandages.
6. Treat Bleeding/Infection and process Dirty Water over the campfire.
7. Explore the Abandoned House, Gas Station, Warehouse, and deep forest.
8. Discover Journal notes and warnings.
9. Save before dangerous expeditions or rely on major checkpoint autosaves.
10. Survive the stronger night encounters and return to the persistent shelter world.
11. In co-op, use shared light and revive downed teammates.

## Testing v0.14
1. Pull the latest `main` branch.
2. Open the existing Godot project and press F5.
3. Move somewhere recognizable, collect one finite pickup, then press K / SAVE.
4. Collect another pickup and move somewhere else.
5. Press L / LOAD while offline.
6. Confirm the player returns to the saved location.
7. Confirm the pickup collected before Save remains gone.
8. Confirm the pickup collected only after Save has returned.
9. Activate one or more labyrinth relays, Save, restart the game, and confirm relay/gate progress restores.
10. Unlock the Exit Door, Save after using the key, restart, and confirm the exit remains unlocked.
11. In the outdoor world, change generator/campfire fuel and chest contents, Save, restart, and verify those values restore.
12. Raise Bleeding/Infection, Save, restart, and verify condition values restore.
13. Discover a Journal entry, Save, restart, and confirm it remains in the Journal.
14. Reach a checkpoint and verify `AUTOSAVED` appears.
15. For co-op, restore the host save while offline, then HOST and connect the other device.

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
- Manual Load is intentionally disabled while a co-op session is active.
- Remote client inventories/profiles are not independently persisted yet.
- Renewable water-pump cooldown is not persisted.
- Transient active monster encounter positions are not written to disk; horror systems resume from the restored world rather than serializing an enemy mid-attack.
- Shelter chest cycling still does not automatically prioritize every v0.13 resource type.
- Downed crawling and revive progress UI are not implemented yet.
- Internet matchmaking/NAT traversal is not implemented.

## Next targets
- v0.14.1 — fixes from Save/Load testing on desktop/mobile
- v0.15 — multiplayer polish: shared checkpoint authority, reconnect/session recovery, client profile persistence, and lobby improvements
- v0.16 — mobile performance/settings polish and stronger safe-area customization
- Later — Navigation/pathfinding upgrades and internet-session support
