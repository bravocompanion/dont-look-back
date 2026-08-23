extends "res://scripts/ai_noise_relay_system.gd"

func report_noise(position: Vector3, strength: float = 0.65, label: String = "noise") -> void:
    var adjusted_strength: float = strength
    if _looks_like_player_noise_v68(label):
        var progression: Node = get_node_or_null("/root/ProgressionSystem")
        if progression != null and progression.has_method("get_noise_multiplier_v68"):
            adjusted_strength *= clampf(float(progression.call("get_noise_multiplier_v68")), 0.70, 1.0)
    super.report_noise(position, adjusted_strength, label)

func _looks_like_player_noise_v68(label: String) -> bool:
    var normalized: String = label.to_lower()
    if normalized.contains("monster") or normalized.contains("tenant") or normalized.contains("darkness"):
        return false
    return true

func get_noise_progression_contract_v68() -> Dictionary:
    return {
        "quiet_steps_reduction_per_rank": 0.04,
        "max_rank": 3,
        "minimum_noise_multiplier": 0.70,
        "monster_noise_modified": false
    }
