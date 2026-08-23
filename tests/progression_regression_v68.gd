extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _assert_true(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error("[v0.68 progression] %s" % message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        failures.append("%s — expected %s, got %s" % [message, str(expected), str(actual)])
        push_error("[v0.68 progression] %s — expected %s, got %s" % [message, str(expected), str(actual)])

func _assert_close(actual: float, expected: float, tolerance: float, message: String) -> void:
    if absf(actual - expected) > tolerance:
        failures.append("%s — expected %.4f, got %.4f" % [message, expected, actual])
        push_error("[v0.68 progression] %s — expected %.4f, got %.4f" % [message, expected, actual])

func _run() -> void:
    await process_frame
    await process_frame

    var progression: Node = root.get_node_or_null("ProgressionSystem")
    var carry: Node = root.get_node_or_null("CarryLimitSystem")
    var save: Node = root.get_node_or_null("SaveSystem")
    var consumable: Node = root.get_node_or_null("ConsumableActionSystem")

    _assert_true(progression != null, "ProgressionSystem autoload exists")
    _assert_true(carry != null, "CarryLimitSystem autoload exists")
    _assert_true(save != null, "SaveSystem autoload exists")
    _assert_true(consumable != null, "ConsumableActionSystem autoload exists")
    if progression == null:
        quit(1)
        return

    progression.call("reset_progression_v68", false)
    _assert_eq(int(progression.call("get_level_v68")), 1, "starts at level 1")
    _assert_eq(int(progression.call("get_talent_points_v68")), 0, "starts with zero talent points")
    _assert_eq(int(progression.call("get_stat_points_v68")), 0, "starts with zero stat points")
    _assert_eq(int(progression.call("xp_to_next_level_v68", 1)), 120, "level 1 XP threshold is 120")

    progression.call("add_xp_v68", 120, "test", "general")
    _assert_eq(int(progression.call("get_level_v68")), 2, "120 XP reaches level 2")
    _assert_eq(int(progression.call("get_talent_points_v68")), 1, "level 2 grants one talent point")
    _assert_eq(int(progression.call("get_stat_points_v68")), 1, "even level grants one stat point")

    _assert_true(bool(progression.call("spend_stat_point_v68", "endurance")), "can allocate Endurance")
    _assert_eq(int(progression.call("get_stat_v68", "endurance")), 1, "Endurance increases to 1")
    _assert_close(float(progression.call("get_max_carry_bonus_v68")), 0.10, 0.001, "Endurance gives 0.10 kg carry tolerance")

    _assert_true(bool(progression.call("unlock_talent_v68", "evidence_analyst")), "can unlock Evidence Analyst at level 2")
    _assert_eq(int(progression.call("get_talent_rank_v68", "evidence_analyst")), 1, "Evidence Analyst rank is stored")
    var xp_before_evidence: int = int(progression.call("get_xp_v68"))
    progression.call("record_evidence_for_peer_v68", 1, "survey_manifest")
    var xp_after_evidence: int = int(progression.call("get_xp_v68"))
    _assert_eq(xp_after_evidence - xp_before_evidence, 33, "Evidence Analyst applies +10% evidence XP")
    _assert_true(bool(progression.call("has_knowledge_v68", "survey_team")), "evidence unlocks mapped knowledge")
    progression.call("record_evidence_for_peer_v68", 1, "survey_manifest")
    _assert_eq(int(progression.call("get_xp_v68")), xp_after_evidence, "same evidence cannot farm XP")

    var save_state: Dictionary = Dictionary(progression.call("get_save_state"))
    progression.call("reset_progression_v68", false)
    _assert_eq(int(progression.call("get_level_v68")), 1, "reset returns to level 1")
    progression.call("restore_save_state", save_state)
    _assert_eq(int(progression.call("get_level_v68")), 2, "restore returns saved level")
    _assert_true(bool(progression.call("has_knowledge_v68", "survey_team")), "knowledge survives restore")
    _assert_eq(int(progression.call("get_talent_rank_v68", "evidence_analyst")), 1, "talent survives restore")

    var authored_state: Dictionary = {
        "level": 20,
        "xp_in_level": 0,
        "talent_points": 5,
        "stat_points": 0,
        "stats": {"endurance": 10, "fitness": 5, "fortitude": 6, "focus": 8, "dexterity": 4},
        "talent_ranks": {
            "efficient_metabolism": 2,
            "pack_discipline": 1,
            "load_bearing": 2,
            "runner": 2,
            "quiet_steps": 2,
            "pathfinder": 2,
            "field_medic": 2,
            "steady_hands": 2,
            "fuel_economy": 2,
            "evidence_analyst": 0
        },
        "knowledge": {"ranger_yard": true},
        "claimed_xp_events": {}
    }
    progression.call("restore_save_state", authored_state)
    _assert_close(float(progression.call("get_max_carry_bonus_v68")), 3.0, 0.001, "Endurance + Load Bearing give deterministic carry bonus")
    _assert_close(float(progression.call("get_loaded_ratio_v68")), 0.75, 0.001, "Pack Discipline shifts LOADED threshold to 75%")
    _assert_close(float(progression.call("get_sprint_drain_multiplier_v68")), 0.92, 0.001, "Runner rank 2 reduces sprint drain 8%")
    _assert_close(float(progression.call("get_noise_multiplier_v68")), 0.92, 0.001, "Quiet Steps rank 2 reduces player noise 8%")
    _assert_close(float(progression.call("get_metabolism_multiplier_v68")), 0.91, 0.001, "Fortitude and Efficient Metabolism stack conservatively")
    _assert_close(float(progression.call("get_movement_multiplier_v68")), 1.02, 0.001, "Fitness and Pathfinder produce capped movement bonus")
    _assert_close(float(progression.call("get_panic_multiplier_v68")), 0.82, 0.001, "Focus and Steady Hands reduce effective panic")
    _assert_close(float(progression.call("get_consumable_duration_multiplier_v68")), 0.82, 0.001, "Dexterity and Field Medic reduce vulnerable use time")
    _assert_close(float(progression.call("get_generator_fuel_effectiveness_v68")), 1.12, 0.001, "Fuel Economy rank 2 gives 12% effectiveness")

    if carry != null and carry.has_method("get_max_weight"):
        _assert_close(float(carry.call("get_max_weight", null)), 35.0, 0.001, "effective carry capacity uses progression bonus above 32 kg base")
    if consumable != null and consumable.has_method("get_progression_consumable_contract_v68"):
        var contract: Dictionary = Dictionary(consumable.call("get_progression_consumable_contract_v68"))
        _assert_true(bool(contract.get("consumption_still_vulnerable", false)), "talent does not remove vulnerable consumable behavior")

    if save != null and save.has_method("get_progression_save_contract_v68"):
        var save_contract: Dictionary = Dictionary(save.call("get_progression_save_contract_v68"))
        _assert_eq(bool(save_contract.get("checkpoint_death_rolls_progression_back", true)), false, "checkpoint rollback does not erase survivor progression")
        _assert_true(bool(save_contract.get("multiplayer_client_profile_supported", false)), "client local profile contract is enabled")

    progression.call("reset_progression_v68", false)
    progression.call("add_xp_v68", 1000000, "max level test", "general")
    _assert_eq(int(progression.call("get_level_v68")), 30, "level is capped at 30")
    _assert_eq(int(progression.call("get_talent_points_v68")), 29, "level 30 grants 29 total talent points from level-ups")
    _assert_eq(int(progression.call("get_stat_points_v68")), 15, "levels 2..30 grant 15 stat points on even levels")
    _assert_eq(int(progression.call("get_xp_v68")), 0, "XP does not accumulate beyond max level")

    var high_tier_state: Dictionary = progression.call("get_save_state")
    high_tier_state["level"] = 20
    high_tier_state["talent_points"] = 1
    high_tier_state["talent_ranks"] = {"load_bearing": 0, "pack_discipline": 0}
    progression.call("restore_save_state", high_tier_state)
    _assert_eq(bool(progression.call("unlock_talent_v68", "load_bearing")), false, "talent prerequisite cannot be bypassed by level alone")

    progression.call("reset_progression_v68", false)
    if failures.is_empty():
        print("[v0.68 progression] PASS")
        quit(0)
    else:
        print("[v0.68 progression] FAIL count=%d" % failures.size())
        quit(1)
