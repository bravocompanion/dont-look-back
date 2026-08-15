# DON'T LOOK BACK — Godot v0.10

A first-person survival-horror prototype for Godot 4.x with desktop controls, responsive touch controls, and LAN co-op foundation.

## v0.10 — Mobile Controls
v0.10 turns the existing responsive HUD into actual mobile gameplay input. The same Player script now accepts keyboard/mouse and touch input, so survival, crafting, shelter interaction, and co-op use one gameplay path rather than separate desktop/mobile implementations.

### Touch movement and camera
- Left virtual joystick controls walking direction.
- Right-side free swipe area controls first-person camera look.
- Multi-touch indices keep movement and camera fingers separate.
- Joystick has a deadzone and clamped analog movement.
- RUN is a hold button and uses the existing Stamina sprint system.

### Mobile action buttons
Responsive touch buttons are created at runtime:
- USE — Interact / pick up / activate / craft / storage / sleep
- RUN — Hold to sprint
- LIGHT — Flashlight on/off
- BATT — Replace flashlight battery
- FOOD — Eat Canned Food
- WATER — Drink Bottled Water
- MED — Use Medkit
- RESTART — Appears after death

The existing desktop controls remain active on desktop builds.

### Responsive layout
Touch control sizes and positions scale from the current viewport dimensions.
- Joystick remains in the lower-left control zone.
- Primary actions remain on the lower-right.
- Consumable buttons stay near the lower center.
- Narrow/portrait layouts leave additional clearance for the responsive CO-OP button.
- Survival HUD continues using its compact mobile layout.
- Touch controls are hidden on normal desktop builds.
- Mobile Web is also detected through the web Android/iOS feature tags.

### Mobile interaction prompts
Desktop interaction prompts continue to use `[E]`.
Mobile interaction prompts automatically use `[USE]` so prompts match the touch UI.

### Death / restart
Desktop keeps `R` to restart.
On mobile, the normal action cluster hides after death and a large RESTART touch button appears.

## Multiplayer foundation retained from v0.9
LAN co-op remains available while using the new touch controls.

Current networking includes:
- Host / Join LAN using ENet
- 2–4 survivor target
- Remote survivor position/rotation interpolation
- Remote flashlight state
- Remote Health/Hunger/Thirst/Stamina/Battery snapshots
- Shared standard survival pickups
- Shared emergency relay progress
- Shared day/night state
- Shared generator and campfire fuel state
- Shared shelter storage state from the host

The CO-OP lobby uses normal GUI buttons and can be operated by touch.

### Multiplayer limits still remaining
v0.10 does not yet make every horror encounter fully server-authoritative.
Still planned:
- Shared authoritative The Tenant encounter
- Shared authoritative Darkness Creature targeting/damage
- Shared story-key ownership
- Full client chest transfers
- Revive/downed survivor system
- Internet matchmaking / NAT traversal

LAN is still the intended multiplayer test environment.

## Survival game loop
1. Survive The Tenant in the opening horror labyrinth.
2. Search Apartment 03.
3. Restore all emergency relays.
4. Exit into the forest.
5. Gather Fuel, Food, Water, Batteries, Wood, and Scrap.
6. Power the cabin generator.
7. Craft supplies at the workbench.
8. Maintain generator/campfire light through the night.
9. Manage Health, Hunger, Thirst, Stamina, Battery, Darkness, and Cold.
10. Sleep safely when enough light fuel remains.

## Desktop controls
- W A S D — Move
- Mouse — Look
- Shift — Sprint
- E — Interact
- F — Flashlight
- B or 4 — Replace Flashlight Battery
- 1 — Eat Canned Food
- 2 — Drink Bottled Water
- 3 — Use Medkit
- M — Open/close CO-OP lobby
- Esc — Release/capture mouse
- R — Restart after death / restore active checkpoint

## Mobile controls
- Left joystick — Move
- Swipe right side — Look
- RUN — Sprint
- USE — Interact
- LIGHT — Flashlight
- BATT — Replacement battery
- FOOD — Eat
- WATER — Drink
- MED — Heal
- RESTART — Restart after death
- CO-OP — Open Host/Join lobby

## Android/iOS export note
The gameplay code is now mobile-responsive, but generating an APK/AAB or iOS build still requires the appropriate Godot export templates and platform export setup on the development machine.

For Android LAN multiplayer, enable the INTERNET permission in the Android export preset.

## Testing v0.10
### Desktop
1. Pull the latest `main` branch.
2. Open the existing Godot project.
3. Press F5.
4. Desktop controls should behave exactly as before.

### Mobile device
1. Install/configure the relevant Godot mobile export templates.
2. Export/deploy the project to the device.
3. Start the game in landscape or portrait.
4. Verify joystick movement and simultaneous right-side camera swipe.
5. Test USE, RUN, LIGHT, BATT, FOOD, WATER, and MED.
6. Let Health reach zero or test a death encounter and verify RESTART.
7. For co-op, put devices on the same LAN/Wi-Fi, HOST on one device and JOIN using the host LAN IPv4 on the other.

## Update in Godot
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If local changes would be overwritten, discard them only when you did not intentionally edit those files yourself.
4. Fetch origin and Pull origin.
5. Return to the existing Godot project.
6. Press F5.

## Next targets
- v0.10.1 — fix device-specific touch/layout issues found during Android testing
- v0.11 — authoritative co-op monsters + downed/revive foundation
- Later — exterior expansion, larger loot routes, water systems, stronger night encounters, and internet-session support
