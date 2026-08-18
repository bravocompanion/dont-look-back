extends "res://scripts/save_system_ranger.gd"

const STORY_VERSION_V2: int = 2
const FOREST_V2: String = "res://scenes/forest.tscn"
const MINE_V2: String = "res://scenes/mine.tscn"
const LABYRINTH_V2: String = "res://scenes/main.tscn"
const FACILITY_V2: String = "res://scenes/research_facility.tscn"
const START_POSITION_V2: Array = [14.0, 0.92, -90.0]

func _collect_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_state(player)
    state["ranger_story_version"] = STORY_VERSION_V2
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    if investigation != null and investigation.has_method("get_save_state"):
        var investigation_value: Variant = investigation.call("get_save_state")
        if investigation_value is Dictionary:
            state["investigation"] = Dictionary(investigation_value).duplicate(true)
    return state

func _prepare_clean_reload() -> void:
    super._prepare_clean_reload()
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    if investigation != null and investigation.has_method("reset_progress"):
        investigation.call("reset_progress")

func _current_map_scene_path() -> String:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return FOREST_V2
    var path: String = scene.scene_file_path
    if path in [FOREST_V2, MINE_V2, LABYRINTH_V2, FACILITY_V2]:
        return path
    return FOREST_V2

func _target_scene_for_state(state: Dictionary) -> String:
    if int(state.get("ranger_story_version", 0)) < STORY_VERSION_V2:
        return FOREST_V2
    var saved_scene: String = str(state.get("map_scene", ""))
    if saved_scene in [FOREST_V2, MINE_V2, LABYRINTH_V2, FACILITY_V2]:
        return saved_scene
    return FOREST_V2

func _load_scene_and_restore(state: Dictionary, automatic: bool) -> void:
    var target_scene: String = _target_scene_for_state(state)
    var current_scene: Node = get_tree().current_scene
    var current_path: String = current_scene.scene_file_path if current_scene != null else ""
    var change_error: Error = OK

    if current_path != target_scene:
        change_error = get_tree().change_scene_to_file(target_scene)
    elif not automatic:
        change_error = get_tree().reload_current_scene()

    if change_error != OK:
        _show_status("Load failed: target investigation map could not load.")
        return

    var ready: bool = false
    for _frame_index: int in range(180):
        await get_tree().process_frame
        var scene: Node = get_tree().current_scene
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if scene == null or player == null or scene.scene_file_path != target_scene:
            continue
        ready = _ranger_scene_ready(scene, target_scene)
        if ready:
            break

    if not ready:
        _show_status("Load failed: scene-specific world geometry was not ready.")
        return

    _restore_state(state)
    _show_status("SAVE RESTORED" if automatic else "WORLD LOADED")

func _restore_state(state: Dictionary) -> void:
    var migrated: Dictionary = state.duplicate(true)
    if int(migrated.get("ranger_story_version", 0)) < STORY_VERSION_V2:
        migrated["ranger_story_version"] = STORY_VERSION_V2
        migrated["map_scene"] = FOREST_V2
        var player_state: Dictionary = Dictionary(migrated.get("player", {})).duplicate(true)
        player_state["position"] = START_POSITION_V2.duplicate()
        player_state["rotation_y"] = 0.0
        migrated["player"] = player_state
        migrated["checkpoint"] = {}
        migrated["arc1"] = {}
        migrated["arc1_exploration"] = {}
        migrated["investigation"] = {}

    super._restore_state(migrated)

    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    var investigation_value: Variant = migrated.get("investigation", {})
    if investigation != null and investigation.has_method("restore_save_state") and investigation_value is Dictionary:
        investigation.call("restore_save_state", Dictionary(investigation_value))

func _ranger_scene_ready(scene: Node, scene_path: String) -> bool:
    match scene_path:
        FOREST_V2:
            return scene.get_node_or_null("OutsideWorld/ForestGround") != null
        MINE_V2:
            return scene.get_node_or_null("MineWorld/Floor") != null
        LABYRINTH_V2:
            return scene.get_node_or_null("LabyrinthExpansion") != null and scene.get_node_or_null("Arc1Expansion") != null
        FACILITY_V2:
            return scene.get_node_or_null("FacilityWorld/Floor") != null
    return false
