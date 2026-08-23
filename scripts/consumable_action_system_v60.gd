extends "res://scripts/consumable_action_system_v59.gd"

func _complete_action(player: CharacterBody3D) -> void:
    var completed_action: String = active_action
    var medkit_before: int = _item_count_v60(player, "medkit") if completed_action == ACTION_MEDKIT else 0
    super._complete_action(player)
    if completed_action != ACTION_MEDKIT:
        return
    var medkit_after: int = _item_count_v60(player, "medkit")
    if medkit_after >= medkit_before:
        return
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("record_milestone_v69"):
        progression.call(
            "record_milestone_v69",
            "medicine:first_completed_medkit",
            20,
            "First completed field treatment",
            "field_medicine",
            "survival"
        )

func _item_count_v60(player: CharacterBody3D, item_id: String) -> int:
    if player == null:
        return 0
    var counts_value: Variant = player.get("inventory_counts")
    if not (counts_value is Dictionary):
        return 0
    return maxi(0, int(Dictionary(counts_value).get(item_id, 0)))

func get_medical_progression_contract_v69() -> Dictionary:
    return {
        "first_completed_medkit_xp": 20,
        "interrupted_medkit_xp": 0,
        "repeat_medkit_xp": 0,
        "existing_vulnerable_action_retained": true
    }
