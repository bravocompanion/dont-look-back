extends "res://scripts/crafting_system_v55.gd"

func _craft_recipe(recipe_id: String) -> void:
    var player_before: CharacterBody3D = active_player
    var output: Dictionary = _recipe_output(recipe_id)
    var output_id: String = str(output.get("id", ""))
    var count_before: int = 0
    if player_before != null and not output_id.is_empty():
        count_before = int(Dictionary(player_before.get("inventory_counts")).get(output_id, 0))

    var tower_before: bool = false
    if recipe_id == "anti_radiation_tower":
        var radiation_before: Node = get_node_or_null("/root/RadiationSystem")
        tower_before = radiation_before != null and radiation_before.has_method("is_tower_built") and bool(radiation_before.call("is_tower_built"))

    super._craft_recipe(recipe_id)

    if player_before == null or not is_instance_valid(player_before):
        return
    var succeeded: bool = false
    if recipe_id == "anti_radiation_tower":
        var radiation_after: Node = get_node_or_null("/root/RadiationSystem")
        var tower_after: bool = radiation_after != null and radiation_after.has_method("is_tower_built") and bool(radiation_after.call("is_tower_built"))
        succeeded = not tower_before and tower_after
    elif not output_id.is_empty():
        var count_after: int = int(Dictionary(player_before.get("inventory_counts")).get(output_id, 0))
        succeeded = count_after > count_before

    if succeeded:
        var progression: Node = get_node_or_null("/root/ProgressionSystem")
        if progression != null and progression.has_method("record_first_craft_v68"):
            progression.call("record_first_craft_v68", recipe_id)

func get_crafting_progression_contract_v68() -> Dictionary:
    return {
        "first_craft_xp": 25,
        "repeat_craft_xp": 0,
        "weight_transaction_v67_retained": true,
        "knowledge_recipe_hooks_available": true,
        "existing_recipes_hard_locked_by_level": false
    }
