extends Node3D

@export var move_speed: float = 1.78
@export var isolated_speed_multiplier: float = 1.48
@export var safe_light_speed_multiplier: float = 0.48
@export var attack_damage: float = 22.0
@export var attack_distance: float = 1.28
@export var attack_cooldown: float = 2.65
@export var detection_radius: float = 34.0

var home_position: Vector3 = Vector3.ZERO
var attack_timer: float = 0.0
var send_timer: float = 0.0
var pulse_time: float = 0.0
var active: bool = false
var remote_active: bool = false
var remote_position: Vector3 = Vector3.ZERO
var remote_yaw: float = 0.0
var remote_has_state: bool = false
var core_material: StandardMaterial3D

func _ready() -> void:
    home_position = global_position
    remote_position = global_position
    remote_yaw = rotation.y
    add_to_group("arc1_warden")
    _build_visual()
    visible = false

func _process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    pulse_time += delta

    var major: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    if major == null or not major.has_method("is_warden_active"):
        active = false
        visible = false
        return

    var should_be_active: bool = bool(major.call("is_warden_active"))
    if _is_authoritative():
        var became_active: bool = should_be_active and not active
        active = should_be_active
        if became_active:
            global_position = home_position
            attack_timer = 1.0
        visible = active
        if active:
            _drive_authoritative(delta, major)
        _broadcast_state(delta)
    else:
        active = remote_active
        visible = remote_active
        if remote_has_state and remote_active:
            global_position = global_position.lerp(remote_position, clampf(delta * 11.0, 0.0, 1.0))
            rotation.y = lerp_angle(rotation.y, remote_yaw, clampf(delta * 9.0, 0.0, 1.0))

    _update_pulse()

func _drive_authoritative(delta: float, major: Node) -> void:
    var target: Dictionary = _select_target()
    if target.is_empty():
        var patrol_goal: Vector3 = home_position + Vector3(sin(pulse_time * 0.41) * 5.0, 0.0, cos(pulse_time * 0.33) * 4.0)
        _move_toward_goal(patrol_goal, move_speed * 0.62, delta)
        return

    var target_position_value: Variant = target.get("position", null)
    if not (target_position_value is Vector3):
        return
    var target_position: Vector3 = target_position_value
    var target_peer: int = int(target.get("peer_id", 1))
    var isolated: bool = bool(target.get("isolated", false))
    var world_protected: bool = bool(target.get("world_protected", false))

    var aggression: float = 1.0
    if major.has_method("get_warden_aggression_multiplier"):
        aggression = float(major.call("get_warden_aggression_multiplier"))
    var speed: float = move_speed * aggression
    if isolated:
        speed *= isolated_speed_multiplier
    if world_protected:
        speed *= safe_light_speed_multiplier

    _move_toward_goal(target_position, speed, delta)

    var flat_target: Vector3 = target_position
    flat_target.y = global_position.y
    if attack_timer <= 0.0 and global_position.distance_to(flat_target) <= attack_distance and _line_clear_to(flat_target):
        _attack_target(target_peer)

func _move_toward_goal(goal: Vector3, speed: float, delta: float) -> void:
    var next_point: Vector3 = _next_navigation_point(goal)
    next_point.y = global_position.y
    var direction: Vector3 = next_point - global_position
    direction.y = 0.0
    if direction.length() <= 0.08:
        return
    direction = direction.normalized()
    global_position += direction * speed * delta
    var look_target: Vector3 = global_position + direction
    look_target.y = global_position.y + 1.35
    look_at(look_target, Vector3.UP)

func _select_target() -> Dictionary:
    if _network_online():
        return _select_online_target()

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return {}
    var distance: float = _horizontal_distance(global_position, player.global_position)
    if distance > detection_radius:
        return {}
    var world_protected: bool = false
    var scene: Node = get_tree().current_scene
    if scene != null and player.has_method("_has_nearby_world_light"):
        world_protected = bool(player.call("_has_nearby_world_light", scene))
    return {
        "peer_id": 1,
        "position": player.global_position,
        "isolated": false,
        "world_protected": world_protected
    }

func _select_online_target() -> Dictionary:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null or not coop.has_method("_get_active_peer_ids") or not coop.has_method("_get_survivor_state"):
        return {}

    var ids_value: Variant = coop.call("_get_active_peer_ids")
    if not (ids_value is Array):
        return {}
    var ids: Array = Array(ids_value)
    var best: Dictionary = {}
    var best_score: float = -INF

    for peer_variant: Variant in ids:
        var peer_id: int = int(peer_variant)
        var state_value: Variant = coop.call("_get_survivor_state", peer_id)
        if not (state_value is Dictionary):
            continue
        var state: Dictionary = Dictionary(state_value)
        if bool(state.get("downed", false)):
            continue
        var transform_value: Variant = state.get("transform", null)
        if not (transform_value is Transform3D):
            continue
        var survivor_transform: Transform3D = transform_value
        var position: Vector3 = survivor_transform.origin
        var distance: float = _horizontal_distance(global_position, position)
        if distance > detection_radius:
            continue

        var teammate_distance: float = _nearest_teammate_distance(peer_id, position, ids, coop)
        var isolated: bool = teammate_distance >= 14.0
        var darkness: float = float(state.get("darkness", 0.0))
        var score: float = teammate_distance * 1.35 + darkness * 0.035 - distance * 0.28
        if score <= best_score:
            continue
        best_score = score
        var personal_flashlight: bool = bool(state.get("flashlight", false))
        var world_protected: bool = bool(state.get("in_light", false)) and not personal_flashlight
        best = {
            "peer_id": peer_id,
            "position": position,
            "isolated": isolated,
            "world_protected": world_protected
        }
    return best

func _nearest_teammate_distance(peer_id: int, position: Vector3, ids: Array, coop: Node) -> float:
    var nearest: float = 0.0
    var found_other: bool = false
    for other_variant: Variant in ids:
        var other_id: int = int(other_variant)
        if other_id == peer_id:
            continue
        var state_value: Variant = coop.call("_get_survivor_state", other_id)
        if not (state_value is Dictionary):
            continue
        var state: Dictionary = Dictionary(state_value)
        if bool(state.get("downed", false)):
            continue
        var transform_value: Variant = state.get("transform", null)
        if not (transform_value is Transform3D):
            continue
        var other_transform: Transform3D = transform_value
        var distance: float = position.distance_to(other_transform.origin)
        if not found_other or distance < nearest:
            nearest = distance
            found_other = true
    return nearest if found_other else 0.0

func _next_navigation_point(goal: Vector3) -> Vector3:
    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation != null and navigation.has_method("_next_navigation_point"):
        var point_value: Variant = navigation.call("_next_navigation_point", global_position, goal)
        if point_value is Vector3:
            return point_value
    return goal

func _line_clear_to(target_position: Vector3) -> bool:
    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation != null and navigation.has_method("_segment_clear"):
        return bool(navigation.call("_segment_clear", global_position, target_position, 0.0))
    return true

func _attack_target(peer_id: int) -> void:
    attack_timer = attack_cooldown
    _report_noise(1.0, "The Warden impact")

    if _network_online():
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null and coop.has_method("damage_survivor"):
            coop.call("damage_survivor", peer_id, attack_damage, "The Warden")
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null and player.has_method("apply_damage"):
        player.call("apply_damage", attack_damage, "The Warden")

func _broadcast_state(delta: float) -> void:
    if not _network_online() or not _is_authoritative():
        return
    send_timer -= delta
    if send_timer > 0.0:
        return
    send_timer = 0.10
    _receive_warden_state.rpc(global_position, rotation.y, active)

@rpc("authority", "call_remote", "unreliable", 15)
func _receive_warden_state(position: Vector3, yaw: float, enabled: bool) -> void:
    remote_position = position
    remote_yaw = yaw
    remote_active = enabled
    remote_has_state = true

func _report_noise(strength: float, label: String) -> void:
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise != null and noise.has_method("report_noise"):
        noise.call("report_noise", global_position, strength, label)

func _update_pulse() -> void:
    if core_material == null:
        return
    var intensity: float = 0.55 + 0.45 * absf(sin(pulse_time * 2.8))
    core_material.emission_energy_multiplier = 1.1 + intensity * 1.1

func _build_visual() -> void:
    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.016, 0.018, 0.020, 1.0)
    body_material.roughness = 0.92
    body_material.metallic = 0.16

    core_material = StandardMaterial3D.new()
    core_material.albedo_color = Color(0.30, 0.045, 0.035, 1.0)
    core_material.emission_enabled = true
    core_material.emission = Color(0.72, 0.07, 0.035, 1.0)
    core_material.emission_energy_multiplier = 1.4

    var torso_mesh: BoxMesh = BoxMesh.new()
    torso_mesh.size = Vector3(0.92, 1.55, 0.48)
    var torso: MeshInstance3D = MeshInstance3D.new()
    torso.mesh = torso_mesh
    torso.material_override = body_material
    torso.position.y = 1.42
    add_child(torso)

    var head_mesh: BoxMesh = BoxMesh.new()
    head_mesh.size = Vector3(0.56, 0.46, 0.42)
    var head: MeshInstance3D = MeshInstance3D.new()
    head.mesh = head_mesh
    head.material_override = body_material
    head.position = Vector3(0.0, 2.42, -0.03)
    add_child(head)

    var shoulder_mesh: BoxMesh = BoxMesh.new()
    shoulder_mesh.size = Vector3(1.55, 0.22, 0.34)
    var shoulders: MeshInstance3D = MeshInstance3D.new()
    shoulders.mesh = shoulder_mesh
    shoulders.material_override = body_material
    shoulders.position = Vector3(0.0, 2.02, 0.0)
    add_child(shoulders)

    var core_mesh: SphereMesh = SphereMesh.new()
    core_mesh.radius = 0.11
    core_mesh.height = 0.22
    core_mesh.radial_segments = 8
    core_mesh.rings = 4
    var core: MeshInstance3D = MeshInstance3D.new()
    core.mesh = core_mesh
    core.material_override = core_material
    core.position = Vector3(0.0, 1.58, -0.27)
    add_child(core)

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _horizontal_distance(first: Vector3, second: Vector3) -> float:
    return Vector2(first.x - second.x, first.z - second.z).length()
