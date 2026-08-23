extends "res://scripts/survival_depth_system_v55.gd"

func boil_water(player: CharacterBody3D) -> bool:
    var success: bool = super.boil_water(player)
    if not success:
        return false
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("record_milestone_v69"):
        progression.call(
            "record_milestone_v69",
            "water:first_safe_boil",
            30,
            "First safe water processed",
            "water_safety",
            "survival"
        )
    return true

func get_water_progression_contract_v69() -> Dictionary:
    return {
        "first_successful_boil_xp": 30,
        "award_requires_processed_water": true,
        "repeat_boil_xp": 0
    }
