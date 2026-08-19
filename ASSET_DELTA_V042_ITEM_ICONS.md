# Asset Delta v0.42 — Item Icons

v0.42 integrates the generated survival item artwork into the active UI through `ItemIconRegistry`.

## Active coverage

The compact 448x336 atlas covers the current inventory/crafting resource set: water, food, medical supplies, battery/fuel, wood/scrap/cloth, v0.41 radiation crafting materials, hunting/fishing resources, tools, Raincoat and Radiation Suit.

Inventory rows, Ranger Workbench recipes and Shared Stash rows now use the same canonical icon mapping. The Inventory shortcut also uses the backpack icon and the Stash menu uses the crate icon.

The atlas is reconstructed once from the committed `scripts/icon_data/item_icon_data_00.gd` through `item_icon_data_12.gd` chunks and cached as a single texture. This keeps the first integration compact for mobile and desktop.

## Shared Stash

The cabin chest now opens a responsive icon-based Shared Stash menu. Solo and HOST can transfer items. Co-op clients can inspect the shared contents while transfers remain host-controlled to avoid storage conflicts. Existing storage save/network dictionaries are preserved.

## Asset needs after this update

No new item icon is required for the current inventory/workbench/stash item IDs.

Future gameplay-state icons that are still useful, without duplicating current atlas art, include wildlife target/tracking states, fishing spot/bite feedback, downed/revive states, locked/unlocked route states, several unique evidence documents, and future enemy/tower-condition states.

The pending Forest night ambience file remains `res://assets/audio/forest_night.mp3`.
