extends "res://scripts/save_system.gd"

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"

var save_ui_initialized: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    save_exists = FileAccess.file_exists(SAVE_PATH)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    if scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        if layer != null:
            layer.visible = false
        return

    if not save_ui_initialized:
        _build_ui()
        save_ui_initialized = true
    if layer != null:
        layer.visible = true
    super._process(delta)

func _collect_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_state(player)
    state["map_scene"] = _current_map_scene_path()
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null and arc.has_method("get_save_state"):
        var arc_value: Variant = arc.call("get_save_state")
        if arc_value is Dictionary:
            state["arc1"] = Dictionary(arc_value).duplicate(true)
    return state

func _prepare_clean_reload() -> void:
    super._prepare_clean_reload()
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null and arc.has_method("reset_progress"):
        arc.call("reset_progress")

func _load_from_disk(automatic: bool) -> bool:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        _show_status("Load failed: cannot open save file.")
        return false

    var raw_text: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(raw_text)
    if not (parsed is Dictionary):
        _show_status("Load failed: save data is invalid.")
        return false

    var state: Dictionary = Dictionary(parsed)
    var format_version: int = int(state.get("format_version", 0))
    if format_version <= 0 or format_version > SAVE_FORMAT_VERSION:
        _show_status("Load failed: unsupported save version.")
        return false

    save_exists = true
    if not automatic:
        _prepare_clean_reload()
        _show_status("LOADING WORLD...")
    call_deferred("_load_scene_and_restore", state, automatic)
    return true

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
        _show_status("Load failed: target map could not load.")
        return

    var ready: bool = false
    for _frame_index: int in range(180):
        await get_tree().process_frame
        var scene: Node = get_tree().current_scene
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if scene == null or player == null or scene.scene_file_path != target_scene:
            continue
        if target_scene == FOREST_SCENE_PATH:
            ready = scene.get_node_or_null("OutsideWorld/ForestGround") != null
        else:
            ready = scene.get_node_or_null("LabyrinthExpansion") != null and scene.get_node_or_null("Arc1Expansion") != null
        if ready:
            break

    if not ready:
        _show_status("Load failed: map geometry was not ready.")
        return

    _restore_state(state)
    _show_status("SAVE RESTORED" if automatic else "WORLD LOADED")

func _restore_state(state: Dictionary) -> void:
    var migrated: Dictionary = state.duplicate(true)
    var normalized_claims: Array[String] = []
    var claimed_variant: Variant = migrated.get("claimed_pickups", [])
    if claimed_variant is Array:
        for path_variant: Variant in Array(claimed_variant):
            var normalized: String = _normalize_pickup_path(str(path_variant))
            if not normalized.is_empty() and not normalized_claims.has(normalized):
                normalized_claims.append(normalized)
    migrated["claimed_pickups"] = normalized_claims
    super._restore_state(migrated)

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    var arc_value: Variant = migrated.get("arc1", {})
    if arc != null and arc.has_method("restore_save_state") and arc_value is Dictionary:
        arc.call("restore_save_state", Dictionary(arc_value))

func register_claimed_pickup(node_path: String) -> void:
    var normalized: String = _normalize_pickup_path(node_path)
    if normalized.is_empty():
        return
    persistent_claimed_pickups[normalized] = true

func is_pickup_claimed(node_path: String) -> bool:
    var normalized: String = _normalize_pickup_path(node_path)
    return bool(persistent_claimed_pickups.get(normalized, false))

func _merge_network_claims() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        return
    var claimed: Dictionary = Dictionary(network.get("claimed_pickups"))
    for path_variant: Variant in claimed.keys():
        if not bool(claimed.get(path_variant, false)):
            continue
        var normalized: String = _normalize_pickup_path(str(path_variant))
        if not normalized.is_empty():
            persistent_claimed_pickups[normalized] = true

func _apply_claims_to_network() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    var scene: Node = get_tree().current_scene
    if network == null or scene == null:
        return
    var network_claims: Dictionary = {}
    for path_variant: Variant in persistent_claimed_pickups.keys():
        var normalized: String = _normalize_pickup_path(str(path_variant))
        var absolute_path: String = _absolute_pickup_path(normalized, scene)
        if not absolute_path.is_empty():
            network_claims[absolute_path] = true
    network.set("claimed_pickups", network_claims)

func _remove_current_claimed_nodes() -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    for path_variant: Variant in persistent_claimed_pickups.keys():
        var normalized: String = _normalize_pickup_path(str(path_variant))
        var pickup: Node = scene.get_node_or_null(NodePath(normalized))
        if pickup != null:
            pickup.queue_free()

func _current_map_scene_path() -> String:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path.is_empty():
        return LABYRINTH_SCENE_PATH
    if scene.scene_file_path == FOREST_SCENE_PATH:
        return FOREST_SCENE_PATH
    return LABYRINTH_SCENE_PATH

func _target_scene_for_state(state: Dictionary) -> String:
    var saved_scene: String = str(state.get("map_scene", ""))
    if saved_scene == FOREST_SCENE_PATH:
        return FOREST_SCENE_PATH
    if saved_scene == LABYRINTH_SCENE_PATH:
        return LABYRINTH_SCENE_PATH

    var player_state: Dictionary = Dictionary(state.get("player", {}))
    var position_variant: Variant = player_state.get("position", [])
    if position_variant is Array:
        var values: Array = Array(position_variant)
        if values.size() >= 3 and float(values[2]) <= -52.0:
            return FOREST_SCENE_PATH
    return LABYRINTH_SCENE_PATH

func _normalize_pickup_path(node_path: String) -> String:
    var path: String = node_path.strip_edges()
    if path.is_empty():
        return ""
    if path.begins_with("/root/"):
        var after_root: String = path.substr(6)
        var first_slash: int = after_root.find("/")
        if first_slash >= 0 and first_slash + 1 < after_root.length():
            return after_root.substr(first_slash + 1)
    return path.trim_prefix("/")

func _absolute_pickup_path(normalized_path: String, scene: Node) -> String:
    if normalized_path.is_empty() or scene == null:
        return ""
    return "%s/%s" % [str(scene.get_path()), normalized_path]
