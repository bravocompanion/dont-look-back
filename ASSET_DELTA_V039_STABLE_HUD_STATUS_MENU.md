# Asset Delta — v0.39 Stable HUD + Field Status Menu

## Required assets

No new production asset is required for this update. The fix is implemented with Godot Control nodes and existing HUD data.

## UI changes

- Removed the duplicate vertical survival icon HUD from the active SurvivalSystem runtime.
- The live HUD now keeps one horizontal survival strip and one stable primary objective.
- Case route, day/time/cold, weather/wetness, shelter generator/campfire/storage, bleeding/infection/panic, co-op status, and inventory summary are moved into the Field Status menu.
- Desktop: TAB opens/closes Field Status.
- Mobile/Desktop: STATUS button opens the same responsive menu.
- Field Status includes shortcuts to Inventory and CO-OP Lobby.

## Optional production assets

- Field Status header icon.
- Small section icons for Case, Environment, Shelter, Condition, Co-op, and Inventory.
- Nine-slice dark panel/background for the status menu.
- Mobile-safe STATUS button icon.

Keep all icons readable at small sizes and provide a low-overdraw mobile version.
