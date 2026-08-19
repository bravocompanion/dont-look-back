extends "res://scripts/shelter_system_ranger_v2.gd"

const EXPANDED_WORKBENCH_SCRIPT_PATH: String = "res://scripts/shelter_workbench_v41.gd"
const STORAGE_PRIORITY_V41: Array[String] = [
    "generator_fuel", "flashlight_battery", "medkit", "bandage",
    "bottled_water", "canned_food", "firewood_bundle", "wood", "cloth", "scrap",
    "plastic_sheet", "rubber", "electronics", "lead_plate", "copper_wire", "filter",
    "arrow", "raw_meat", "raw_fish", "hide", "bone", "animal_fat"
]

func _ready() -> void:
    super._ready()
    workbench_script = load(EXPANDED_WORKBENCH_SCRIPT_PATH) as Script

func store_one_supply(player: CharacterBody3D) -> bool:
    if player == null:
        return false
    var names: Dictionary = Dictionary(player.get("inventory_names"))
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    for item_id: String in STORAGE_PRIORITY_V41:
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

func take_one_supply(player: CharacterBody3D) -> bool:
    if player == null or not player.has_method("add_item"):
        return false
    for item_id: String in STORAGE_PRIORITY_V41:
        var count: int = int(storage_counts.get(item_id, 0))
        if count <= 0:
            continue
        var display_name: String = str(storage_names.get(item_id, _v41_display_name(item_id)))
        if not bool(player.call("add_item", item_id, display_name)):
            _set_objective(player, "Inventory full. Cannot take %s." % display_name)
            return false
        count -= 1
        if count <= 0:
            storage_counts.erase(item_id)
            storage_names.erase(item_id)
        else:
            storage_counts[item_id] = count
        _set_objective(player, "Took %s from storage. Chest holds %d items." % [display_name, _storage_total()])
        return true
    _set_objective(player, "The storage chest is empty.")
    return false

func _v41_display_name(item_id: String) -> String:
    match item_id:
        "plastic_sheet": return "Plastic Sheet"
        "rubber": return "Rubber"
        "electronics": return "Electronics"
        "lead_plate": return "Lead Plate"
        "copper_wire": return "Copper Wire"
        "filter": return "Industrial Filter"
        "cloth": return "Cloth"
        "arrow": return "Arrow"
        "raw_meat": return "Raw Meat"
        "raw_fish": return "Raw Fish"
        "hide": return "Animal Hide"
        "bone": return "Bone"
        "animal_fat": return "Animal Fat"
    return _default_display_name(item_id)
