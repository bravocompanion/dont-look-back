extends SceneTree

const CASES: Array[Dictionary] = [
    {
        "name": "Ranger Forest",
        "path": "res://scenes/forest.tscn",
        "anchors": ["OutsideWorld/ForestGround"]
    },
    {
        "name": "Old Mine",
        "path": "res://scenes/mine.tscn",
        "anchors": ["MineWorld/Floor"]
    },
    {
        "name": "Labyrinth Level 03",
        "path": "res://scenes/main.tscn",
        "anchors": ["LabyrinthExpansion", "Arc1Expansion"]
    },
    {
        "name": "Research Facility",
        "path": "res://scenes/research_facility.tscn",
        "anchors": ["FacilityWorld/Floor"]
    }
]

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_regression")

func _run_regression() -> void:
    print("[REGRESSION] Don't Look Back v0.64 scene smoke starting...")
    _check_runtime_contracts()
    _check_v63_light_ownership_contracts()

    for case_data: Dictionary in CASES:
        await _boot_case(case_data)

    _check_export_presets()

    if failures.is_empty():
        print("[REGRESSION] PASS — canonical maps, v0.64 wildlife stability, light/ownership rules, pacing, and native presets are ready.")
        quit(0)
        return

    push_error("[REGRESSION] FAIL — %d issue(s)" % failures.size())
    for failure: String in failures:
        push_error("[REGRESSION] - %s" % failure)
    quit(1)

func _check_runtime_contracts() -> void:
    var contracts: Dictionary = {
        "NetworkManager": [
            "request_shared_shelter_action",
            "notify_local_inventory_delta_v60"
        ],
        "CheckpointSystem": [
            "prepare_team_wipe_restore_v59"
        ],
        "SaveSystem": [
            "build_checkpoint_shared_snapshot",
            "restore_checkpoint_shared_snapshot"
        ],
        "MinePowerSystem": [
            "get_save_state",
            "restore_save_state"
        ],
        "LabyrinthGameplayRules": [
            "request_stabilizer_v61",
            "can_use_breakers_v61",
            "get_enemy_pressure_bonus_v61"
        ],
        "ResearchFacilityPayoffSystem": [
            "request_choice_v61",
            "get_save_state",
            "restore_save_state",
            "get_campaign_outcome_v61",
            "has_rescue_priority_v62",
            "has_anomaly_priority_v62",
            "get_consequence_summary_v62"
        ],
        "HorrorPacingSystem": [
            "request_unease_v62",
            "request_stalk_v62",
            "get_state_name_v62",
            "get_pressure_v62",
            "get_safe_recovery_multiplier_v62",
            "reset_pacing_v62"
        ],
        "LightRegistry": [
            "is_player_protected_from_darkness_v63",
            "is_player_world_protected_v63",
            "is_position_world_protected_v63",
            "get_light_contract_v63",
            "invalidate_cache_v63"
        ],
        "DarknessDirector": [
            "get_runtime_owner_v63",
            "resolve_owner_for_mode_v63",
            "solo_spawn_allowed_for_mode_v63"
        ],
        "CoopHorrorSystem": [
            "get_light_authority_contract_v63"
        ]
    }

    for autoload_name_variant: Variant in contracts.keys():
        var autoload_name: String = str(autoload_name_variant)
        var node: Node = root.get_node_or_null(NodePath(autoload_name))
        if node == null:
            failures.append("autoload missing: %s" % autoload_name)
            continue
        for method_variant: Variant in Array(contracts[autoload_name_variant]):
            var method_name: String = str(method_variant)
            if not node.has_method(method_name):
                failures.append("%s missing method %s" % [autoload_name, method_name])

func _check_v63_light_ownership_contracts() -> void:
    var registry: Node = root.get_node_or_null("LightRegistry")
    var darkness: Node = root.get_node_or_null("DarknessDirector")
    var coop: Node = root.get_node_or_null("CoopHorrorSystem")
    if registry == null or darkness == null or coop == null:
        return

    var light_contract: Dictionary = Dictionary(registry.call("get_light_contract_v63"))
    if not bool(light_contract.get("darkness_accepts_flashlight", false)):
        failures.append("v0.63 light contract: Darkness must accept flashlight protection")
    if bool(light_contract.get("tenant_accepts_flashlight", true)):
        failures.append("v0.63 light contract: Tenant must reject flashlight as world protection")

    if not bool(darkness.call("solo_spawn_allowed_for_mode_v63", false)):
        failures.append("v0.63 ownership: offline Darkness director must own solo spawn")
    if bool(darkness.call("solo_spawn_allowed_for_mode_v63", true)):
        failures.append("v0.63 ownership: local Darkness director must stop spawning online")
    if str(darkness.call("resolve_owner_for_mode_v63", true)) != "coop_host":
        failures.append("v0.63 ownership: online Darkness owner must resolve to coop_host")

    var coop_contract: Dictionary = Dictionary(coop.call("get_light_authority_contract_v63"))
    if bool(coop_contract.get("tenant_uses_flashlight", true)):
        failures.append("v0.63 co-op contract: Tenant cannot use flashlight as protection")
    if not bool(coop_contract.get("darkness_uses_flashlight_or_world", false)):
        failures.append("v0.63 co-op contract: Darkness must use flashlight-or-world protection")

func _boot_case(case_data: Dictionary) -> void:
    var path: String = str(case_data.get("path", ""))
    var label: String = str(case_data.get("name", path))
    var change_error: Error = change_scene_to_file(path)
    if change_error != OK:
        failures.append("%s could not start: %s" % [label, error_string(change_error)])
        return

    var ready: bool = false
    for _frame_index: int in range(360):
        await process_frame
        var scene: Node = current_scene
        if scene == null or scene.scene_file_path != path:
            continue
        var player: CharacterBody3D = get_first_node_in_group("player") as CharacterBody3D
        if player == null:
            continue
        if not _anchors_ready(scene, Array(case_data.get("anchors", []))):
            continue
        ready = true
        break

    if not ready:
        failures.append("%s did not reach player + authored runtime anchors within 360 frames" % label)
        return

    print("[REGRESSION] PASS map: %s" % label)

    if path == "res://scenes/forest.tscn":
        _check_forest_authority_targets()
        _check_v62_pacing_runtime()
        await _check_v64_wildlife_runtime()
    elif path == "res://scenes/main.tscn":
        _check_checkpoint_snapshot_contract()
        await _check_labyrinth_rules_runtime()
    elif path == "res://scenes/research_facility.tscn":
        await _check_research_payoff_runtime()

func _anchors_ready(scene: Node, anchors: Array) -> bool:
    for anchor_variant: Variant in anchors:
        var anchor: String = str(anchor_variant)
        if scene.get_node_or_null(NodePath(anchor)) == null:
            return false
    return true

func _check_forest_authority_targets() -> void:
    var scene: Node = current_scene
    if scene == null:
        return
    for target: String in ["OutsideWorld/ShelterGenerator", "OutsideWorld/ShelterCampfire"]:
        if scene.get_node_or_null(NodePath(target)) == null:
            failures.append("Forest authority target missing: %s" % target)

func _check_v64_wildlife_runtime() -> void:
    var runtime: Node = null
    var deer: Node = null
    for _frame_index: int in range(240):
        await process_frame
        runtime = root.get_node_or_null("SurvivalSystem/ForestSurvivalRuntime")
        for candidate: Node in get_nodes_in_group("wildlife"):
            if str(candidate.get("animal_kind")) == "deer":
                deer = candidate
                break
        if runtime != null and deer != null:
            break

    if runtime == null:
        failures.append("v0.64 ForestSurvivalRuntime did not attach")
        return
    if not runtime.has_method("get_wildlife_runtime_contract_v64"):
        failures.append("v0.64 ForestSurvivalRuntime missing wildlife contract")
        return

    var runtime_contract: Dictionary = Dictionary(runtime.call("get_wildlife_runtime_contract_v64"))
    if str(runtime_contract.get("wildlife_script", "")) != "res://scripts/wildlife_animal_v64.gd":
        failures.append("v0.64 Forest runtime is not loading wildlife_animal_v64.gd")
    if str(runtime_contract.get("arrow_projectile_script", "")) != "res://scripts/forest_arrow_projectile_v64.gd":
        failures.append("v0.64 Forest runtime is not loading forest_arrow_projectile_v64.gd")
    if bool(runtime_contract.get("embedded_arrow_blocks_wildlife", true)):
        failures.append("v0.64 embedded arrow must not block wildlife")

    if deer == null:
        failures.append("v0.64 Forest did not spawn a deer for wildlife regression")
        return
    if not deer.has_method("get_flee_stability_contract_v64"):
        failures.append("v0.64 live deer is not using wildlife_animal_v64.gd")
        return

    var flee_contract: Dictionary = Dictionary(deer.call("get_flee_stability_contract_v64"))
    if bool(flee_contract.get("repeat_hit_speed_stacks", true)):
        failures.append("v0.64 repeat wildlife hits must not stack flee speed")
    var deer_speed_cap: float = float(flee_contract.get("speed_cap", 99.0))
    if deer_speed_cap > 2.641:
        failures.append("v0.64 deer flee speed cap regressed above 2.64 m/s")
    if float(flee_contract.get("heading_turn_rate_degrees", 0.0)) <= 0.0:
        failures.append("v0.64 deer flee heading must have a bounded positive turn rate")
    if float(flee_contract.get("repeat_hit_heading_lock_seconds", 0.0)) <= 0.0:
        failures.append("v0.64 repeat-hit heading lock is missing")

    var projectile_script: Script = load("res://scripts/forest_arrow_projectile_v64.gd") as Script
    if projectile_script == null:
        failures.append("v0.64 embedded-arrow projectile script failed to load")
        return
    var projectile: StaticBody3D = StaticBody3D.new()
    projectile.set_script(projectile_script)
    if not projectile.has_method("get_attachment_collision_contract_v64"):
        failures.append("v0.64 projectile missing attachment collision contract")
        projectile.free()
        return
    var arrow_contract: Dictionary = Dictionary(projectile.call("get_attachment_collision_contract_v64"))
    if int(arrow_contract.get("interaction_layer", 0)) != 2:
        failures.append("v0.64 attached recoverable arrow must use interaction-only layer 2")
    if bool(arrow_contract.get("blocks_wildlife", true)):
        failures.append("v0.64 attached recoverable arrow still reports blocking wildlife")
    if not bool(arrow_contract.get("explicit_collision_exception", false)):
        failures.append("v0.64 attached arrow must add an explicit collision exception")
    projectile.free()

func _check_v62_pacing_runtime() -> void:
    var pacing: Node = root.get_node_or_null("HorrorPacingSystem")
    if pacing == null:
        return
    pacing.call("reset_pacing_v62")
    pacing.call("request_unease_v62", "regression", 0.40, 2.0)
    if float(pacing.call("get_pressure_v62")) < 0.39:
        failures.append("v0.62 HorrorPacingSystem did not accept UNEASE pressure")
    pacing.call("request_stalk_v62", "regression", 2.0, 0.72)
    if float(pacing.call("get_pressure_v62")) < 0.70:
        failures.append("v0.62 HorrorPacingSystem did not accept STALK pressure")
    pacing.call("reset_pacing_v62")

func _check_checkpoint_snapshot_contract() -> void:
    var save: Node = root.get_node_or_null("SaveSystem")
    var player: CharacterBody3D = get_first_node_in_group("player") as CharacterBody3D
    if save == null or player == null or not save.has_method("build_checkpoint_shared_snapshot"):
        return
    var snapshot_value: Variant = save.call("build_checkpoint_shared_snapshot", player)
    if not (snapshot_value is Dictionary):
        failures.append("SaveSystem checkpoint snapshot did not return Dictionary")
        return
    var snapshot: Dictionary = Dictionary(snapshot_value)
    for required_key: String in ["world", "claimed_pickups", "investigation", "arc1", "mine_power_v59", "research_payoff_v61"]:
        if not snapshot.has(required_key):
            failures.append("checkpoint snapshot missing key: %s" % required_key)

func _check_labyrinth_rules_runtime() -> void:
    for _frame_index: int in range(180):
        await process_frame
        var scene: Node = current_scene
        if scene != null and scene.get_node_or_null("LabyrinthGameplayRulesV61/ArchiveStabilizer1") != null and scene.get_node_or_null("LabyrinthGameplayRulesV61/LockdownBeacon1") != null:
            return
    failures.append("v0.61 Labyrinth gameplay-rule runtime did not spawn stabilizers/beacons")

func _check_research_payoff_runtime() -> void:
    for _frame_index: int in range(240):
        await process_frame
        var scene: Node = current_scene
        if scene == null:
            continue
        var distress: Node = scene.get_node_or_null("ResearchPayoffV61/DistressChoiceTerminal")
        var containment: Node = scene.get_node_or_null("ResearchPayoffV61/ContainmentChoiceTerminal")
        var beacon: Node = scene.get_node_or_null("ResearchPayoffV61/ResponseBeacon1")
        if distress != null and containment != null and beacon != null:
            return
    failures.append("v0.61 Research Facility choice/payoff runtime did not spawn")

func _check_export_presets() -> void:
    var file: FileAccess = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
    if file == null:
        failures.append("export_presets.cfg could not be opened")
        return
    var text: String = file.get_as_text()
    file.close()
    for preset_name: String in ["Web", "Windows Desktop", "Linux Desktop", "Android Debug", "Android Release"]:
        if not text.contains("name=\"%s\"" % preset_name):
            failures.append("export preset missing: %s" % preset_name)
