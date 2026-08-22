extends Node

# v0.58 Mine signature mechanic: one shared support-light circuit can be powered
# at a time. The team chooses safer upper-shaft traversal or deep-shaft light.
# Optional Forest Water Sample grants a permanent stabilized junction light.

const MINE_SCENE_PATH: String = "res://scenes/mine.tscn"
const CONSOLE_SCRIPT_PATH: String = "res://scripts/mine_power_console.gd"
const ROOT_NAME: String = "V58MinePowerRouting"
const CIRCUIT_UPPER: String = "upper"
const CIRCUIT_DEEP: String = "deep"

@export var interaction_distance: float = 3.6
@export var powered_energy: float = 2.25
@export var powered_range: float = 8.5
@export var sample_bonus_energy: float = 1.65
@export var sample_bonus_range: float = 6.4

var current_circuit: String = CIRCUIT_UPPER
var configured_scene_id: int = 0
var runtime_root: Node3D
var console_script: Script
var upper_lights: Array[OmniLight3D] = []
var deep_lights: Array[OmniLight3D] = []
var sample_light: OmniLight3D
var sample_bonus_active: bool = false
var bonus_refresh_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    console_script = load(CONSOLE_SCRIPT_PATH) as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != MINE_SCENE_PATH:
        configured_scene_id = 0
        runtime_root = null
        upper_lights.clear()
        deep_lights.clear()
        sample_light = null
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        call_deferred("_configure_mine", scene)
        return

    if runtime_root == null or not is_instance_valid(runtime_root):
        return

    bonus_refresh_timer -= delta
    if bonus_refresh_timer <= 0.0:
        bonus_refresh_timer = 0.5
        var new_bonus: bool = _water_sample_bonus_available()
        if new_bonus != sample_bonus_active:
            sample_bonus_active = new_bonus
            _apply_light_state()

func request_select_circuit(circuit_id: String) -> void:
    if circuit_id != CIRCUIT_UPPER and circuit_id != CIRCUIT_DEEP:
        return
    if _network_online() and not _is_host():
        _request_select_circuit_remote.rpc_id(1, circuit_id)
        return
    _select_circuit_authoritative(circuit_id, _local_peer_id())

@rpc("any_peer", "call_remote", "reliable", 59)
func _request_select_circuit_remote(circuit_id: String) -> void:
    if not _is_host() or (circuit_id != CIRCUIT_UPPER and circuit_id != CIRCUIT_DEEP):
        return
    var peer_id: int = multiplayer.get_remote_sender_id()
    if peer_id <= 1:
        return
    _select_circuit_authoritative(circuit_id, peer_id)

@rpc("authority", "call_remote", "reliable", 59)
func _sync_circuit_remote(circuit_id: String) -> void:
    if circuit_id != CIRCUIT_UPPER and circuit_id != CIRCUIT_DEEP:
        return
    current_circuit = circuit_id
    _apply_light_state()
    _message_local(_circuit_message(circuit_id))

func _select_circuit_authoritative(circuit_id: String, peer_id: int) -> void:
    if not _peer_can_use_console(peer_id, circuit_id):
        _feedback_peer(peer_id, "MINE POWER: Move closer to a matching power-routing console.")
        return
    if current_circuit == circuit_id:
        _feedback_peer(peer_id, "%s circuit is already powered." % _circuit_label(circuit_id))
        return

    current_circuit = circuit_id
    _apply_light_state()
    _report_power_noise()
    if _network_online():
        _sync_circuit_remote.rpc(circuit_id)
    _feedback_peer(peer_id, _circuit_message(circuit_id))

func _configure_mine(scene: Node) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if scene == null or not is_instance_valid(scene) or get_tree().current_scene != scene:
        return

    var old_root: Node = scene.get_node_or_null(NodePath(ROOT_NAME))
    if old_root != null:
        old_root.free()

    runtime_root = Node3D.new()
    runtime_root.name = ROOT_NAME
    scene.add_child(runtime_root)
    upper_lights.clear()
    deep_lights.clear()
    sample_light = null

    # Entrance station: establishes the rule before the first evidence room.
    _add_console("EntranceUpperConsole", CIRCUIT_UPPER, "UPPER SHAFT", Vector3(-1.35, 0.92, 5.6))
    _add_console("EntranceDeepConsole", CIRCUIT_DEEP, "DEEP SHAFT", Vector3(1.35, 0.92, 5.6))

    # Mid-shaft station prevents tedious full backtracking and creates a choice
    # at the point where the investigation starts pushing deeper underground.
    _add_console("JunctionUpperConsole", CIRCUIT_UPPER, "UPPER SHAFT", Vector3(-1.15, 0.92, -33.0))
    _add_console("JunctionDeepConsole", CIRCUIT_DEEP, "DEEP SHAFT", Vector3(1.15, 0.92, -33.0))

    upper_lights.append(_add_support_light("UpperLightA", Vector3(0.0, 2.15, -11.0)))
    upper_lights.append(_add_support_light("UpperLightB", Vector3(0.0, 2.15, -24.0)))
    deep_lights.append(_add_support_light("DeepLightA", Vector3(0.0, 2.15, -43.0)))
    deep_lights.append(_add_support_light("DeepLightB", Vector3(0.0, 2.15, -56.0)))
    deep_lights.append(_add_support_light("DeepLightC", Vector3(0.0, 2.15, -67.0)))

    sample_light = _add_support_light("StabilizedJunctionLight", Vector3(0.0, 2.0, -34.5))
    sample_bonus_active = _water_sample_bonus_available()
    _apply_light_state()

    _message_local(
        "MINE POWER: Only one shaft circuit can stay lit. Use a routing console to choose UPPER or DEEP support lights."
    )

func _add_console(node_name: String, circuit_id: String, label_text: String, position_value: Vector3) -> void:
    if runtime_root == null or console_script == null:
        return
    var body: StaticBody3D = StaticBody3D.new()
    body.name = node_name
    body.position = position_value
    body.set_script(console_script)
    body.set("circuit_id", circuit_id)
    body.set("display_name", label_text)
    runtime_root.add_child(body)

    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(0.8, 1.25, 0.32)
    mesh_instance.mesh = mesh
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.10, 0.115, 0.11, 1.0)
    material.metallic = 0.48
    material.roughness = 0.52
    mesh_instance.material_override = material
    body.add_child(mesh_instance)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(0.8, 1.25, 0.32)
    collision.shape = shape
    body.add_child(collision)

    var label: Label3D = Label3D.new()
    label.text = label_text
    label.position = Vector3(0.0, 0.82, 0.20)
    label.font_size = 26
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    body.add_child(label)

func _add_support_light(node_name: String, position_value: Vector3) -> OmniLight3D:
    var light: OmniLight3D = OmniLight3D.new()
    light.name = node_name
    light.position = position_value
    light.light_color = Color(0.74, 0.82, 0.72, 1.0)
    light.light_energy = powered_energy
    light.omni_range = powered_range
    light.shadow_enabled = false
    runtime_root.add_child(light)
    return light

func _apply_light_state() -> void:
    for light: OmniLight3D in upper_lights:
        if light != null and is_instance_valid(light):
            light.visible = current_circuit == CIRCUIT_UPPER
            light.light_energy = powered_energy
            light.omni_range = powered_range
    for light: OmniLight3D in deep_lights:
        if light != null and is_instance_valid(light):
            light.visible = current_circuit == CIRCUIT_DEEP
            light.light_energy = powered_energy
            light.omni_range = powered_range
    if sample_light != null and is_instance_valid(sample_light):
        sample_light.visible = sample_bonus_active
        sample_light.light_energy = sample_bonus_energy
        sample_light.omni_range = sample_bonus_range

func _water_sample_bonus_available() -> bool:
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    if investigation == null:
        return false
    if investigation.has_method("has_water_sample_bonus_v58"):
        return bool(investigation.call("has_water_sample_bonus_v58"))
    return investigation.has_method("has_evidence") and bool(investigation.call("has_evidence", "water_sample"))

func _peer_can_use_console(peer_id: int, circuit_id: String) -> bool:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != MINE_SCENE_PATH:
        return false
    var peer_position_result: Dictionary = _peer_position(peer_id)
    if not bool(peer_position_result.get("valid", false)):
        return false
    var position_value: Variant = peer_position_result.get("position", null)
    if not (position_value is Vector3):
        return false
    var peer_position: Vector3 = position_value

    for node: Node in get_tree().get_nodes_in_group("mine_power_console"):
        var console: Node3D = node as Node3D
        if console == null or str(console.get("circuit_id")) != circuit_id:
            continue
        if peer_position.distance_to(console.global_position) <= interaction_distance:
            return true
    return false

func _peer_position(peer_id: int) -> Dictionary:
    if not _network_online() or peer_id == _local_peer_id():
        var player: CharacterBody3D = _local_player()
        if player == null:
            return {"valid": false}
        return {"valid": true, "position": player.global_position}

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return {"valid": false}
    var states_value: Variant = coop.get("survivor_states")
    if not (states_value is Dictionary):
        return {"valid": false}
    var state: Dictionary = Dictionary(Dictionary(states_value).get(peer_id, {}))
    if state.is_empty() or bool(state.get("downed", false)):
        return {"valid": false}
    var transform_value: Variant = state.get("transform", null)
    if not (transform_value is Transform3D):
        return {"valid": false}
    var survivor_transform: Transform3D = transform_value
    return {"valid": true, "position": survivor_transform.origin}

func _report_power_noise() -> void:
    var relay: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if relay == null:
        return
    if relay.has_method("report_noise"):
        var player: CharacterBody3D = _local_player()
        var origin: Vector3 = player.global_position if player != null else Vector3.ZERO
        relay.call("report_noise", origin, 0.92, "mine power routing")

func _circuit_label(circuit_id: String) -> String:
    return "UPPER SHAFT" if circuit_id == CIRCUIT_UPPER else "DEEP SHAFT"

func _circuit_message(circuit_id: String) -> String:
    var suffix: String = " Stabilized junction light remains active from the Water Sample analysis." if sample_bonus_active else ""
    return "MINE POWER: %s circuit online.%s" % [_circuit_label(circuit_id), suffix]

func _feedback_peer(peer_id: int, text: String) -> void:
    if not _network_online() or peer_id == _local_peer_id():
        _message_local(text)
        return
    _feedback_remote.rpc_id(peer_id, text)

@rpc("authority", "call_remote", "reliable", 60)
func _feedback_remote(text: String) -> void:
    _message_local(text)

func _message_local(text: String) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _on_peer_connected(peer_id: int) -> void:
    if not _is_host() or peer_id <= 1:
        return
    _sync_circuit_remote.rpc_id(peer_id, current_circuit)

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _local_peer_id() -> int:
    return multiplayer.get_unique_id() if _network_online() else 1

func _local_player() -> CharacterBody3D:
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
