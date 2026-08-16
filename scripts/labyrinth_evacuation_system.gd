extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const ESCAPE_DURATION: float = 150.0
const OVERRIDE_TIME_REWARD: float = 18.0
const USE_DISTANCE: float = 3.6
const EXTRACTION_DISTANCE: float = 4.2
const OVERRIDE_IDS: Array[String] = ["archive_override", "flood_override"]
const OVERRIDE_POSITIONS: Dictionary = {
    "archive_override": Vector3(10.8, 0.0, -123.6),
    "flood_override": Vector3(-10.9, 0.0, -88.2)
}
const EXTRACTION_POSITION: Vector3 = Vector3(-7.0, 1.2, -53.4)

var configured_scene_id: int = 0
var evacuation_root: Node3D
var override_script: Script
var exit_script: Script
var escape_started: bool = false
var escape_active: bool = false
var escape_completed: bool = false
var escape_remaining: float = ESCAPE_DURATION
var critical_state: bool = false
var completed_overrides: Dictionary = {}
var state_dirty: bool = true
var sync_timer: float = 0.0
var persist_timer: float = 0.0
var hud_timer: float = 0.0
var pressure_bucket: int = 0
var extraction_created: bool = false
var strobe_lights: Array[OmniLight3D] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    override_script = load("res://scripts/arc1_evacuation_override.gd") as Script
    exit_script = load("res://scripts/arc1_evacuation_exit.gd") as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        configured_scene_id = 0
        evacuation_root = null
        strobe_lights.clear()
        extraction_created = false
        return

    var arc_root: Node3D = scene.get_node_or_null("Arc1Expansion") as Node3D
    if arc_root == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        evacuation_root = null
        strobe_lights.clear()
        extraction_created = false
        call_deferred("_configure_scene", scene, arc_root)
        return

    if evacuation_root == null or not is_instance_valid(evacuation_root):
        return

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return

    var lockdown_complete: bool = bool(Dictionary(arc.get("completed")).get("lockdown", false))
    if lockdown_complete and not escape_completed:
        _suppress_original_exit(arc_root)

    if _is_authoritative():
        if not lockdown_complete:
            _reset_if_arc_restarted()
        else:
            _start_escape_from_arc_if_needed(arc)
            if escape_active:
                _update_escape(delta, arc)

        sync_timer -= delta
        if state_dirty or sync_timer <= 0.0:
            sync_timer = 0.40
            if _network_online():
                _receive_evacuation_state.rpc(get_network_state())
            state_dirty = false

    if escape_active:
        _force_escape_pressure()
    _update_strobe_lights()

    if _all_overrides_complete() and escape_active:
        _ensure_extraction()

    hud_timer -= delta
    if hud_timer <= 0.0:
        hud_timer = 0.28 if escape_active else 1.0
        _update_objective_hud()

func request_override_activation(override_id: String) -> void:
    if not OVERRIDE_IDS.has(override_id):
        return
    if _network_online() and not _is_authoritative():
        _request_override_remote.rpc_id(1, override_id)
        return
    var requester_id: int = multiplayer.get_unique_id() if _network_online() else 1
    _server_activate_override(override_id, requester_id)

func request_escape_finish() -> void:
    if _network_online() and not _is_authoritative():
        _request_finish_remote.rpc_id(1)
        return
    var requester_id: int = multiplayer.get_unique_id() if _network_online() else 1
    _server_finish_escape(requester_id)

func get_override_prompt(override_id: String, display_name: String) -> String:
    if bool(completed_overrides.get(override_id, false)):
        return "%s — restored" % display_name
    if not escape_active:
        return "%s — standby" % display_name
    if override_id == "archive_override":
        return "Restore %s — reverse evacuation route" % display_name
    return "Restore %s — arm extraction circuit" % display_name

func get_override_visual_state(override_id: String) -> int:
    if bool(completed_overrides.get(override_id, false)):
        return 2
    return 1 if escape_active else 0

func is_escape_active() -> bool:
    return escape_active

func is_escape_critical() -> bool:
    return critical_state

func get_network_state() -> Dictionary:
    return {
        "escape_started": escape_started,
        "escape_active": escape_active,
        "escape_completed": escape_completed,
        "escape_remaining": escape_remaining,
        "critical_state": critical_state,
        "completed_overrides": completed_overrides.duplicate(true),
        "pressure_bucket": pressure_bucket
    }

@rpc("any_peer", "call_remote", "reliable", 16)
func _request_override_remote(override_id: String) -> void:
    if not _is_authoritative():
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    _server_activate_override(override_id, sender_id)

@rpc("any_peer", "call_remote", "reliable", 16)
func _request_finish_remote() -> void:
    if not _is_authoritative():
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    _server_finish_escape(sender_id)

@rpc("authority", "call_remote", "reliable", 16)
func _receive_evacuation_state(state: Dictionary) -> void:
    _apply_network_state(state)

@rpc("authority", "call_remote", "reliable", 16)
func _receive_evacuation_feedback(text: String) -> void:
    _set_local_status(text)

@rpc("authority", "call_remote", "reliable", 16)
func _receive_pressure_shutter(shutter_id: String, position: Vector3, duration: float) -> void:
    _spawn_pressure_shutter(shutter_id, position, duration)

func _server_activate_override(override_id: String, requester_id: int) -> void:
    if not escape_active or not OVERRIDE_IDS.has(override_id):
        _feedback_to_peer(requester_id, "The evacuation circuit is not active.")
        return
    if bool(completed_overrides.get(override_id, false)):
        _feedback_to_peer(requester_id, "That emergency override is already restored.")
        return

    var requester_position: Vector3 = _requester_position(requester_id)
    var target_position: Vector3 = _override_position(override_id)
    if requester_position == Vector3.INF or requester_position.distance_to(target_position) > USE_DISTANCE:
        _feedback_to_peer(requester_id, "Move closer to the emergency override.")
        return

    completed_overrides[override_id] = true
    escape_remaining = minf(ESCAPE_DURATION + OVERRIDE_TIME_REWARD * 2.0, escape_remaining + OVERRIDE_TIME_REWARD)
    _persist_escape_state()
    state_dirty = true
    _report_noise(target_position, 1.12, "evacuation override restored")
    _request_autosave("Arc 1 evacuation override")

    if _all_overrides_complete():
        _feedback_to_peer(requester_id, "EXTRACTION ARMED — return to the M-01 entrance.")
        _set_local_status("EXTRACTION ARMED — reverse route to the lower-labyrinth entrance.")
        _ensure_extraction()
    else:
        _feedback_to_peer(requester_id, "Override restored. +%.0f seconds. One evacuation circuit remains." % OVERRIDE_TIME_REWARD)

func _server_finish_escape(requester_id: int) -> void:
    if not escape_active or not _all_overrides_complete():
        _feedback_to_peer(requester_id, "Extraction is not armed yet.")
        return

    var requester_position: Vector3 = _requester_position(requester_id)
    if requester_position == Vector3.INF or requester_position.distance_to(EXTRACTION_POSITION) > EXTRACTION_DISTANCE:
        _feedback_to_peer(requester_id, "Reach the extraction beacon at the M-01 entrance.")
        return

    escape_active = false
    escape_completed = true
    critical_state = false
    _persist_escape_state()
    state_dirty = true
    _request_autosave("Arc 1 evacuation complete")

    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition != null and transition.has_method("request_forest_transition"):
        transition.call("request_forest_transition")

func _start_escape_from_arc_if_needed(arc: Node) -> void:
    if escape_completed:
        return
    if escape_started:
        escape_active = true
        return

    var arc_completed: Dictionary = Dictionary(arc.get("completed"))
    escape_started = true
    escape_active = true
    escape_completed = bool(arc_completed.get("v21_escape_completed", false))
    if escape_completed:
        escape_active = false
        return

    escape_remaining = clampf(float(arc_completed.get("v21_escape_remaining", ESCAPE_DURATION)), 0.0, ESCAPE_DURATION + OVERRIDE_TIME_REWARD * 2.0)
    if not arc_completed.has("v21_escape_remaining"):
        escape_remaining = ESCAPE_DURATION
    for override_id: String in OVERRIDE_IDS:
        completed_overrides[override_id] = bool(arc_completed.get(_override_save_key(override_id), false))

    critical_state = escape_remaining <= 0.0
    pressure_bucket = _pressure_bucket(escape_remaining)
    _persist_escape_state()
    _request_autosave("Arc 1 evacuation started")
    _set_local_status("EVACUATION PROTOCOL — the lower exit is gone. Reverse the Labyrinth and restore two overrides.")
    state_dirty = true

func _update_escape(delta: float, arc: Node) -> void:
    escape_remaining = maxf(0.0, escape_remaining - delta)
    critical_state = escape_remaining <= 0.0

    var next_bucket: int = _pressure_bucket(escape_remaining)
    if next_bucket > pressure_bucket:
        for bucket: int in range(pressure_bucket + 1, next_bucket + 1):
            _trigger_pressure_pulse(bucket)
        pressure_bucket = next_bucket
        state_dirty = true

    persist_timer -= delta
    if persist_timer <= 0.0:
        persist_timer = 1.0
        _persist_escape_state()

    if critical_state:
        arc.set("fault_timer", maxf(float(arc.get("fault_timer")), 1.0))
        arc.set("state_dirty", true)

func _trigger_pressure_pulse(bucket: int) -> void:
    var position: Vector3 = Vector3.ZERO
    match bucket:
        1:
            position = Vector3(8.8, 0.0, -121.5)
        2:
            position = Vector3(-8.8, 0.0, -101.0)
        3:
            position = Vector3(8.8, 0.0, -77.0)
        4:
            position = Vector3(-7.0, 0.0, -64.0)
        _:
            position = Vector3(0.0, 0.0, -94.0)

    var shutter_id: String = "EvacShutter%d" % bucket
    _spawn_pressure_shutter(shutter_id, position, 4.5)
    if _network_online():
        _receive_pressure_shutter.rpc(shutter_id, position, 4.5)
    _report_noise(position, 1.0 + float(bucket) * 0.08, "evacuation structural shift")

    var director: Node = get_node_or_null("/root/LabyrinthEncounterDirector")
    if director != null:
        director.set("horror_event_timer", minf(float(director.get("horror_event_timer")), 5.0))
    if bucket == 2 or bucket == 4:
        _request_autosave("Arc 1 evacuation pressure checkpoint")

func _force_escape_pressure() -> void:
    var major: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    if major != null:
        major.set("warden_active", true)

    var director: Node = get_node_or_null("/root/LabyrinthEncounterDirector")
    if director != null:
        var horror_limit: float = 4.5 if critical_state else 8.0
        director.set("horror_event_timer", minf(float(director.get("horror_event_timer")), horror_limit))

    var warden_speed: float = 2.18 if critical_state else 1.94
    for node: Node in get_tree().get_nodes_in_group("arc1_warden"):
        node.set("move_speed", warden_speed)
        node.set("detection_radius", 44.0 if critical_state else 38.0)

func _configure_scene(scene: Node, arc_root: Node3D) -> void:
    for _frame_index: int in range(60):
        await get_tree().process_frame
        if not is_instance_valid(scene) or get_tree().current_scene != scene:
            return
        if is_instance_valid(arc_root):
            break

    if not is_instance_valid(scene) or get_tree().current_scene != scene or not is_instance_valid(arc_root):
        return

    var old_root: Node = arc_root.get_node_or_null("EvacuationExpansion")
    if old_root != null:
        old_root.free()

    evacuation_root = Node3D.new()
    evacuation_root.name = "EvacuationExpansion"
    arc_root.add_child(evacuation_root)

    _spawn_override("archive_override", "A-03 Emergency Override", _override_position("archive_override"))
    _spawn_override("flood_override", "F-02 Extraction Override", _override_position("flood_override"))
    _build_evacuation_guidance()

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null and _is_authoritative():
        var arc_completed: Dictionary = Dictionary(arc.get("completed"))
        if bool(arc_completed.get("lockdown", false)):
            escape_started = false
            _start_escape_from_arc_if_needed(arc)

    if _all_overrides_complete() and escape_active:
        _ensure_extraction()
    state_dirty = true

func _spawn_override(override_id: String, display_name: String, position: Vector3) -> void:
    if evacuation_root == null or override_script == null:
        return
    var panel: StaticBody3D = StaticBody3D.new()
    panel.name = "EvacOverride_%s" % override_id
    panel.position = position
    panel.set_script(override_script)
    panel.set("override_id", override_id)
    panel.set("display_name", display_name)
    evacuation_root.add_child(panel)

func _build_evacuation_guidance() -> void:
    if evacuation_root == null:
        return
    var positions: Array[Vector3] = [
        Vector3(0.0, 2.55, -133.0), Vector3(9.5, 2.55, -124.0), Vector3(-8.5, 2.55, -115.0),
        Vector3(8.5, 2.55, -104.0), Vector3(-9.0, 2.55, -96.0), Vector3(8.5, 2.55, -87.5),
        Vector3(-8.5, 2.55, -78.0), Vector3(8.8, 2.55, -70.0), Vector3(-8.8, 2.55, -62.0),
        Vector3(-7.0, 2.55, -55.0)
    ]
    for index: int in range(positions.size()):
        var light: OmniLight3D = OmniLight3D.new()
        light.name = "EvacStrobe%02d" % index
        light.position = positions[index]
        light.light_color = Color(0.80, 0.15, 0.045, 1.0)
        light.light_energy = 0.088
        light.omni_range = 4.4
        light.shadow_enabled = false
        light.visible = false
        evacuation_root.add_child(light)
        strobe_lights.append(light)

        var label: Label3D = Label3D.new()
        label.name = "EvacArrow%02d" % index
        label.text = "<< EVAC" if index < positions.size() - 1 else "EXTRACTION <<"
        label.font_size = 20
        label.modulate = Color(0.72, 0.18, 0.06, 1.0)
        label.position = positions[index] + Vector3(0.0, -0.62, 0.0)
        label.visible = false
        evacuation_root.add_child(label)

func _update_strobe_lights() -> void:
    var time_value: float = float(Time.get_ticks_msec()) / 1000.0
    for index: int in range(strobe_lights.size()):
        var light: OmniLight3D = strobe_lights[index]
        if light == null or not is_instance_valid(light):
            continue
        light.visible = escape_active
        if light.visible:
            var pulse: float = 0.48 + 0.52 * absf(sin(time_value * 4.8 + float(index) * 0.72))
            light.light_energy = minf(0.095, 0.055 + pulse * 0.038)

    if evacuation_root == null:
        return
    for child: Node in evacuation_root.get_children():
        if child is Label3D and child.name.begins_with("EvacArrow"):
            var label: Label3D = child as Label3D
            label.visible = escape_active

func _ensure_extraction() -> void:
    if extraction_created or evacuation_root == null or exit_script == null:
        return
    extraction_created = true

    var beacon: OmniLight3D = OmniLight3D.new()
    beacon.name = "EvacuationBeacon"
    beacon.position = EXTRACTION_POSITION + Vector3(0.0, 1.55, 0.0)
    beacon.light_color = Color(0.30, 0.86, 0.48, 1.0)
    beacon.light_energy = 1.35
    beacon.omni_range = 6.0
    beacon.shadow_enabled = false
    evacuation_root.add_child(beacon)

    var exit: Area3D = Area3D.new()
    exit.name = "EvacuationExit"
    exit.position = EXTRACTION_POSITION
    exit.set_script(exit_script)
    evacuation_root.add_child(exit)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(4.8, 2.4, 1.5)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    exit.add_child(collision)

func _suppress_original_exit(arc_root: Node3D) -> void:
    var old_transition: Node = arc_root.get_node_or_null("OutsideTransitionArc1")
    if old_transition != null:
        old_transition.queue_free()
    var old_beacon: Node = arc_root.get_node_or_null("Arc1FinalBeacon")
    if old_beacon != null:
        old_beacon.queue_free()

func _spawn_pressure_shutter(shutter_id: String, position: Vector3, duration: float) -> void:
    if evacuation_root == null or not is_instance_valid(evacuation_root):
        return
    var old: Node = evacuation_root.get_node_or_null(shutter_id)
    if old != null:
        old.queue_free()

    var body: StaticBody3D = StaticBody3D.new()
    body.name = shutter_id
    body.position = position
    evacuation_root.add_child(body)

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.13, 0.075, 0.05, 1.0)
    material.metallic = 0.52
    material.roughness = 0.56
    material.emission_enabled = true
    material.emission = Color(0.72, 0.06, 0.02, 1.0)
    material.emission_energy_multiplier = 0.55

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(4.0, 2.8, 0.24)
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = material
    visual.position.y = 1.4
    body.add_child(visual)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(4.0, 2.8, 0.30)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 1.4
    body.add_child(collision)

    _expire_shutter(body, duration)

func _expire_shutter(body: StaticBody3D, duration: float) -> void:
    await get_tree().create_timer(maxf(1.0, duration)).timeout
    if body != null and is_instance_valid(body):
        body.queue_free()

func _update_objective_hud() -> void:
    if not escape_active:
        return
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or player.global_position.z > -49.0:
        return

    var remaining: int = maxi(0, int(ceil(escape_remaining)))
    var time_text: String = "%d:%02d" % [remaining / 60, remaining % 60]
    var archive_done: bool = bool(completed_overrides.get("archive_override", false))
    var flood_done: bool = bool(completed_overrides.get("flood_override", false))

    if critical_state:
        if _all_overrides_complete():
            _set_local_status("EVACUATION CRITICAL — EXTRACTION ARMED. Return to M-01. THE WARDEN IS HUNTING.")
        else:
            _set_local_status("EVACUATION CRITICAL — restore overrides A:%s F:%s. THE WARDEN IS HUNTING." % ["OK" if archive_done else "--", "OK" if flood_done else "--"])
        return

    if _all_overrides_complete():
        _set_local_status("EVACUATION %s — EXTRACTION ARMED. Reverse route to M-01 entrance." % time_text)
    else:
        _set_local_status("EVACUATION %s — overrides A:%s F:%s. Reverse through Archive → Flooded → Maintenance." % [time_text, "OK" if archive_done else "--", "OK" if flood_done else "--"])

func _persist_escape_state() -> void:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var arc_completed: Dictionary = Dictionary(arc.get("completed"))
    arc_completed["v21_escape_started"] = escape_started
    arc_completed["v21_escape_completed"] = escape_completed
    arc_completed["v21_escape_remaining"] = escape_remaining
    for override_id: String in OVERRIDE_IDS:
        arc_completed[_override_save_key(override_id)] = bool(completed_overrides.get(override_id, false))
    arc.set("completed", arc_completed)
    arc.set("state_dirty", true)

func _reset_if_arc_restarted() -> void:
    if not escape_started and not escape_completed:
        return
    escape_started = false
    escape_active = false
    escape_completed = false
    escape_remaining = ESCAPE_DURATION
    critical_state = false
    completed_overrides.clear()
    pressure_bucket = 0
    extraction_created = false
    state_dirty = true

func _apply_network_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    escape_started = bool(state.get("escape_started", false))
    escape_active = bool(state.get("escape_active", false))
    escape_completed = bool(state.get("escape_completed", false))
    escape_remaining = maxf(0.0, float(state.get("escape_remaining", ESCAPE_DURATION)))
    critical_state = bool(state.get("critical_state", false))
    pressure_bucket = maxi(0, int(state.get("pressure_bucket", 0)))
    var overrides_value: Variant = state.get("completed_overrides", {})
    if overrides_value is Dictionary:
        completed_overrides = Dictionary(overrides_value).duplicate(true)
    if escape_active and _all_overrides_complete():
        _ensure_extraction()

func _pressure_bucket(remaining: float) -> int:
    if remaining <= 0.0:
        return 5
    if remaining <= 30.0:
        return 4
    if remaining <= 60.0:
        return 3
    if remaining <= 90.0:
        return 2
    if remaining <= 120.0:
        return 1
    return 0

func _all_overrides_complete() -> bool:
    for override_id: String in OVERRIDE_IDS:
        if not bool(completed_overrides.get(override_id, false)):
            return false
    return true

func _override_position(override_id: String) -> Vector3:
    var value: Variant = OVERRIDE_POSITIONS.get(override_id, Vector3.ZERO)
    return value if value is Vector3 else Vector3.ZERO

func _override_save_key(override_id: String) -> String:
    return "v21_%s" % override_id

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
    _receive_evacuation_feedback.rpc_id(peer_id, text)

func _set_local_status(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _report_noise(position: Vector3, strength: float, label: String) -> void:
    if not _is_authoritative():
        return
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise != null and noise.has_method("report_noise"):
        noise.call("report_noise", position, strength, label)

func _request_autosave(reason: String) -> void:
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("request_autosave"):
        save_system.call("request_autosave", reason)

func _on_peer_connected(peer_id: int) -> void:
    if not _is_authoritative():
        return
    call_deferred("_send_state_to_peer", peer_id)

func _send_state_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    if _network_online():
        _receive_evacuation_state.rpc_id(peer_id, get_network_state())

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))
