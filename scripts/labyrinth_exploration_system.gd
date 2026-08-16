extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const SHORTCUT_STAGE: Dictionary = {
    "maintenance_shortcut": 1,
    "flood_shortcut": 2
}
const SHORTCUT_DEEP_Z: Dictionary = {
    "maintenance_shortcut": -77.2,
    "flood_shortcut": -94.2
}

var configured_scene_id: int = 0
var exploration_root: Node3D
var shortcut_script: Script
var pickup_script: Script
var journal_note_script: Script
var unlocked_shortcuts: Dictionary = {}
var pending_restore_state: Dictionary = {}
var state_dirty: bool = true
var sync_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    shortcut_script = load("res://scripts/arc1_shortcut_door.gd") as Script
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    journal_note_script = load("res://scripts/journal_note.gd") as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        exploration_root = null
        configured_scene_id = 0
        return

    var arc_root: Node3D = scene.get_node_or_null("Arc1Expansion") as Node3D
    if arc_root == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        exploration_root = null
        call_deferred("_configure_scene", scene, arc_root)
        return

    if exploration_root == null or not is_instance_valid(exploration_root):
        return

    if _is_authoritative():
        sync_timer -= delta
        if state_dirty or sync_timer <= 0.0:
            sync_timer = 0.75
            if _network_online():
                _receive_exploration_state.rpc(get_save_state())
            state_dirty = false

func request_shortcut_unlock(shortcut_id: String) -> void:
    if not SHORTCUT_STAGE.has(shortcut_id):
        return
    if is_shortcut_unlocked(shortcut_id):
        return

    if _network_online() and not _is_authoritative():
        _request_shortcut_remote.rpc_id(1, shortcut_id)
        return

    var requester_id: int = multiplayer.get_unique_id() if _network_online() else 1
    _server_unlock_shortcut(shortcut_id, requester_id)

func is_shortcut_unlocked(shortcut_id: String) -> bool:
    return bool(unlocked_shortcuts.get(shortcut_id, false))

func get_save_state() -> Dictionary:
    return {
        "unlocked_shortcuts": unlocked_shortcuts.duplicate(true)
    }

func restore_save_state(state: Dictionary) -> void:
    pending_restore_state = state.duplicate(true)
    _apply_restored_state(state)

func reset_progress() -> void:
    unlocked_shortcuts.clear()
    pending_restore_state.clear()
    state_dirty = true
    _refresh_shortcut_nodes()

@rpc("any_peer", "call_remote", "reliable", 12)
func _request_shortcut_remote(shortcut_id: String) -> void:
    if not _is_authoritative():
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    _server_unlock_shortcut(shortcut_id, sender_id)

@rpc("authority", "call_remote", "reliable", 12)
func _receive_exploration_state(state: Dictionary) -> void:
    _apply_restored_state(state)

func _server_unlock_shortcut(shortcut_id: String, requester_id: int) -> void:
    if not SHORTCUT_STAGE.has(shortcut_id) or is_shortcut_unlocked(shortcut_id):
        return

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var required_stage: int = int(SHORTCUT_STAGE.get(shortcut_id, 99))
    if int(arc.get("current_stage")) < required_stage:
        _set_local_status("The service latch has no power yet.")
        return

    var requester_z: float = _requester_z(requester_id)
    var required_z: float = float(SHORTCUT_DEEP_Z.get(shortcut_id, -9999.0))
    if requester_z > required_z:
        _set_local_status("Shortcut is locked from the other side.")
        return

    unlocked_shortcuts[shortcut_id] = true
    state_dirty = true
    _refresh_shortcut_nodes()
    _set_local_status("SERVICE SHORTCUT UNLOCKED — backtracking route opened.")
    _request_autosave("Arc 1 shortcut unlocked")
    call_deferred("_rebuild_navigation_after_shortcut")

func _configure_scene(scene: Node, arc_root: Node3D) -> void:
    for _frame_index: int in range(45):
        await get_tree().process_frame
        if not is_instance_valid(scene) or get_tree().current_scene != scene:
            return
        if is_instance_valid(arc_root):
            break

    if not is_instance_valid(scene) or get_tree().current_scene != scene or not is_instance_valid(arc_root):
        return

    var old_root: Node = arc_root.get_node_or_null("ExplorationExpansion")
    if old_root != null:
        old_root.free()

    exploration_root = Node3D.new()
    exploration_root.name = "ExplorationExpansion"
    arc_root.add_child(exploration_root)

    _build_sector_readability()
    _build_optional_bays()
    _build_shortcuts(arc_root)
    _build_secret_finds()

    if not pending_restore_state.is_empty():
        _apply_restored_state(pending_restore_state)
    _refresh_shortcut_nodes()
    state_dirty = true

func _build_sector_readability() -> void:
    if exploration_root == null:
        return

    var yellow: Color = Color(0.72, 0.56, 0.18, 1.0)
    var blue: Color = Color(0.18, 0.48, 0.66, 1.0)
    var green: Color = Color(0.28, 0.58, 0.38, 1.0)
    var red: Color = Color(0.70, 0.20, 0.18, 1.0)

    _add_sector_sign("ArcLegend", "PIPE CODE  YELLOW=M  BLUE=F  GREEN=A  RED=L", Vector3(-6.8, 2.0, -52.4), Color(0.62, 0.64, 0.60, 1.0))
    _add_sector_sign("MaintenanceSign", "M-01  MAINTENANCE WING", Vector3(-7.0, 2.05, -57.2), yellow)
    _add_sector_sign("FloodSign", "F-02  FLOODED SERVICE", Vector3(0.0, 2.05, -82.6), blue)
    _add_sector_sign("ArchiveSign", "A-03  ARCHIVE", Vector3(0.0, 2.05, -108.0), green)
    _add_sector_sign("LockdownSign", "L-04  LOCKDOWN", Vector3(0.0, 2.05, -129.0), red)

    var maintenance_marks: Array[Vector3] = [Vector3(-10.5, 2.55, -61.0), Vector3(10.5, 2.55, -68.0), Vector3(-10.5, 2.55, -75.0)]
    var flood_marks: Array[Vector3] = [Vector3(-10.5, 2.55, -86.0), Vector3(10.5, 2.55, -94.0), Vector3(-10.5, 2.55, -101.5)]
    var archive_marks: Array[Vector3] = [Vector3(-10.5, 2.55, -110.5), Vector3(10.5, 2.55, -118.0), Vector3(-10.5, 2.55, -124.0)]
    var lockdown_marks: Array[Vector3] = [Vector3(-8.0, 2.55, -131.0), Vector3(0.0, 2.55, -135.0), Vector3(8.0, 2.55, -138.0)]

    _add_route_markers("M", maintenance_marks, yellow)
    _add_route_markers("F", flood_marks, blue)
    _add_route_markers("A", archive_marks, green)
    _add_route_markers("L", lockdown_marks, red)

    _add_landmark("MaintenanceLandmark", Vector3(-12.2, 0.0, -67.2), yellow, 2.15)
    _add_landmark("FloodLandmark", Vector3(12.1, 0.0, -92.0), blue, 1.75)
    _add_landmark("ArchiveLandmark", Vector3(-12.1, 0.0, -116.0), green, 2.35)
    _add_landmark("LockdownLandmark", Vector3(0.0, 0.0, -132.2), red, 2.55)

func _build_optional_bays() -> void:
    if exploration_root == null:
        return

    _add_optional_bay("MaintenanceStorage", "OPTIONAL  M-07 STORAGE", Vector3(11.5, 0.0, -74.0), Color(0.72, 0.56, 0.18, 1.0))
    _spawn_supply("maintenance_cache_battery", "flashlight_battery", "Flashlight Battery", Vector3(12.1, 0.05, -74.6))
    _spawn_supply("maintenance_cache_bandage", "bandage", "Bandage", Vector3(10.8, 0.05, -74.7))

    _add_optional_bay("FloodPumpAnnex", "OPTIONAL  F-09 PUMP ANNEX", Vector3(11.4, 0.0, -97.0), Color(0.18, 0.48, 0.66, 1.0))
    _spawn_supply("flood_cache_water", "bottled_water", "Bottled Water", Vector3(12.0, 0.05, -97.6))
    _spawn_supply("flood_cache_cloth", "cloth", "Cloth", Vector3(10.7, 0.05, -97.6))

    _add_optional_bay("ArchiveRecordsAnnex", "OPTIONAL  A-12 RECORDS ANNEX", Vector3(11.2, 0.0, -109.2), Color(0.28, 0.58, 0.38, 1.0))
    _spawn_supply("archive_cache_medkit", "medkit", "Medkit", Vector3(11.9, 0.05, -109.8))
    _spawn_supply("archive_cache_battery", "flashlight_battery", "Flashlight Battery", Vector3(10.6, 0.05, -109.8))

func _build_shortcuts(arc_root: Node3D) -> void:
    if exploration_root == null or shortcut_script == null:
        return

    _replace_wall_with_shortcut(arc_root, "MaintenanceWallC", -4.0, 19.5, -77.0, -4.0, "maintenance_shortcut", "M-01 Service Shortcut", -77.2)
    _replace_wall_with_shortcut(arc_root, "FloodWallB", -4.2, 19.0, -94.0, -4.2, "flood_shortcut", "F-02 Pump Shortcut", -94.2)

func _build_secret_finds() -> void:
    _spawn_note(
        "arc1_pipe_code",
        "Maintenance Color Code",
        "TIP",
        "Yellow conduit marks Maintenance. Blue marks Flooded Service. Green marks Archive. Red only appears near Lockdown. The workers navigated by pipe color when the signs failed.",
        Vector3(12.0, 0.06, -73.5)
    )
    _spawn_note(
        "arc1_records_margin",
        "Margin Note in Box A-12",
        "TRIVIA",
        "Someone wrote the same sentence on twelve inventory sheets: 'The corridors change when nobody is counting doors.' Every sheet lists a different number of doors.",
        Vector3(11.8, 0.06, -108.7)
    )

func _replace_wall_with_shortcut(arc_root: Node3D, wall_name: String, wall_center_x: float, wall_width: float, wall_z: float, gap_center_x: float, shortcut_id: String, display_name: String, required_z: float) -> void:
    var wall: CSGBox3D = arc_root.get_node_or_null(wall_name) as CSGBox3D
    var material: Material
    if wall != null:
        material = wall.material
        wall.free()
    if material == null:
        var fallback: StandardMaterial3D = StandardMaterial3D.new()
        fallback.albedo_color = Color(0.085, 0.09, 0.095, 1.0)
        fallback.roughness = 0.97
        material = fallback

    var gap_width: float = 2.6
    var wall_start: float = wall_center_x - wall_width * 0.5
    var wall_end: float = wall_center_x + wall_width * 0.5
    var left_end: float = gap_center_x - gap_width * 0.5
    var right_start: float = gap_center_x + gap_width * 0.5
    var left_width: float = maxf(0.1, left_end - wall_start)
    var right_width: float = maxf(0.1, wall_end - right_start)

    _add_csg_box("%sShortcutLeft" % wall_name, Vector3((wall_start + left_end) * 0.5, 1.5, wall_z), Vector3(left_width, 3.2, 0.24), material, true)
    _add_csg_box("%sShortcutRight" % wall_name, Vector3((right_start + wall_end) * 0.5, 1.5, wall_z), Vector3(right_width, 3.2, 0.24), material, true)

    var door: StaticBody3D = StaticBody3D.new()
    door.name = "Shortcut_%s" % shortcut_id
    door.position = Vector3(gap_center_x, 0.0, wall_z)
    door.set_script(shortcut_script)
    door.set("shortcut_id", shortcut_id)
    door.set("display_name", display_name)
    door.set("required_deeper_z", required_z)
    exploration_root.add_child(door)

func _add_sector_sign(node_name: String, text: String, position: Vector3, color: Color) -> void:
    if exploration_root == null:
        return
    var sign: Label3D = Label3D.new()
    sign.name = node_name
    sign.text = text
    sign.font_size = 34
    sign.modulate = color
    sign.position = position
    exploration_root.add_child(sign)

func _add_route_markers(prefix: String, positions: Array[Vector3], color: Color) -> void:
    for marker_index: int in range(positions.size()):
        var material: StandardMaterial3D = _emissive_material(color, 0.75)
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(2.8, 0.08, 0.10)
        var marker: MeshInstance3D = MeshInstance3D.new()
        marker.name = "%sRouteMarker%02d" % [prefix, marker_index]
        marker.mesh = mesh
        marker.material_override = material
        marker.position = positions[marker_index]
        exploration_root.add_child(marker)

func _add_landmark(node_name: String, position: Vector3, color: Color, height: float) -> void:
    var material: StandardMaterial3D = _emissive_material(color, 0.42)
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(0.48, height, 0.48)
    var landmark: MeshInstance3D = MeshInstance3D.new()
    landmark.name = node_name
    landmark.mesh = mesh
    landmark.material_override = material
    landmark.position = position + Vector3(0.0, height * 0.5, 0.0)
    exploration_root.add_child(landmark)

func _add_optional_bay(node_name: String, label_text: String, position: Vector3, color: Color) -> void:
    var floor_material: StandardMaterial3D = StandardMaterial3D.new()
    floor_material.albedo_color = Color(color.r * 0.16, color.g * 0.16, color.b * 0.16, 1.0)
    floor_material.roughness = 0.92
    _add_csg_box("%sFloor" % node_name, position + Vector3(0.0, 0.015, 0.0), Vector3(4.2, 0.03, 3.0), floor_material, false)

    var divider_material: StandardMaterial3D = StandardMaterial3D.new()
    divider_material.albedo_color = Color(0.11, 0.11, 0.10, 1.0)
    divider_material.roughness = 0.90
    _add_csg_box("%sDividerA" % node_name, position + Vector3(-1.9, 0.72, 0.6), Vector3(0.16, 1.44, 1.8), divider_material, true)

    _add_sector_sign("%sLabel" % node_name, label_text, position + Vector3(0.0, 1.85, -1.15), color)

    for crate_index: int in range(2):
        var crate_material: StandardMaterial3D = StandardMaterial3D.new()
        crate_material.albedo_color = Color(0.16, 0.13, 0.09, 1.0)
        crate_material.roughness = 0.92
        var crate_mesh: BoxMesh = BoxMesh.new()
        crate_mesh.size = Vector3(0.58, 0.52, 0.58)
        var crate: MeshInstance3D = MeshInstance3D.new()
        crate.name = "%sCrate%d" % [node_name, crate_index]
        crate.mesh = crate_mesh
        crate.material_override = crate_material
        crate.position = position + Vector3(1.25 - float(crate_index) * 0.72, 0.26, 0.75)
        exploration_root.add_child(crate)

func _spawn_supply(node_name: String, item_id: String, display_name: String, position: Vector3) -> void:
    if exploration_root == null or pickup_script == null:
        return
    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = node_name
    pickup.position = position
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", NodePath("../../../Player/HUD/Objective"))
    exploration_root.add_child(pickup)

func _spawn_note(entry_id: String, title: String, category: String, body: String, position: Vector3) -> void:
    if exploration_root == null or journal_note_script == null:
        return
    var note: StaticBody3D = StaticBody3D.new()
    note.name = "ExplorationNote_%s" % entry_id
    note.position = position
    note.set_script(journal_note_script)
    note.set("entry_id", entry_id)
    note.set("entry_title", title)
    note.set("entry_category", category)
    note.set("entry_body", body)
    exploration_root.add_child(note)

func _add_csg_box(node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool) -> CSGBox3D:
    var box: CSGBox3D = CSGBox3D.new()
    box.name = node_name
    box.position = position
    box.size = size
    box.material = material
    box.use_collision = collision
    exploration_root.add_child(box)
    return box

func _emissive_material(color: Color, emission_strength: float) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(color.r * 0.35, color.g * 0.35, color.b * 0.35, 1.0)
    material.roughness = 0.78
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = emission_strength
    return material

func _refresh_shortcut_nodes() -> void:
    if exploration_root == null:
        return
    for shortcut_id: String in SHORTCUT_STAGE.keys():
        var door: Node = exploration_root.get_node_or_null("Shortcut_%s" % shortcut_id)
        if door != null and door.has_method("set_unlocked_state"):
            door.call("set_unlocked_state", is_shortcut_unlocked(shortcut_id))

func _apply_restored_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    var shortcut_value: Variant = state.get("unlocked_shortcuts", {})
    if shortcut_value is Dictionary:
        unlocked_shortcuts = Dictionary(shortcut_value).duplicate(true)
    pending_restore_state = state.duplicate(true)
    state_dirty = true
    _refresh_shortcut_nodes()

func _requester_z(peer_id: int) -> float:
    if not _network_online() or peer_id == multiplayer.get_unique_id() or peer_id == 1 and _is_authoritative():
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        return player.global_position.z if player != null else INF

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null or not coop.has_method("_get_survivor_state"):
        return INF
    var state_value: Variant = coop.call("_get_survivor_state", peer_id)
    if not (state_value is Dictionary):
        return INF
    var state: Dictionary = Dictionary(state_value)
    var transform_value: Variant = state.get("transform", null)
    if transform_value is Transform3D:
        var survivor_transform: Transform3D = transform_value
        return survivor_transform.origin.z
    return INF

func _rebuild_navigation_after_shortcut() -> void:
    await get_tree().physics_frame
    await get_tree().physics_frame
    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation == null:
        return
    navigation.set("graph_ready", false)
    navigation.set("graph_retry_timer", 0.0)
    navigation.set("graph_point_count", 0)
    var graph_value: Variant = navigation.get("nav_graph")
    if graph_value is AStar3D:
        var graph: AStar3D = graph_value
        graph.clear()

func _request_autosave(reason: String) -> void:
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("request_autosave"):
        save_system.call("request_autosave", reason)

func _set_local_status(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _on_peer_connected(peer_id: int) -> void:
    if not _is_authoritative():
        return
    call_deferred("_send_state_to_peer", peer_id)

func _send_state_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    if _network_online():
        _receive_exploration_state.rpc_id(peer_id, get_save_state())

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))
