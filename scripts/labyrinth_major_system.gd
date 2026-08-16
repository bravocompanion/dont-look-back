extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const ISOLATION_IDS: Array[String] = ["isolation_maintenance", "isolation_flood", "isolation_archive"]
const USE_DISTANCE: float = 3.5
const SHUTTER_DURATION: float = 7.5

var configured_scene_id: int = 0
var major_root: Node3D
var isolation_script: Script
var warden_script: Script
var route_variant: int = -1
var completed_nodes: Dictionary = {}
var warden_active: bool = false
var finale_phase: int = 0
var last_finale_phase: int = 0
var sync_timer: float = 0.0
var state_dirty: bool = true
var layout_rebuild_pending: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    isolation_script = load("res://scripts/arc1_isolation_node.gd") as Script
    warden_script = load("res://scripts/arc1_warden.gd") as Script
    rng.randomize()
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        configured_scene_id = 0
        major_root = null
        warden_active = false
        finale_phase = 0
        last_finale_phase = 0
        return

    var arc_root: Node3D = scene.get_node_or_null("Arc1Expansion") as Node3D
    if arc_root == null:
        return

    _sync_completed_from_arc()
    _ensure_route_variant()

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        major_root = null
        call_deferred("_configure_scene", scene, arc_root)
        return

    if layout_rebuild_pending and major_root != null and is_instance_valid(major_root):
        layout_rebuild_pending = false
        call_deferred("_rebuild_layout", scene, arc_root)
        return

    if major_root == null or not is_instance_valid(major_root):
        return

    if _is_authoritative():
        _update_major_state()
        sync_timer -= delta
        if state_dirty or sync_timer <= 0.0:
            sync_timer = 0.40
            if _network_online():
                _receive_major_state.rpc(get_network_state())
            state_dirty = false

func request_isolation_node(node_id: String) -> void:
    if not ISOLATION_IDS.has(node_id):
        return
    if bool(completed_nodes.get(node_id, false)):
        return

    if _network_online() and not _is_authoritative():
        _request_isolation_remote.rpc_id(1, node_id)
        return

    var requester_id: int = multiplayer.get_unique_id() if _network_online() else 1
    _server_complete_isolation(node_id, requester_id)

func is_lockdown_ready() -> bool:
    return get_isolation_completed_count() >= ISOLATION_IDS.size()

func get_isolation_completed_count() -> int:
    var count: int = 0
    for node_id: String in ISOLATION_IDS:
        if bool(completed_nodes.get(node_id, false)):
            count += 1
    return count

func get_isolation_prompt(node_id: String, display_name: String) -> String:
    if bool(completed_nodes.get(node_id, false)):
        return "%s — isolated" % display_name
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return "%s — offline" % display_name
    var stage: int = int(arc.get("current_stage"))
    if stage < 4:
        return "%s — sealed until Archive power is restored" % display_name
    if bool(arc.get("holdout_active")) or bool(Dictionary(arc.get("completed")).get("lockdown", false)):
        return "%s — cycle already committed" % display_name
    return "Shut down %s" % display_name

func get_isolation_visual_state(node_id: String) -> int:
    if bool(completed_nodes.get(node_id, false)):
        return 2
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null and int(arc.get("current_stage")) >= 4 and not bool(arc.get("holdout_active")):
        return 1
    return 0

func is_warden_active() -> bool:
    return warden_active

func get_warden_aggression_multiplier() -> float:
    var multiplier: float = 1.0 + float(get_isolation_completed_count()) * 0.10
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null and bool(arc.get("holdout_active")):
        multiplier += 0.10 * float(maxi(0, finale_phase - 1))
    return multiplier

func get_finale_phase() -> int:
    return finale_phase

func get_route_variant() -> int:
    return maxi(0, route_variant)

func get_network_state() -> Dictionary:
    return {
        "route_variant": route_variant,
        "completed_nodes": completed_nodes.duplicate(true),
        "warden_active": warden_active,
        "finale_phase": finale_phase
    }

@rpc("any_peer", "call_remote", "reliable", 14)
func _request_isolation_remote(node_id: String) -> void:
    if not _is_authoritative():
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    _server_complete_isolation(node_id, sender_id)

@rpc("authority", "call_remote", "reliable", 14)
func _receive_major_state(state: Dictionary) -> void:
    _apply_network_state(state)

@rpc("authority", "call_remote", "reliable", 14)
func _receive_major_feedback(text: String) -> void:
    _set_local_status(text)

@rpc("authority", "call_remote", "reliable", 14)
func _receive_shutter_event(node_id: String, variant: int, duration: float) -> void:
    _spawn_temporary_shutter(node_id, variant, duration)

func _server_complete_isolation(node_id: String, requester_id: int) -> void:
    if not ISOLATION_IDS.has(node_id) or bool(completed_nodes.get(node_id, false)):
        return

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null or int(arc.get("current_stage")) != 4 or bool(arc.get("holdout_active")):
        _feedback_to_peer(requester_id, "Isolation controls are not available yet.")
        return

    var requester_position: Vector3 = _requester_position(requester_id)
    var node_position: Vector3 = _node_position(node_id, route_variant)
    if requester_position == Vector3.INF or requester_position.distance_to(node_position) > USE_DISTANCE:
        _feedback_to_peer(requester_id, "Move closer to the Isolation Node.")
        return

    completed_nodes[node_id] = true
    _persist_node_to_arc(node_id)
    _trigger_isolation_event(node_id)
    state_dirty = true

    var completed_count: int = get_isolation_completed_count()
    if completed_count >= ISOLATION_IDS.size():
        _set_local_status("ISOLATION SWEEP COMPLETE — return to L-04 Lockdown Console.")
        _feedback_to_peer(requester_id, "All isolation circuits are down. Lockdown Console is ready.")
        _request_autosave("Arc 1 isolation sweep complete")
    else:
        _feedback_to_peer(requester_id, "Isolation Node offline — %d / %d. The Warden is moving." % [completed_count, ISOLATION_IDS.size()])
        _request_autosave("Arc 1 isolation node")

func _trigger_isolation_event(node_id: String) -> void:
    var position: Vector3 = _node_position(node_id, route_variant)
    _report_noise(position, 1.22, "isolation circuit collapse")

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null:
        arc.set("fault_timer", maxf(float(arc.get("fault_timer")), 7.5))
        arc.set("state_dirty", true)

    var director: Node = get_node_or_null("/root/LabyrinthEncounterDirector")
    if director != null:
        director.set("encounter_timer", minf(float(director.get("encounter_timer")), 4.0))
        director.set("horror_event_timer", minf(float(director.get("horror_event_timer")), 8.0))

    _spawn_temporary_shutter(node_id, route_variant, SHUTTER_DURATION)
    if _network_online():
        _receive_shutter_event.rpc(node_id, route_variant, SHUTTER_DURATION)

func _update_major_state() -> void:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return

    var stage: int = int(arc.get("current_stage"))
    var holdout: bool = bool(arc.get("holdout_active"))
    var lockdown_complete: bool = bool(Dictionary(arc.get("completed")).get("lockdown", false))
    var previous_warden: bool = warden_active

    if stage == 4 and not is_lockdown_ready() and not holdout:
        warden_active = true
    elif holdout:
        warden_active = float(arc.get("holdout_remaining")) <= 100.0
    else:
        warden_active = false

    if lockdown_complete:
        warden_active = false

    if warden_active != previous_warden:
        state_dirty = true

    var next_phase: int = _compute_finale_phase(arc)
    if next_phase != finale_phase:
        finale_phase = next_phase
        state_dirty = true
    if finale_phase != last_finale_phase:
        _on_finale_phase_changed(last_finale_phase, finale_phase)
        last_finale_phase = finale_phase

func _compute_finale_phase(arc: Node) -> int:
    if not bool(arc.get("holdout_active")):
        return 0
    var remaining: float = float(arc.get("holdout_remaining"))
    if remaining > 80.0:
        return 1
    if remaining > 40.0:
        return 2
    return 3

func _on_finale_phase_changed(_old_phase: int, new_phase: int) -> void:
    if new_phase <= 0:
        return
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    var director: Node = get_node_or_null("/root/LabyrinthEncounterDirector")
    if arc != null:
        var fault: float = 3.5 if new_phase == 1 else 5.0 + float(new_phase)
        arc.set("fault_timer", maxf(float(arc.get("fault_timer")), fault))
        arc.set("state_dirty", true)
    if director != null:
        var encounter_limit: float = 8.0 if new_phase == 1 else 5.5 if new_phase == 2 else 3.5
        var horror_limit: float = 13.0 if new_phase == 1 else 9.0 if new_phase == 2 else 6.0
        director.set("encounter_timer", minf(float(director.get("encounter_timer")), encounter_limit))
        director.set("horror_event_timer", minf(float(director.get("horror_event_timer")), horror_limit))
    _report_noise(Vector3(0.0, 0.0, -135.0), 0.90 + float(new_phase) * 0.12, "lockdown phase %d" % new_phase)

func _configure_scene(scene: Node, arc_root: Node3D) -> void:
    for _frame_index: int in range(60):
        await get_tree().process_frame
        if not is_instance_valid(scene) or get_tree().current_scene != scene:
            return
        if is_instance_valid(arc_root):
            break

    if not is_instance_valid(scene) or get_tree().current_scene != scene or not is_instance_valid(arc_root):
        return
    _ensure_route_variant()
    _build_layout(arc_root)

func _rebuild_layout(scene: Node, arc_root: Node3D) -> void:
    await get_tree().process_frame
    if not is_instance_valid(scene) or get_tree().current_scene != scene or not is_instance_valid(arc_root):
        return
    _build_layout(arc_root)

func _build_layout(arc_root: Node3D) -> void:
    var old_root: Node = arc_root.get_node_or_null("MajorExpansion")
    if old_root != null:
        old_root.free()

    major_root = Node3D.new()
    major_root.name = "MajorExpansion"
    arc_root.add_child(major_root)

    _spawn_isolation_node("isolation_maintenance", "M-01 Isolation Node", _node_position("isolation_maintenance", route_variant))
    _spawn_isolation_node("isolation_flood", "F-02 Isolation Node", _node_position("isolation_flood", route_variant))
    _spawn_isolation_node("isolation_archive", "A-03 Isolation Node", _node_position("isolation_archive", route_variant))
    _build_guidance_lights()
    _spawn_warden()
    state_dirty = true

func _spawn_isolation_node(node_id: String, display_name: String, position: Vector3) -> void:
    if major_root == null or isolation_script == null:
        return
    var node: StaticBody3D = StaticBody3D.new()
    node.name = "Isolation_%s" % node_id
    node.position = position
    node.set_script(isolation_script)
    node.set("node_id", node_id)
    node.set("display_name", display_name)
    major_root.add_child(node)

func _spawn_warden() -> void:
    if major_root == null or warden_script == null:
        return
    var warden: Node3D = Node3D.new()
    warden.name = "TheWarden"
    warden.position = Vector3(0.0, 0.0, -107.5)
    warden.set_script(warden_script)
    major_root.add_child(warden)

func _build_guidance_lights() -> void:
    if major_root == null:
        return
    var positions: Array[Vector3] = [
        Vector3(-12.2, 0.16, -60.0), Vector3(11.8, 0.16, -67.5), Vector3(-11.8, 0.16, -75.0),
        Vector3(-11.8, 0.16, -87.0), Vector3(11.8, 0.16, -96.0), Vector3(-11.8, 0.16, -102.5),
        Vector3(-11.6, 0.16, -111.0), Vector3(11.6, 0.16, -118.0), Vector3(-11.6, 0.16, -124.5),
        Vector3(-8.5, 0.16, -130.5), Vector3(0.0, 0.16, -134.0), Vector3(8.5, 0.16, -137.5)
    ]
    for index: int in range(positions.size()):
        var color: Color = Color(0.52, 0.15, 0.09, 1.0) if index >= 9 else Color(0.30, 0.24, 0.13, 1.0)
        var material: StandardMaterial3D = StandardMaterial3D.new()
        material.albedo_color = Color(color.r * 0.28, color.g * 0.28, color.b * 0.28, 1.0)
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 0.62
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(0.58, 0.035, 0.18)
        var strip: MeshInstance3D = MeshInstance3D.new()
        strip.name = "MajorGuideStrip%02d" % index
        strip.mesh = mesh
        strip.material_override = material
        strip.position = positions[index]
        major_root.add_child(strip)

        var light: OmniLight3D = OmniLight3D.new()
        light.name = "MajorGuideLight%02d" % index
        light.position = positions[index] + Vector3(0.0, 0.08, 0.0)
        light.light_color = color
        light.light_energy = 0.072 if index < 9 else 0.084
        light.omni_range = 2.2
        light.shadow_enabled = false
        major_root.add_child(light)

func _spawn_temporary_shutter(node_id: String, variant: int, duration: float) -> void:
    if major_root == null or not is_instance_valid(major_root):
        return
    var shutter_name: String = "MajorShutter_%s" % node_id
    var old: Node = major_root.get_node_or_null(shutter_name)
    if old != null:
        old.queue_free()

    var body: StaticBody3D = StaticBody3D.new()
    body.name = shutter_name
    body.position = _shutter_position(node_id, variant)
    major_root.add_child(body)

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.095, 0.075, 1.0)
    material.metallic = 0.58
    material.roughness = 0.50
    material.emission_enabled = true
    material.emission = Color(0.42, 0.06, 0.025, 1.0)
    material.emission_energy_multiplier = 0.48

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(4.4, 2.85, 0.24)
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = material
    visual.position.y = 1.42
    body.add_child(visual)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(4.4, 2.85, 0.30)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 1.42
    body.add_child(collision)

    _expire_shutter(body, duration)

func _expire_shutter(body: StaticBody3D, duration: float) -> void:
    await get_tree().create_timer(maxf(1.0, duration)).timeout
    if body != null and is_instance_valid(body):
        body.queue_free()

func _node_position(node_id: String, variant: int) -> Vector3:
    var safe_variant: int = posmod(variant, 3)
    if node_id == "isolation_maintenance":
        if safe_variant == 0:
            return Vector3(-11.2, 0.0, -73.6)
        if safe_variant == 1:
            return Vector3(10.8, 0.0, -61.8)
        return Vector3(10.8, 0.0, -75.8)
    if node_id == "isolation_flood":
        if safe_variant == 0:
            return Vector3(11.0, 0.0, -88.4)
        if safe_variant == 1:
            return Vector3(-11.0, 0.0, -99.6)
        return Vector3(-10.8, 0.0, -91.8)
    if safe_variant == 0:
        return Vector3(-10.8, 0.0, -118.0)
    if safe_variant == 1:
        return Vector3(10.8, 0.0, -123.4)
    return Vector3(10.6, 0.0, -111.8)

func _shutter_position(node_id: String, variant: int) -> Vector3:
    var safe_variant: int = posmod(variant, 3)
    if node_id == "isolation_maintenance":
        return Vector3(8.8 if safe_variant != 1 else -8.8, 0.0, -71.5 if safe_variant == 0 else -64.0)
    if node_id == "isolation_flood":
        return Vector3(-8.8 if safe_variant != 2 else 8.8, 0.0, -94.0 if safe_variant == 0 else -101.0)
    return Vector3(0.0, 0.0, -127.0)

func _ensure_route_variant() -> void:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var arc_completed: Dictionary = Dictionary(arc.get("completed"))
    if arc_completed.has("major_route_variant"):
        var saved_variant: int = clampi(int(arc_completed.get("major_route_variant", 0)), 0, 2)
        if saved_variant != route_variant:
            route_variant = saved_variant
            if configured_scene_id != 0 and major_root != null:
                layout_rebuild_pending = true
        return
    if not _is_authoritative():
        return
    route_variant = rng.randi_range(0, 2)
    arc_completed["major_route_variant"] = route_variant
    arc.set("completed", arc_completed)
    arc.set("state_dirty", true)
    state_dirty = true

func _sync_completed_from_arc() -> void:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var arc_completed: Dictionary = Dictionary(arc.get("completed"))
    for node_id: String in ISOLATION_IDS:
        completed_nodes[node_id] = bool(arc_completed.get(_save_key(node_id), false))

func _persist_node_to_arc(node_id: String) -> void:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var arc_completed: Dictionary = Dictionary(arc.get("completed"))
    arc_completed[_save_key(node_id)] = true
    arc.set("completed", arc_completed)
    arc.set("state_dirty", true)

func _save_key(node_id: String) -> String:
    return "major_%s" % node_id

func _apply_network_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    var incoming_variant: int = clampi(int(state.get("route_variant", 0)), 0, 2)
    if route_variant != incoming_variant:
        route_variant = incoming_variant
        if configured_scene_id != 0 and major_root != null:
            layout_rebuild_pending = true
    var completed_value: Variant = state.get("completed_nodes", {})
    if completed_value is Dictionary:
        completed_nodes = Dictionary(completed_value).duplicate(true)
    warden_active = bool(state.get("warden_active", false))
    finale_phase = clampi(int(state.get("finale_phase", 0)), 0, 3)

func _requester_position(peer_id: int) -> Vector3:
    if not _network_online() or peer_id == multiplayer.get_unique_id() or peer_id == 1 and _is_authoritative():
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        return player.global_position if player != null else Vector3.INF

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null or not coop.has_method("_get_survivor_state"):
        return Vector3.INF
    var state_value: Variant = coop.call("_get_survivor_state", peer_id)
    if not (state_value is Dictionary):
        return Vector3.INF
    var state: Dictionary = Dictionary(state_value)
    var transform_value: Variant = state.get("transform", null)
    if transform_value is Transform3D:
        var survivor_transform: Transform3D = transform_value
        return survivor_transform.origin
    return Vector3.INF

func _feedback_to_peer(peer_id: int, text: String) -> void:
    if not _network_online() or peer_id == multiplayer.get_unique_id() or peer_id == 1 and _is_authoritative():
        _set_local_status(text)
        return
    _receive_major_feedback.rpc_id(peer_id, text)

func _set_local_status(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _request_autosave(reason: String) -> void:
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("request_autosave"):
        save_system.call("request_autosave", reason)

func _report_noise(position: Vector3, strength: float, label: String) -> void:
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise != null and noise.has_method("report_noise"):
        noise.call("report_noise", position, strength, label)

func _on_peer_connected(peer_id: int) -> void:
    if not _is_authoritative():
        return
    call_deferred("_send_state_to_peer", peer_id)

func _send_state_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    if _network_online():
        _receive_major_state.rpc_id(peer_id, get_network_state())

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))
