extends "res://scripts/shelter_system_ranger_v5.gd"

# v0.54 storage completion: all core capped survival stacks, including cooked
# food, can be moved out of the expedition inventory into the cabin chest.
func store_one_supply(player: CharacterBody3D) -> bool:
    if player == null:
        return false
    var names: Dictionary = Dictionary(player.get("inventory_names"))
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))

    for item_id: String in STORAGE_PRIORITY_V54:
        if int(counts.get(item_id, 0)) <= 0:
            continue
        if not _consume_item(player, item_id):
            continue
        var display_name: String = str(names.get(item_id, _v41_display_name(item_id)))
        storage_names[item_id] = display_name
        storage_counts[item_id] = int(storage_counts.get(item_id, 0)) + 1
        _set_objective(player, "Stored %s. Chest now holds %d items." % [display_name, _storage_total()])
        return true

    _set_objective(player, "No storable survival or crafting supplies available.")
    return false
