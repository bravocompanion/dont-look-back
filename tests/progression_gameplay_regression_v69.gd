extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run_v69")

func _run_v69() -> void:
    await process_frame
    await process_frame

    var progression: Node = root.get_node_or_null("ProgressionSystem")
    _check(progression != null, "ProgressionSystem autoload exists")
    if progression == null:
        _finish_v69()
        return

    _check(progression.has_method("record_milestone_v69"), "v0.69 milestone API exists")
    _check(progression.has_method("xp_to_next_level_v68"), "v0.68 level curve retained")
    progression.call("reset_progression_v68", false)

    _check(int(progression.get("level")) == 1, "fresh survivor starts Level 1")
    _check(int(progression.call("xp_to_next_level_v68", 1)) == 120, "Level 1 threshold remains 120 XP")

    var water_first: bool = bool(progression.call(
        "record_milestone_v69", "water:first_safe_boil", 30,
        "First safe water processed", "water_safety", "survival"
    ))
    _check(water_first, "first safe-water milestone awards")
    _check(int(progression.get("xp_in_level")) == 30, "safe water grants 30 XP")
    _check(bool(progression.call("has_knowledge_v68", "water_safety")), "safe water unlocks Water Safety knowledge")

    var water_repeat: bool = bool(progression.call(
        "record_milestone_v69", "water:first_safe_boil", 30,
        "First safe water processed", "water_safety", "survival"
    ))
    _check(not water_repeat, "safe-water milestone cannot be farmed")
    _check(int(progression.get("xp_in_level")) == 30, "repeat safe water grants no XP")

    progression.call(
        "record_milestone_v69", "wildlife_harvest:first", 40,
        "First wildlife harvest", "wildlife_anatomy", "survival"
    )
    progression.call(
        "record_milestone_v69", "fishing:first_catch", 30,
        "First successful fishing catch", "wildlife_anatomy", "survival"
    )
    progression.call(
        "record_milestone_v69", "medicine:first_completed_medkit", 20,
        "First completed field treatment", "field_medicine", "survival"
    )

    _check(int(progression.get("level")) == 2, "four first-survival milestones total 120 XP and reach Level 2")
    _check(int(progression.get("xp_in_level")) == 0, "Level 2 starts at zero overflow for exact 120 XP")
    _check(int(progression.get("talent_points")) == 1, "Level 2 grants one Talent Point")
    _check(int(progression.get("stat_points")) == 1, "even Level 2 grants one Stat Point")
    _check(bool(progression.call("has_knowledge_v68", "wildlife_anatomy")), "harvest/fishing unlock Wildlife Anatomy")
    _check(bool(progression.call("has_knowledge_v68", "field_medicine")), "completed medkit unlocks Field Medicine")
    _check(int(progression.call("xp_to_next_level_v68", 2)) == 179, "v0.68 Level 2 curve remains unchanged")

    var before_repeat_level: int = int(progression.get("level"))
    var before_repeat_xp: int = int(progression.get("xp_in_level"))
    progression.call("record_milestone_v69", "wildlife_harvest:first", 40, "repeat", "wildlife_anatomy", "survival")
    progression.call("record_milestone_v69", "fishing:first_catch", 30, "repeat", "wildlife_anatomy", "survival")
    progression.call("record_milestone_v69", "medicine:first_completed_medkit", 20, "repeat", "field_medicine", "survival")
    _check(int(progression.get("level")) == before_repeat_level, "repeat survival actions do not add levels")
    _check(int(progression.get("xp_in_level")) == before_repeat_xp, "repeat survival actions do not add XP")

    var gameplay_contract: Dictionary = Dictionary(progression.call("get_progression_gameplay_contract_v69"))
    _check(not bool(gameplay_contract.get("level_curve_changed", true)), "v0.69 does not migrate/change level curve")
    _check(not bool(gameplay_contract.get("profile_format_changed", true)), "v0.69 keeps local profile format")
    _check(int(gameplay_contract.get("normal_resource_farming_xp", -1)) == 0, "normal resource farming remains zero XP")
    _check(int(gameplay_contract.get("threat_kill_xp", -1)) == 0, "threat kills remain zero XP")

    var profile_contract: Dictionary = Dictionary(progression.call("get_profile_contract_v68"))
    _check(str(profile_contract.get("path", "")).contains("progression_v68"), "existing survivor progression profile path retained")

    var feedback: Node = root.get_node_or_null("ProgressionFeedbackHUD")
    _check(feedback != null, "ProgressionFeedbackHUD autoload exists")
    if feedback != null:
        var hud_contract: Dictionary = Dictionary(feedback.call("get_feedback_hud_contract_v69"))
        _check(bool(hud_contract.get("shows_xp_progress", false)), "HUD shows XP progress")
        _check(bool(hud_contract.get("mobile_responsive", false)), "HUD contract is mobile responsive")
        _check(bool(hud_contract.get("desktop_responsive", false)), "HUD contract is desktop responsive")

    var depth: Node = root.get_node_or_null("SurvivalDepthSystem")
    _check(depth != null and depth.has_method("get_water_progression_contract_v69"), "water milestone runtime active")
    if depth != null and depth.has_method("get_water_progression_contract_v69"):
        var water_contract: Dictionary = Dictionary(depth.call("get_water_progression_contract_v69"))
        _check(int(water_contract.get("repeat_boil_xp", -1)) == 0, "repeat boiling is not XP grind")

    var consumable: Node = root.get_node_or_null("ConsumableActionSystem")
    _check(consumable != null and consumable.has_method("get_medical_progression_contract_v69"), "medical milestone runtime active")
    if consumable != null and consumable.has_method("get_medical_progression_contract_v69"):
        var medical_contract: Dictionary = Dictionary(consumable.call("get_medical_progression_contract_v69"))
        _check(int(medical_contract.get("interrupted_medkit_xp", -1)) == 0, "interrupted medkit gives zero XP")

    _check(str(ProjectSettings.get_setting("application/config/name", "")).contains("v0.69"), "project version is v0.69")
    _finish_v69()

func _check(condition: bool, description: String) -> void:
    if condition:
        print("[v0.69 PASS] %s" % description)
    else:
        failures.append(description)
        push_error("[v0.69 FAIL] %s" % description)

func _finish_v69() -> void:
    if failures.is_empty():
        print("v0.69 progression gameplay regression: PASS")
        quit(0)
        return
    push_error("v0.69 progression gameplay regression: %d failure(s)" % failures.size())
    for failure: String in failures:
        push_error(" - %s" % failure)
    quit(1)
