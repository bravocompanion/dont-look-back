extends "res://scripts/crafting_system_v54.gd"

# v0.67 crafting evaluates the final carried weight after recipe inputs are
# removed and outputs are added. This allows overweight legacy saves to craft
# weight-reducing recipes instead of becoming soft-locked.

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
    var additions: Dictionary = {}
    if not output.is_empty():
        var output_id: String = str(output.get("id", ""))
        if not output_id.is_empty():
            additions[output_id] = maxi(1, int(output.get("count", 1)))

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry != null and carry.has_method("can_accept_transaction"):
        return bool(carry.call("can_accept_transaction", player, costs, additions))

    return super._can_craft(recipe_id, player)

func get_crafting_weight_contract_v67() -> Dictionary:
    return {
        "uses_net_weight": true,
        "consumed_inputs_reduce_preflight_weight": true,
        "overweight_weight_reducing_recipe_allowed": true
    }
