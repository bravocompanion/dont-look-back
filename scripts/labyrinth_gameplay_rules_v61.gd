extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const STABILIZER_SCRIPT_PATH: String = "res://scripts/labyrinth_rule_stabilizer_v61.gd"
const STABILIZER_DURATION: float = 24.0
const STABILIZER_DISTANCE: float = 3.8
const BEACON_ROTATE_SECONDS: float = 23.0
const BEACON_RADIUS: float = 6.5
const PIPE_SURGE_MIN: float = 6.5
const PIPE_SURGE_MAX: float = 10.0

const STABILIZER_POSITIONS: Array[Vector3] = [
    Vector3(-10.8, 0.0, -109.0),
    Vector3(10.8, 0.0, -116.0),
    Vector3(-10.8, 0.0, -122.0)
]
const BEACON_POSITIONS: Array[Vector3] = [
    Vector3(-8.0, 0.0, -131.5),
    Vector3(7.8, 0.0, -134.8),
    Vector3(-6.6, 0.0, -138.0)
]
const PIPE_SURGE_POSITIONS: Array[Vector3] = [
    Vector3(-7.0, 0.0, -89.5),
    Vector3(7.0, 0.0, -98.0),
    Vector3(0.0, 0.0, -94.0)
]

var configured_scene_id: int = 0
var runtime_root: Node3D
var stabilizer_script: Script
var stabilizer_nodes: Dictionary = {}
var stabilizer_owner: Dictionary = {}
var stabilizer_remaining: Dictionary = {}
var beacon_lights: Array[OmniLight3D] = []
var beacon_materials: Array[StandardMaterial3D] = []
var active_beacon_index: int = 0
var beacon_rotate_remaining: float = BEACON_ROTATE_SECONDS
var pipe_surge_remaining: float = 7.5
var pipe_surge_index: int = 0
var last_stage: int = -1
var state_sync_timer: float = 0.0
var state_dirty: bool = true
var lockdown_coverage_ok: bool = true
var lockdown_noise_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    stabilizer_script = load(STABILIZER_SCRIPT_PATH) as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected_v61):
        multiplayer.peer_connected.connect(_on_peer_connected_v61)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        configured_scene_id = 0
        runtime_root = null
        stabilizer_nodes.clear()
        beacon_lights.clear()
        beacon_materials.clear()
        last_stage = -1
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        runtime_root = null
        stabilizer_nodes.clear()
        beacon_lights.clear()
        beacon_materials.clear()
        stabilizer_owner.clear()
        stabilizer_remaining.clear()
        active_beacon_index = 0
        beacon_rotate_remaining = BEACON_ROTATE_SECONDS
        pipe_surge_remaining = 7.5
        last_stage = -1
        call_deferred("_configure_scene_v61", scene)
        return

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null or runtime_root == null or not is_instance_valid(runtime_root):
        return
    var stage: int = int(arc.get("current_stage"))
    if stage != last_stage:
        _on_stage_changed_v61(last_stage, stage)
        last_stage = stage

    _apply_blackout_rule_v61(arc, stage)
    _update_runtime_visibility_v61(stage)

    if not _is_authoritative_v61():
        _refresh_visuals_v61()
        return

    if stage == 2:
        pipe_surge_remaining -= delta
        if pipe_surge_remaining <= 0.0:
            _emit_pipe_surge_v61()
            pipe_surge_remaining = randf_range(PIPE_SURGE_MIN, PIPE_SURGE_MAX)

    if stage == 3:
        _tick_stabilizers_v61(delta)
    elif not stabilizer_owner.is_empty() or not stabilizer_remaining.is_empty():
        stabilizer_owner.clear()
        stabilizer_remaining.clear()
        state_dirty = true

    if stage == 5 and bool(arc.get("holdout_active")):
        beacon_rotate_remaining -= delta
        if beacon_rotate_remaining <= 0.0:
            active_beacon_index = (active_beacon_index + 1) % BEACON_POSITIONS.size()
            beacon_rotate_remaining = BEACON_ROTATE_SECONDS
            state_dirty = true
            _announce_local_v61("LOCKDOWN: emergency protection moved — regroup at Beacon %d." % (active_beacon_index + 1))
        lockdown_coverage_ok = _lockdown_coverage_met_v61()
        lockdown_noise_timer -= delta
        if not lockdown_coverage_ok and lockdown_noise_timer <= 0.0:
            lockdown_noise_timer = 4.5
            _report_noise_v61(BEACON_POSITIONS[active_beacon_index], 1.05, "lockdown exposed team")
    else:
        lockdown_coverage_ok = true
        lockdown_noise_timer = 0.0

    state_sync_timer -= delta
    if state_dirty or state_sync_timer <= 0.0:
        state_sync_timer = 0.45
        state_dirty = false
        if _network_online_v61() and _is_host_v61():
            _receive_rules_state_v61.rpc(_build_sync_state_v61())

    _refresh_visuals_v61()

func request_stabilizer_v61(stabilizer_id: int) -> void:
    if stabilizer_id < 0 or stabilizer_id >= STABILIZER_POSITIONS.size():
        return
    if _network_online_v61() and not _is_host_v61():
        _request_stabilizer_remote_v61.rpc_id(1, stabilizer_id)
        return
    _activate_stabilizer_v61(_local_peer_id_v61(), stabilizer_id)

func get_stabilizer_prompt_v61(stabilizer_id: int, display_name: String) -> String:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null or int(arc.get("current_stage")) != 3:
        return "%s — standby" % display_name
    var remaining: float = float(stabilizer_remaining.get(stabilizer_id, 0.0))
    var owner: int = int(stabilizer_owner.get(stabilizer_id, 0))
    if remaining > 0.05 and owner > 0:
        return "%s — P%d holding %.0fs" % [display_name, owner, remaining]
    return "Hold %s for archive breakers" % display_name

func can_use_breakers_v61() -> bool:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null or int(arc.get("current_stage")) != 3:
        return true
    return _active_stabilizer_count_v61() >= _required_stabilizer_count_v61()

func get_breaker_requirement_text_v61() -> String:
    return "%d / %d stabilizers held" % [_active_stabilizer_count_v61(), _required_stabilizer_count_v61()]

func get_enemy_pressure_bonus_v61() -> float:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return 0.0
    var stage: int = int(arc.get("current_stage"))
    if stage == 3 and not can_use_breakers_v61():
        return 0.12
    if stage == 5 and bool(arc.get("holdout_active")):
        return 0.04 if lockdown_coverage_ok else 0.44
    return 0.0

func get_active_lockdown_beacon_v61() -> int:
    return active_beacon_index

func get_lockdown_rule_text_v61() -> String:
    var required: int = _required_lockdown_coverage_v61()
    return "Beacon %d • regroup %d survivor%s" % [active_beacon_index + 1, required, "" if required == 1 else "s"]

@rpc("any_peer", "call_remote", "reliable", 64)
func _request_stabilizer_remote_v61(stabilizer_id: int) -> void:
    if not _is_host_v61() or stabilizer_id < 0 or stabilizer_id >= STABILIZER_POSITIONS.size():
        return
    _activate_stabilizer_v61(multiplayer.get_remote_sender_id(), stabilizer_id)

@rpc("authority", "call_remote", "reliable", 64)
func _receive_rules_state_v61(state: Dictionary) -> void:
    active_beacon_index = clampi(int(state.get("active_beacon", 0)), 0, BEACON_POSITIONS.size() - 1)
    beacon_rotate_remaining = maxf(0.0, float(state.get("beacon_remaining", BEACON_ROTATE_SECONDS)))
    lockdown_coverage_ok = bool(state.get("coverage_ok", true))
    stabilizer_owner = Dictionary(state.get("stabilizer_owner", {})).duplicate(true)
    stabilizer_remaining = Dictionary(state.get("stabilizer_remaining", {})).duplicate(true)
    _refresh_visuals_v61()

func _activate_stabilizer_v61(peer_id: int, stabilizer_id: int) -> void:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null or int(arc.get("current_stage")) != 3:
        return
    var node: Node3D = stabilizer_nodes.get(stabilizer_id) as Node3D
    if node == null or not _peer_near_position_v61(peer_id, node.global_position, STABILIZER_DISTANCE):
        return

    for key_variant: Variant in stabilizer_owner.keys():
        var key: int = int(key_variant)
        if key != stabilizer_id and int(stabilizer_owner.get(key, 0)) == peer_id:
            stabilizer_owner.erase(key)
            stabilizer_remaining.erase(key)

    stabilizer_owner[stabilizer_id] = peer_id
    stabilizer_remaining[stabilizer_id] = STABILIZER_DURATION
    state_dirty = true
    _report_noise_v61(node.global_position, 0.58, "archive stabilizer")
    _announce_peer_v61(peer_id, "STABILIZER %d HELD — %s." % [stabilizer_id + 1, get_breaker_requirement_text_v61()])
    _refresh_visuals_v61()

func _tick_stabilizers_v61(delta: float) -> void:
    var expired: Array[int] = []
    for key_variant: Variant in stabilizer_remaining.keys():
        var key: int = int(key_variant)
        var next_value: float = maxf(0.0, float(stabilizer_remaining.get(key, 0.0)) - delta)
        stabilizer_remaining[key] = next_value
        if next_value <= 0.0:
            expired.append(key)
    for key: int in expired:
        stabilizer_remaining.erase(key)
        stabilizer_owner.erase(key)
        state_dirty = true

func _active_stabilizer_count_v61() -> int:
    var count: int = 0
    for key_variant: Variant in stabilizer_remaining.keys():
        if float(stabilizer_remaining.get(int(key_variant), 0.0)) > 0.05:
            count += 1
    return count

func _required_stabilizer_count_v61() -> int:
    return clampi(_party_size_v61(), 1, 3)

func _required_lockdown_coverage_v61() -> int:
    var party: int = _party_size_v61()
    return 2 if party >= 3 else 1

func _lockdown_coverage_met_v61() -> bool:
    var required: int = _required_lockdown_coverage_v61()
    var covered: int = 0
    for peer_id: int in _party_peer_ids_v61():
        var position_value: Variant = _peer_position_v61(peer_id)
        if position_value == null:
            continue
        var position: Vector3 = position_value
        if position.distance_to(BEACON_POSITIONS[active_beacon_index]) <= BEACON_RADIUS:
            covered += 1
    return covered >= required

func _party_peer_ids_v61() -> Array[int]:
    var ids: Array[int] = [1]
    if _network_online_v61() and _is_host_v61():
        for peer_id: int in multiplayer.get_peers():
            if peer_id > 1:
                ids.append(peer_id)
    return ids

func _party_size_v61() -> int:
    if not _network_online_v61():
        return 1
    if _is_host_v61():
        return clampi(1 + multiplayer.get_peers().size(), 1, 4)
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        var states_value: Variant = coop.get("survivor_states")
        if states_value is Dictionary:
            return clampi(Dictionary(states_value).size(), 1, 4)
    return 2

func _peer_position_v61(peer_id: int) -> Variant:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("_peer_position_v57"):
        return network.call("_peer_position_v57", peer_id)
    if peer_id == 1:
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        return player.global_position if player != null else null
    return null

func _peer_near_position_v61(peer_id: int, position: Vector3, max_distance: float) -> bool:
    var value: Variant = _peer_position_v61(peer_id)
    if value == null:
        return false
    var peer_position: Vector3 = value
    return peer_position.distance_to(position) <= max_distance

func _configure_scene_v61(scene: Node) -> void:
    for _frame_index: int in range(180):
        await get_tree().process_frame
        if not is_instance_valid(scene) or get_tree().current_scene != scene:
            return
        if scene.get_node_or_null("Arc1Expansion") != null:
            break
    if not is_instance_valid(scene) or get_tree().current_scene != scene or scene.get_node_or_null("Arc1Expansion") == null:
        return

    var old: Node = scene.get_node_or_null("LabyrinthGameplayRulesV61")
    if old != null:
        old.free()
    runtime_root = Node3D.new()
    runtime_root.name = "LabyrinthGameplayRulesV61"
    scene.add_child(runtime_root)

    for index: int in range(STABILIZER_POSITIONS.size()):
        var body: StaticBody3D = StaticBody3D.new()
        body.name = "ArchiveStabilizer%d" % (index + 1)
        body.set_script(stabilizer_script)
        body.set("stabilizer_id", index)
        body.set("display_name", "Archive Stabilizer %d" % (index + 1))
        body.position = STABILIZER_POSITIONS[index]
        runtime_root.add_child(body)
        stabilizer_nodes[index] = body

    for index: int in range(BEACON_POSITIONS.size()):
        _build_beacon_v61(index, BEACON_POSITIONS[index])
    _update_runtime_visibility_v61(int(get_node("/root/LabyrinthArc1System").get("current_stage")))
    _refresh_visuals_v61()

func _build_beacon_v61(index: int, position: Vector3) -> void:
    if runtime_root == null:
        return
    var root: Node3D = Node3D.new()
    root.name = "LockdownBeacon%d" % (index + 1)
    root.position = position
    runtime_root.add_child(root)

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.emission_enabled = true
    material.albedo_color = Color(0.08, 0.13, 0.15, 1.0)
    material.emission = Color(0.02, 0.10, 0.12, 1.0)
    material.emission_energy_multiplier = 1.0
    beacon_materials.append(material)

    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = 0.22
    mesh.bottom_radius = 0.34
    mesh.height = 0.55
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = material
    visual.position = Vector3(0.0, 0.28, 0.0)
    root.add_child(visual)

    var light: OmniLight3D = OmniLight3D.new()
    light.position = Vector3(0.0, 1.35, 0.0)
    light.omni_range = BEACON_RADIUS
    light.light_energy = 0.0
    light.light_color = Color(0.32, 0.82, 0.92, 1.0)
    root.add_child(light)
    beacon_lights.append(light)

    var label: Label3D = Label3D.new()
    label.name = "Label"
    label.position = Vector3(0.0, 1.9, 0.0)
    label.text = "BEACON %d" % (index + 1)
    label.font_size = 22
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    root.add_child(label)

func _on_stage_changed_v61(_old_stage: int, new_stage: int) -> void:
    stabilizer_owner.clear()
    stabilizer_remaining.clear()
    active_beacon_index = 0
    beacon_rotate_remaining = BEACON_ROTATE_SECONDS
    lockdown_coverage_ok = true
    state_dirty = true
    if new_stage == 1:
        _announce_local_v61("ARC RULE — BLACKOUT: maintenance lights are critically weak until all fuses are restored.")
    elif new_stage == 2:
        _announce_local_v61("ARC RULE — PIPE SURGE: flooded pressure lines create false noise. Do not trust every sound cue.")
    elif new_stage == 3:
        _announce_local_v61("ARC RULE — SPLIT: each survivor can hold one stabilizer. Hold %d simultaneously before touching breakers." % _required_stabilizer_count_v61())
    elif new_stage == 5:
        _announce_local_v61("ARC RULE — MOVING LIGHT: lockdown protection rotates between three emergency beacons. Regroup when it moves.")
    elif new_stage >= 6:
        _announce_local_v61("ARC 1 STABLE — the lockdown released. Regroup before entering the Research Facility.")
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null and new_stage != 1 and arc.has_method("_update_runtime_visuals"):
        arc.call("_update_runtime_visuals")

func _apply_blackout_rule_v61(arc: Node, stage: int) -> void:
    if stage != 1:
        return
    var lights_value: Variant = arc.get("dim_lights")
    if not (lights_value is Array):
        return
    for light_variant: Variant in Array(lights_value):
        var light: OmniLight3D = light_variant as OmniLight3D
        if light != null and is_instance_valid(light):
            light.light_energy = minf(light.light_energy, 0.022)

func _emit_pipe_surge_v61() -> void:
    var position: Vector3 = PIPE_SURGE_POSITIONS[pipe_surge_index % PIPE_SURGE_POSITIONS.size()]
    pipe_surge_index += 1
    _report_noise_v61(position, 0.88, "flooded pipe surge")

func _report_noise_v61(position: Vector3, strength: float, label: String) -> void:
    var relay: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if relay != null and relay.has_method("report_noise"):
        relay.call("report_noise", position, strength, label)

func _update_runtime_visibility_v61(stage: int) -> void:
    for value: Variant in stabilizer_nodes.values():
        var node: Node3D = value as Node3D
        if node != null:
            node.visible = stage == 3
            node.process_mode = Node.PROCESS_MODE_INHERIT if stage == 3 else Node.PROCESS_MODE_DISABLED
    if runtime_root == null:
        return
    for index: int in range(BEACON_POSITIONS.size()):
        var beacon: Node3D = runtime_root.get_node_or_null("LockdownBeacon%d" % (index + 1)) as Node3D
        if beacon != null:
            beacon.visible = stage == 5

func _refresh_visuals_v61() -> void:
    for key_variant: Variant in stabilizer_nodes.keys():
        var key: int = int(key_variant)
        var node: Node = stabilizer_nodes.get(key) as Node
        if node != null and node.has_method("set_active_visual_v61"):
            var active: bool = float(stabilizer_remaining.get(key, 0.0)) > 0.05
            node.call("set_active_visual_v61", active, int(stabilizer_owner.get(key, 0)))
    for index: int in range(beacon_lights.size()):
        var active: bool = index == active_beacon_index
        var light: OmniLight3D = beacon_lights[index]
        if light != null:
            light.light_energy = 1.15 if active else 0.03
        if index < beacon_materials.size():
            var material: StandardMaterial3D = beacon_materials[index]
            material.emission = Color(0.12, 0.72, 0.86, 1.0) if active else Color(0.02, 0.08, 0.10, 1.0)
            material.emission_energy_multiplier = 3.4 if active else 0.7

func _build_sync_state_v61() -> Dictionary:
    return {
        "stabilizer_owner": stabilizer_owner.duplicate(true),
        "stabilizer_remaining": stabilizer_remaining.duplicate(true),
        "active_beacon": active_beacon_index,
        "beacon_remaining": beacon_rotate_remaining,
        "coverage_ok": lockdown_coverage_ok
    }

func _on_peer_connected_v61(peer_id: int) -> void:
    if not _network_online_v61() or not _is_host_v61() or peer_id <= 1:
        return
    _receive_rules_state_v61.rpc_id(peer_id, _build_sync_state_v61())

func _announce_peer_v61(peer_id: int, text: String) -> void:
    if peer_id == 1:
        _announce_local_v61(text)
        return
    if _network_online_v61() and _is_host_v61():
        _rule_feedback_v61.rpc_id(peer_id, text)

@rpc("authority", "call_remote", "reliable", 64)
func _rule_feedback_v61(text: String) -> void:
    _announce_local_v61(text)

func _announce_local_v61(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _network_online_v61() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host_v61() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _is_authoritative_v61() -> bool:
    return not _network_online_v61() or _is_host_v61()

func _local_peer_id_v61() -> int:
    return multiplayer.get_unique_id() if _network_online_v61() else 1
