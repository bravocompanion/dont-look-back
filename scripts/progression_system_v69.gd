extends "res://scripts/progression_system_v68_profile.gd"

# v0.69 keeps the v0.68 level curve/profile format intact and adds a small
# milestone API for concrete survival actions. Every milestone is claimed once
# through the existing anti-grind event dictionary, so reconnects and reloads
# cannot repeatedly grant XP.

func record_milestone_v69(
    event_key: String,
    base_xp: int,
    reason: String,
    knowledge_id: String = "",
    category: String = "survival"
) -> bool:
    if event_key.strip_edges().is_empty() or base_xp <= 0:
        return false

    var clean_key: String = event_key.strip_edges().to_lower().left(120)
    var awarded: bool = award_event_once_v68(
        "milestone:v69:%s" % clean_key,
        base_xp,
        reason,
        category
    )

    var learned: bool = false
    if not knowledge_id.is_empty():
        learned = unlock_knowledge_v68(knowledge_id)
    return awarded or learned

func get_progression_gameplay_contract_v69() -> Dictionary:
    return {
        "level_curve_changed": false,
        "profile_format_changed": false,
        "milestones_are_once_per_survivor": true,
        "first_safe_water_xp": 30,
        "first_wildlife_harvest_xp": 40,
        "first_fish_catch_xp": 30,
        "first_completed_medkit_xp": 20,
        "normal_resource_farming_xp": 0,
        "threat_kill_xp": 0
    }
