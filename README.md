# DON'T LOOK BACK — Godot v0.11

A first-person survival-horror prototype for Godot 4.x with desktop controls, responsive touch controls, LAN co-op, shared survival systems, and host-authoritative horror encounters.

## v0.11 — Co-op Horror Foundation
v0.11 moves the main horror logic onto the LAN host so connected survivors fight the same encounter instead of each device simulating a separate monster.

### Host-authoritative The Tenant
While multiplayer is active:
- The Tenant AI is controlled only by the host.
- A client entering the opening horror trigger can request the shared encounter from the host.
- Entering the safe zone sends a shared stop request so the chase ends for the session rather than only on one device.
- The host selects the nearest survivor who is still standing.
- The Tenant can switch target between survivors.
- Looking at The Tenant from any standing survivor can freeze it.
- The host uses synchronized player body rotation + camera pitch to evaluate whether a survivor is watching it.
- World geometry still blocks the watch line-of-sight test.
- The host decides movement, attacks, panic, and damage.
- Monster transform/state is broadcast to clients on a separate unreliable RPC channel.

Solo mode still uses the original local The Tenant script.

### Shared Darkness Creature
While multiplayer is active, the original per-device DarknessDirector simulation is suspended and replaced by one shared Darkness Creature controlled by the host.

- The host watches every survivor's Darkness Exposure and light state.
- A survivor with dangerous Darkness can cause the shared creature to form.
- The creature targets standing survivors and can switch targets.
- Host-authoritative attacks deal synchronized damage.
- Nearby protective light from another survivor can force the creature to retreat and disappear.
- Clients render the same shared creature transform sent by the host.

When multiplayer is disconnected, the original solo DarknessDirector is enabled again.

### Downed survivors
In an active co-op session, lethal monster damage no longer immediately ends that survivor's run.

Instead:
- Health reaches 0.
- The survivor enters DOWNED state.
- Movement and normal gameplay input are disabled while downed.
- A full-screen downed warning appears.
- Other peers see a `DOWNED / USE TO REVIVE` marker on that survivor.
- The remote survivor receives an interaction collider so the normal E/USE interaction system can start a revive.

Other lethal survival conditions are also converted into the co-op downed state when detected while online.

Downed crawling is not implemented yet; v0.11 downed players are immobilized until revived or the team wipes.

### Revive channel
To revive a teammate:
1. Move close to the downed survivor.
2. Look at them and press E on desktop or USE on mobile.
3. Stay within approximately 2.8 meters for 3 seconds.
4. Moving away interrupts the revive.
5. A completed revive restores 45 Health and at least 35 Stamina.

The host validates revive distance, downed state, and completion time.

### Team wipe
The host tracks all connected survivors. If every active survivor is downed at the same time for roughly 2 seconds, the host broadcasts a team wipe and all peers reload the current scene. Existing checkpoint restoration remains responsible for the local restart position/state.

### Survivor authority data
v0.11 adds a lightweight co-op horror snapshot alongside the existing v0.9 NetworkManager snapshot. The host receives:
- Player transform
- Camera pitch
- Health
- Downed state
- Darkness Exposure
- Protective-light state
- Flashlight active state

This information is used for monster targeting, watch checks, revive validation, and team-wipe logic.

## Existing multiplayer retained
- Host / Join LAN using Godot ENet
- 2–4 survivor target
- Remote survivor movement interpolation
- Remote flashlight state
- Health/Hunger/Thirst/Stamina/Battery snapshots
- Shared survival pickups
- Shared emergency relay progress
- Shared day/night clock
- Shared generator and campfire fuel
- Shared host shelter storage state
- Touch-operable CO-OP lobby

### Multiplayer limits still remaining
v0.11 is a stronger co-op foundation but is not final production netcode.

Still planned:
- Downed crawling
- Revive animation/progress UI
- Shared story-key ownership
- Full client-controlled chest transfers
- Shared checkpoint authority instead of per-peer checkpoint restoration
- Better monster collision/pathfinding in larger outdoor structures
- Reconnect/session recovery
- Internet matchmaking / NAT traversal

LAN is still the intended multiplayer test environment.

## Mobile gameplay retained from v0.10
- Left virtual joystick — Move
- Right-side swipe — Camera look
- RUN — Sprint
- USE — Interact / revive
- LIGHT — Flashlight
- BATT — Replacement battery
- FOOD — Eat
- WATER — Drink
- MED — Heal
- RESTART — Solo/death restart when available
- CO-OP — Host/Join lobby

Touch controls scale from the current viewport and normal keyboard/mouse controls remain active on desktop builds.

## Desktop controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact / begin revive
- F — Flashlight
- B or 4 — Replace Flashlight Battery
- 1 — Eat Canned Food
- 2 — Drink Bottled Water
- 3 — Use Medkit
- M — Open/close CO-OP lobby
- Esc — Release/capture mouse
- R — Solo death restart / restore active checkpoint

## Current survival loop
1. Enter the opening horror corridor.
2. Survive the shared The Tenant encounter in co-op.
3. Search Apartment 03.
4. Restore the emergency relays.
5. Exit into the forest.
6. Gather Fuel, Food, Water, Batteries, Wood, and Scrap.
7. Power and maintain the cabin shelter.
8. Craft supplies and use storage.
9. Survive Darkness Creature encounters together.
10. Revive downed teammates instead of abandoning them.
11. Maintain Health, Hunger, Thirst, Stamina, Battery, Darkness, and Cold through the day/night loop.

## Testing v0.11 co-op
1. Pull the latest `main` branch on two devices.
2. Put both devices on the same LAN/Wi-Fi.
3. Device A opens CO-OP and presses HOST.
4. Device B enters Device A's LAN IPv4 and presses JOIN.
5. Verify both survivor avatars are visible.
6. Enter the opening encounter and confirm both devices see the same The Tenant position.
7. Have either survivor look at The Tenant and confirm the shared monster freezes.
8. Allow one survivor to take lethal monster damage and confirm DOWNED appears instead of immediate game over.
9. The other survivor approaches, presses E/USE, and remains close for 3 seconds.
10. Verify the downed survivor returns with Health restored.
11. In a dark area, verify the Darkness Creature is shared and retreats when a nearby survivor reaches protective light.

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

## Next targets
- v0.11.1 — fixes discovered during two-device monster/revive testing
- v0.12 — Exterior Expansion: abandoned structures, water source, larger loot routes, and stronger night encounters
- v0.13 — deeper survival conditions and resource processing
- Later — persistent host world saves, multiplayer polish, and internet-session support
