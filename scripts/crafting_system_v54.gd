extends "res://scripts/crafting_system_v43.gd"

# v0.54 crafting respects expedition stack limits in addition to unique-slot
# inventory capacity. Parent recipe costs and UI stay unchanged.

func _can_craft(recipe_id: String, player: CharacterBody3D) -> bool:
    if player == null:
        return false
    if _is_unique_owned(recipe_id, player):
        return false
    if recipe_id == "anti_radiation_tower":
        var radiation: Node = get_node_or_null("/root/RadiationSystem")
        if radiation == null or not radiation.has_method("can_build_tower") or not bool(radiation.call("can_build_tower")):
            return false

    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    var costs: Dictionary = _recipe_costs(recipe_id)
    for key_variant: Variant in costs.keys():
        var item_id: String = str(key_variant)
        if int(counts.get(item_id, 0)) < int(costs.get(item_id, 0)):
            return false

    var output: Dictionary = _recipe_output(recipe_id)
    if output.is_empty():
        return true
    var output_id: String = str(output.get("id", ""))
    if output_id.is_empty():
        return true
    var output_count: int = maxi(1, int(output.get("count", 1)))

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry != null and carry.has_method("can_accept_item"):
        return bool(carry.call("can_accept_item", player, output_id, output_count))

    var names: Dictionary = Dictionary(player.get("inventory_names"))
    var capacity: int = int(player.get("inventory_capacity"))
    return names.has(output_id) or names.size() < capacity

func _grant_output(player: CharacterBody3D, output: Dictionary) -> bool:
    if output.is_empty():
        return true
    var item_id: String = str(output.get("id", ""))
    var display_name: String = str(output.get("name", _display_name(item_id)))
    var amount: int = maxi(1, int(output.get("count", 1)))

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry != null and carry.has_method("grant_item"):
        return bool(carry.call("grant_item", player, item_id, display_name, amount))

    return super._grant_output(player, output)
