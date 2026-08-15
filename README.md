# DON'T LOOK BACK — Godot v0.9

A first-person survival-horror prototype built for Godot 4.x.

## v0.9 — Multiplayer Foundation
v0.9 adds the first playable LAN co-op layer without replacing the existing single-player survival systems. Solo mode still works when no multiplayer peer is active.

### Host / Join
- LAN host/join using Godot ENet multiplayer.
- Current target: 2–4 survivors.
- Open the CO-OP panel with the on-screen `CO-OP` button or press `M` on desktop.
- HOST shows the host device LAN IPv4 when available.
- JOIN accepts an IPv4 address such as `192.168.1.20`.
- Default port: `24877`.
- Disconnecting returns the game to solo mode.

### Networked survivors
Every peer keeps control of its own existing first-person player. NetworkManager sends a lightweight snapshot of:
- World transform / movement position
- Body rotation
- Camera pitch
- Flashlight on/off state
- Health
- Hunger
- Thirst
- Stamina
- Flashlight battery

Other survivors are rendered as remote co-op avatars with a visible flashlight and floating Survivor/HP label. Transform interpolation is used to smooth remote movement.

### Shared survival pickups
The standard survival loot system is now coordinated through the host:
- Food
- Water
- Medkits
- Flashlight batteries
- Fuel cans
- Wood
- Scrap

When one survivor successfully claims a supply, the host records that pickup path and removes the same pickup for the other connected peers. The claimed list is also sent to late-joining clients.

Story/key items outside `survival_pickup.gd` are not yet globally synchronized in v0.9.

### Shared labyrinth progress
The three Emergency Relays are host-authoritative while multiplayer is active.
- A client sends a relay activation request.
- The host updates the shared relay state.
- Relay state and final gate state are broadcast to connected clients.

### Shared world and shelter state
The host periodically broadcasts:
- Day/night clock
- Day number
- Generator running state
- Generator fuel
- Campfire fuel
- Shelter storage contents/count
- Emergency relay state

Fuel added by a client is consumed from that client's inventory and sent as a shared shelter action to the host. Generator and campfire state are then synchronized back to all peers.

For v0.9 safety:
- Shared chest transfers are host-controlled.
- Sleeping/advancing the shared night is host-controlled.
- Workbench crafting remains local to each survivor inventory.

### Multiplayer limits in v0.9
This is the foundation release, not the final co-op netcode.

Still to complete:
- Full server-authoritative monster targeting/damage for every survivor
- Synchronizing The Tenant and Darkness Creature as one shared encounter
- Shared story-key ownership
- Client-controlled shared storage transfers
- Revive/downed-player system
- Internet matchmaking / NAT traversal

The current Host/Join flow is intended for LAN testing first.

## Existing survival game
The existing game flow remains available:
1. Survive The Tenant in the horror labyrinth.
2. Search Apartment 03.
3. Restore the emergency relays.
4. Exit into the forest.
5. Gather Fuel, Food, Water, Batteries, Wood, and Scrap.
6. Power the cabin generator.
7. Craft supplies at the workbench.
8. Maintain generator/campfire light through the night.
9. Manage Health, Hunger, Thirst, Stamina, Battery, Darkness, and Cold.

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

## Mobile / responsive status
The multiplayer lobby itself is responsive and includes a touch-clickable `CO-OP` button. Existing survival and shelter HUDs also switch to compact layouts on narrow screens.

Full mobile gameplay controls are still scheduled for v0.10:
- Left virtual joystick
- Touch/swipe camera look
- Interact
- Sprint
- Flashlight
- Item actions
- Mobile-safe inventory controls

For Android multiplayer exports, remember to enable the Android INTERNET permission in the export preset.

## Testing v0.9 on two PCs
1. Pull the latest `main` branch on both devices.
2. Make sure both PCs are on the same LAN/Wi-Fi.
3. Start the game on PC A and open CO-OP.
4. Press HOST.
5. Note the LAN IPv4 shown by the host.
6. Start the game on PC B.
7. Open CO-OP and enter PC A's LAN IPv4.
8. Press JOIN.
9. Both devices should show the other survivor avatar and synchronized flashlight/state.

If Windows Firewall asks for network access, allow Godot/game access on the private network used for the test.

## Update in Godot
If the repository is already cloned:
1. Open GitHub Desktop.
2. Select `bravocompanion/dont-look-back`.
3. If local changes would be overwritten, discard them only when you did not intentionally edit those files yourself.
4. Fetch origin and Pull origin.
5. Return to the existing Godot project.
6. Press F5.

## Next target
- v0.9.1 — multiplayer monster authority + shared encounter fixes after LAN testing
- v0.10 — complete mobile touch controls and Android-oriented responsive input
- Later — exterior expansion, revive system, stronger co-op night encounters, and internet-session support
