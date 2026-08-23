extends "res://scripts/forest_survival_system_v65.gd"

# v0.69 grants progression only after physical loot actually reaches this
# survivor. These callbacks execute on the receiving peer, so co-op clients earn
# their own personal milestone rather than credit being redirected to the host.

func _grant_harvest_loot_local_v52(player: CharacterBody3D, loot: Dictionary, animal_kind: String) -> void:
    var before: int = _loot_count_v66(player, loot)
    super._grant_harvest_loot_local_v52(player, loot, animal_kind)
    var after: int = _loot_count_v66(player, loot)
    if after <= before:
        return
    _record_local_milestone_v66(
        "wildlife_harvest:first",
        40,
        "First wildlife harvest",
        "wildlife_anatomy",
        "survival"
    )

func _grant_loot_local(loot: Dictionary, message: String) -> void:
    var player: CharacterBody3D = _local_player()
    var fish_before: int = _inventory_count_v66(player, "raw_fish")
    super._grant_loot_local(loot, message)
    if int(loot.get("raw_fish", 0)) <= 0:
        return
    var fish_after: int = _inventory_count_v66(player, "raw_fish")
    if fish_after <= fish_before:
        return
    _record_local_milestone_v66(
        "fishing:first_catch",
        30,
        "First successful fishing catch",
        "wildlife_anatomy",
        "survival"
    )

func _loot_count_v66(player: CharacterBody3D, loot: Dictionary) -> int:
    if player == null:
        return 0
    var total: int = 0
    for key_variant: Variant in loot.keys():
        total += _inventory_count_v66(player, str(key_variant))
    return total

func _inventory_count_v66(player: CharacterBody3D, item_id: String) -> int:
    if player == null:
        return 0
    var counts_value: Variant = player.get("inventory_counts")
    if not (counts_value is Dictionary):
        return 0
    return maxi(0, int(Dictionary(counts_value).get(item_id, 0)))

func _record_local_milestone_v66(
    event_key: String,
    xp: int,
    reason: String,
    knowledge_id: String,
    category: String
) -> void:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("record_milestone_v69"):
        progression.call("record_milestone_v69", event_key, xp, reason, knowledge_id, category)

func get_forest_progression_contract_v69() -> Dictionary:
    return {
        "first_harvest_xp": 40,
        "first_fish_xp": 30,
        "award_after_loot_granted": true,
        "awards_receiving_peer": true,
        "repeat_harvest_xp": 0,
        "repeat_fishing_xp": 0
    }
