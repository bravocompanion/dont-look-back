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
    print("[REGRESSION] Don't Look Back v0.61 scene smoke starting...")
    _check_runtime_contracts()

    for case_data: Dictionary in CASES:
        await _boot_case(case_data)

    _check_export_presets()

    if failures.is_empty():
        print("[REGRESSION] PASS — canonical maps, v0.61 gameplay rules, and native presets are ready.")
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
            "get_campaign_outcome_v61"
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
