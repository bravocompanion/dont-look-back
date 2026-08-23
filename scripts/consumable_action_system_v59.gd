extends "res://scripts/consumable_action_system_v58.gd"

func _duration_for(action: String) -> float:
    var duration: float = super._duration_for(action)
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("get_consumable_duration_multiplier_v68"):
        duration *= clampf(float(progression.call("get_consumable_duration_multiplier_v68")), 0.65, 1.0)
    return maxf(0.2, duration)

func get_progression_consumable_contract_v68() -> Dictionary:
    return {
        "dexterity_duration_reduction_per_point": 0.005,
        "field_medic_duration_reduction_per_rank": 0.08,
        "minimum_duration_multiplier": 0.70,
        "consumption_still_vulnerable": true,
        "damage_interrupt_unchanged": true
    }
