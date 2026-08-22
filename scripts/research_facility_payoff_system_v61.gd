extends Node

const FACILITY_SCENE_PATH: String = "res://scenes/research_facility.tscn"
const TERMINAL_SCRIPT_PATH: String = "res://scripts/research_choice_terminal_v61.gd"
const CHOICE_DISTRESS: String = "distress_signal"
const CHOICE_CONTAINMENT: String = "containment_data"
const VALID_CHOICES: Array[String] = [CHOICE_DISTRESS, CHOICE_CONTAINMENT]
const CHOICE_DISTANCE: float = 3.8
const DISTRESS_RESPONSE_SECONDS: float = 24.0
const CONTAINMENT_RESPONSE_SECONDS: float = 18.0
const DISTRESS_BEACON_STEP: float = 5.5
const INTERFERENCE_EXPOSURE_PER_SECOND: float = 30.0
const SAFE_BEACON_RADIUS: float = 4.8

const TERMINAL_POSITIONS: Dictionary = {
    CHOICE_DISTRESS: Vector3(-4.2, 0.0, -28.5),
    CHOICE_CONTAINMENT: Vector3(4.2, 0.0, -28.5)
}
const BEACON_POSITIONS: Array[Vector3] = [
    Vector3(-6.2, 0.0, -31.5),
    Vector3(0.0, 0.0, -34.8),
    Vector3(6.2, 0.0, -31.5)
]

var configured_scene_id: int = 0
var runtime_root: Node3D
var terminal_script: Script
var terminals: Dictionary = {}
var beacon_lights: Array[OmniLight3D] = []
var beacon_materials: Array[StandardMaterial3D] = []

var selected_choice: String = ""
var response_active: bool = false
var response_complete: bool = false
var response_remaining: float = 0.0
var active_beacon_index: int = 0
var beacon_step_remaining: float = DISTRESS_BEACON_STEP
var response_noise_timer: float = 0.0
var state_sync_timer: float = 0.0
var pending_restore_state: Dictionary = {}
var state_dirty: bool = true

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    terminal_script = load(TERMINAL_SCRIPT_PATH) as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected_v61):
        multiplayer.peer_connected.connect(_on_peer_connected_v61)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FACILITY_SCENE_PATH:
        configured_scene_id = 0
        runtime_root = null
        terminals.clear()
        beacon_lights.clear()
        beacon_materials.clear()
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        runtime_root = null
        terminals.clear()
        beacon_lights.clear()
        beacon_materials.clear()
        call_deferred("_configure_scene_v61", scene)
        return

    if runtime_root == null or not is_instance_valid(runtime_root):
        return

    if response_active:
        response_remaining = maxf(0.0, response_remaining - delta)
        if selected_choice == CHOICE_DISTRESS and _is_authoritative_v61():
            beacon_step_remaining -= delta
            if beacon_step_remaining <= 0.0:
                active_beacon_index = (active_beacon_index + 1) % BEACON_POSITIONS.size()
                beacon_step_remaining = DISTRESS_BEACON_STEP
                state_dirty = true
                _announce_local_v61("DISTRESS UPLINK: emergency carrier moved to Beacon %d." % (active_beacon_index + 1))
        _apply_local_interference_v61(delta)

        if _is_authoritative_v61():
            response_noise_timer -= delta
            if response_noise_timer <= 0.0:
                response_noise_timer = 4.0
                _report_noise_v61(BEACON_POSITIONS[active_beacon_index], 0.82, "facility containment pulse")
            if response_remaining <= 0.0:
                _complete_response_v61()

    if _is_authoritative_v61():
        state_sync_timer -= delta
        if state_dirty or state_sync_timer <= 0.0:
            state_sync_timer = 0.45
            state_dirty = false
            if _network_online_v61() and _is_host_v61():
                _receive_payoff_state_v61.rpc(_build_sync_state_v61())

    _refresh_visuals_v61()

func request_choice_v61(choice_id: String) -> void:
    if choice_id not in VALID_CHOICES:
        return
    if _network_online_v61() and not _is_host_v61():
        _request_choice_remote_v61.rpc_id(1, choice_id)
        return
    _commit_choice_v61(_local_peer_id_v61(), choice_id)

func get_choice_prompt_v61(choice_id: String, display_name: String) -> String:
    if not _routing_terminal_reviewed_v61():
        return "%s — review main routing table first" % display_name
    if selected_choice.is_empty():
        return "Commit %s" % ("RESCUE PRIORITY" if choice_id == CHOICE_DISTRESS else "ANOMALY PRIORITY")
    if selected_choice == choice_id:
        return "%s — committed%s" % [display_name, " / response active" if response_active else ""]
    return "%s — locked by prior decision" % display_name

func get_save_state() -> Dictionary:
    return {
        "selected_choice": selected_choice,
        "response_active": response_active,
        "response_complete": response_complete,
        "response_remaining": response_remaining,
        "active_beacon_index": active_beacon_index,
        "beacon_step_remaining": beacon_step_remaining
    }

func restore_save_state(state: Dictionary) -> void:
    pending_restore_state = state.duplicate(true)
    _apply_state_v61(state)
    _refresh_visuals_v61()

func reset_progress() -> void:
    selected_choice = ""
    response_active = false
    response_complete = false
    response_remaining = 0.0
    active_beacon_index = 0
    beacon_step_remaining = DISTRESS_BEACON_STEP
    response_noise_timer = 0.0
    pending_restore_state.clear()
    state_dirty = true
    _refresh_visuals_v61()

func get_campaign_outcome_v61() -> String:
    if not response_complete:
        return ""
    if selected_choice == CHOICE_DISTRESS:
        return "RESCUE PRIORITY — survey distress carrier acknowledged."
    if selected_choice == CHOICE_CONTAINMENT:
        return "ANOMALY PRIORITY — containment topology decoded."
    return ""

@rpc("any_peer", "call_remote", "reliable", 65)
func _request_choice_remote_v61(choice_id: String) -> void:
    if not _is_host_v61() or choice_id not in VALID_CHOICES:
        return
    _commit_choice_v61(multiplayer.get_remote_sender_id(), choice_id)

@rpc("authority", "call_remote", "reliable", 65)
func _receive_payoff_state_v61(state: Dictionary) -> void:
    _apply_state_v61(state)
    _refresh_visuals_v61()

@rpc("authority", "call_remote", "reliable", 65)
func _payoff_feedback_v61(text: String) -> void:
    _announce_local_v61(text)

func _commit_choice_v61(peer_id: int, choice_id: String) -> void:
    if not selected_choice.is_empty() or not _routing_terminal_reviewed_v61():
        _announce_peer_v61(peer_id, "Review the restricted routing table before committing the facility response.")
        return
    var terminal: Node3D = terminals.get(choice_id) as Node3D
    if terminal == null or not _peer_near_position_v61(peer_id, terminal.global_position, CHOICE_DISTANCE):
        _announce_peer_v61(peer_id, "Move closer to the routing terminal before committing this decision.")
        return

    selected_choice = choice_id
    response_active = true
    response_complete = false
    response_remaining = DISTRESS_RESPONSE_SECONDS if choice_id == CHOICE_DISTRESS else CONTAINMENT_RESPONSE_SECONDS
    active_beacon_index = 0 if choice_id == CHOICE_DISTRESS else 1
    beacon_step_remaining = DISTRESS_BEACON_STEP
    response_noise_timer = 1.0
    state_dirty = true

    var text: String
    if choice_id == CHOICE_DISTRESS:
        text = "RESCUE PRIORITY COMMITTED — hold the moving emergency carrier while the survey distress packet transmits."
    else:
        text = "ANOMALY PRIORITY COMMITTED — remain inside the central containment carrier while the topology decrypts."
    _announce_peer_v61(peer_id, text)
    _report_noise_v61(terminal.global_position, 1.15, "research routing commitment")
    _request_autosave_v61("Research Facility decision committed")
    _refresh_visuals_v61()

func _complete_response_v61() -> void:
    if response_complete:
        return
    response_active = false
    response_complete = true
    response_remaining = 0.0
    state_dirty = true

    var pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
    if pacing != null and pacing.has_method("force_recovery"):
        pacing.call("force_recovery", 12.0, "research payoff complete")

    var outcome: String = get_campaign_outcome_v61()
    if selected_choice == CHOICE_DISTRESS:
        _announce_local_v61("CAMPAIGN PAYOFF — %s At least one biometric ping answered. Future route priority: FIND THE SURVEY TEAM." % outcome)
    else:
        _announce_local_v61("CAMPAIGN PAYOFF — %s The deeper network is mapped. Future route priority: CONTAIN THE ANOMALY." % outcome)
    _request_autosave_v61("Research Facility response complete")

func _apply_local_interference_v61(delta: float) -> void:
    var player: CharacterBody3D = _local_player_v61()
    if player == null or bool(player.get("is_dead")):
        return
    var safe_index: int = active_beacon_index if selected_choice == CHOICE_DISTRESS else 1
    var safe_position: Vector3 = BEACON_POSITIONS[safe_index]
    var distance: float = player.global_position.distance_to(safe_position)
    var exposure: float = float(player.get("darkness_exposure"))
    if distance <= SAFE_BEACON_RADIUS:
        player.set("darkness_exposure", maxf(0.0, exposure - 12.0 * delta))
    else:
        player.set("darkness_exposure", minf(100.0, exposure + INTERFERENCE_EXPOSURE_PER_SECOND * delta))

func _configure_scene_v61(scene: Node) -> void:
    for _frame_index: int in range(180):
        await get_tree().process_frame
        if not is_instance_valid(scene) or get_tree().current_scene != scene:
            return
        if scene.get_node_or_null("EvidenceFacilityTerminal") != null:
            break
    if not is_instance_valid(scene) or get_tree().current_scene != scene:
        return

    var old: Node = scene.get_node_or_null("ResearchPayoffV61")
    if old != null:
        old.free()
    runtime_root = Node3D.new()
    runtime_root.name = "ResearchPayoffV61"
    scene.add_child(runtime_root)

    _spawn_terminal_v61(CHOICE_DISTRESS, "Distress Routing Terminal", Vector3(TERMINAL_POSITIONS[CHOICE_DISTRESS]))
    _spawn_terminal_v61(CHOICE_CONTAINMENT, "Containment Data Terminal", Vector3(TERMINAL_POSITIONS[CHOICE_CONTAINMENT]))
    for index: int in range(BEACON_POSITIONS.size()):
        _spawn_beacon_v61(index, BEACON_POSITIONS[index])

    if not pending_restore_state.is_empty():
        _apply_state_v61(pending_restore_state)
    _refresh_visuals_v61()

func _spawn_terminal_v61(choice_id: String, display_name: String, position: Vector3) -> void:
    if runtime_root == null or terminal_script == null:
        return
    var body: StaticBody3D = StaticBody3D.new()
    body.name = "DistressChoiceTerminal" if choice_id == CHOICE_DISTRESS else "ContainmentChoiceTerminal"
    body.set_script(terminal_script)
    body.set("choice_id", choice_id)
    body.set("display_name", display_name)
    body.position = position
    runtime_root.add_child(body)
    terminals[choice_id] = body

func _spawn_beacon_v61(index: int, position: Vector3) -> void:
    if runtime_root == null:
        return
    var root: Node3D = Node3D.new()
    root.name = "ResponseBeacon%d" % (index + 1)
    root.position = position
    runtime_root.add_child(root)

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.emission_enabled = true
    material.albedo_color = Color(0.07, 0.09, 0.10, 1.0)
    material.emission = Color(0.02, 0.06, 0.08, 1.0)
    beacon_materials.append(material)

    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = 0.18
    mesh.bottom_radius = 0.30
    mesh.height = 0.48
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = material
    visual.position = Vector3(0.0, 0.24, 0.0)
    root.add_child(visual)

    var light: OmniLight3D = OmniLight3D.new()
    light.position = Vector3(0.0, 1.25, 0.0)
    light.light_color = Color(0.26, 0.78, 0.90, 1.0)
    light.omni_range = SAFE_BEACON_RADIUS
    light.light_energy = 0.0
    root.add_child(light)
    beacon_lights.append(light)

    var label: Label3D = Label3D.new()
    label.name = "Label"
    label.text = "CARRIER %d" % (index + 1)
    label.position = Vector3(0.0, 1.75, 0.0)
    label.font_size = 22
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    root.add_child(label)

func _refresh_visuals_v61() -> void:
    for key_variant: Variant in terminals.keys():
        var key: String = str(key_variant)
        var node: Node = terminals.get(key) as Node
        if node != null and node.has_method("set_selected_v61"):
            node.call("set_selected_v61", selected_choice == key, not selected_choice.is_empty() and selected_choice != key)

    for index: int in range(beacon_lights.size()):
        var active: bool = response_active and index == (active_beacon_index if selected_choice == CHOICE_DISTRESS else 1)
        var light: OmniLight3D = beacon_lights[index]
        if light != null:
            light.light_energy = 1.18 if active else 0.02
        if index < beacon_materials.size():
            var material: StandardMaterial3D = beacon_materials[index]
            material.emission = Color(0.10, 0.68, 0.86, 1.0) if active else Color(0.015, 0.05, 0.06, 1.0)
            material.emission_energy_multiplier = 3.2 if active else 0.5

func _routing_terminal_reviewed_v61() -> bool:
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    return investigation != null and investigation.has_method("has_evidence") and bool(investigation.call("has_evidence", "facility_terminal"))

func _apply_state_v61(state: Dictionary) -> void:
    var restored_choice: String = str(state.get("selected_choice", ""))
    selected_choice = restored_choice if restored_choice in VALID_CHOICES else ""
    response_active = bool(state.get("response_active", false)) and not selected_choice.is_empty()
    response_complete = bool(state.get("response_complete", false)) and not selected_choice.is_empty()
    response_remaining = maxf(0.0, float(state.get("response_remaining", 0.0)))
    active_beacon_index = clampi(int(state.get("active_beacon_index", 0)), 0, BEACON_POSITIONS.size() - 1)
    beacon_step_remaining = maxf(0.0, float(state.get("beacon_step_remaining", DISTRESS_BEACON_STEP)))
    if response_complete:
        response_active = false
        response_remaining = 0.0

func _build_sync_state_v61() -> Dictionary:
    return get_save_state()

func _on_peer_connected_v61(peer_id: int) -> void:
    if _network_online_v61() and _is_host_v61() and peer_id > 1:
        _receive_payoff_state_v61.rpc_id(peer_id, _build_sync_state_v61())

func _announce_peer_v61(peer_id: int, text: String) -> void:
    if peer_id == 1:
        _announce_local_v61(text)
    elif _network_online_v61() and _is_host_v61():
        _payoff_feedback_v61.rpc_id(peer_id, text)

func _announce_local_v61(text: String) -> void:
    var player: CharacterBody3D = _local_player_v61()
    if player == null:
        return
    var label: Label = player.get_node_or_null("HUD/Objective") as Label
    if label != null:
        label.text = text

func _local_player_v61() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback

func _peer_position_v61(peer_id: int) -> Variant:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("_peer_position_v57"):
        return network.call("_peer_position_v57", peer_id)
    if peer_id == 1:
        var player: CharacterBody3D = _local_player_v61()
        return player.global_position if player != null else null
    return null

func _peer_near_position_v61(peer_id: int, position: Vector3, max_distance: float) -> bool:
    var value: Variant = _peer_position_v61(peer_id)
    if value == null:
        return false
    var peer_position: Vector3 = value
    return peer_position.distance_to(position) <= max_distance

func _report_noise_v61(position: Vector3, strength: float, label: String) -> void:
    var relay: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if relay != null and relay.has_method("report_noise"):
        relay.call("report_noise", position, strength, label)

func _request_autosave_v61(reason: String) -> void:
    var save: Node = get_node_or_null("/root/SaveSystem")
    if save != null and save.has_method("request_autosave"):
        save.call("request_autosave", reason)

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
