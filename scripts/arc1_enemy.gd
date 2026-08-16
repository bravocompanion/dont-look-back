extends Node3D

@export var enemy_id: String = "mourner_a"
@export var enemy_kind: String = "mourner"
@export var activation_stage: int = 1
@export var move_speed: float = 1.75
@export var attack_damage: float = 12.0
@export var detection_radius: float = 18.0
@export var attack_distance: float = 1.15
@export var attack_cooldown_seconds: float = 2.4

var home_position: Vector3 = Vector3.ZERO
var patrol_phase: float = 0.0
var attack_timer: float = 0.0
var send_timer: float = 0.0
var active: bool = false
var remote_target_position: Vector3 = Vector3.ZERO
var remote_target_yaw: float = 0.0
var remote_has_state: bool = false
var last_target_peer: int = 0

func _ready() -> void:
    home_position = global_position
    patrol_phase = float(abs(hash(enemy_id)) % 1000) * 0.01
    remote_target_position = global_position
    remote_target_yaw = rotation.y
    add_to_group("arc1_enemy")
    _build_visual()
    visible = false

func _process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)

    var system: Node = get_node_or_null("/root/LabyrinthArc1System")
    if system == null:
        visible = false
        return

    var should_be_active: bool = bool(system.call("should_enemy_be_active", enemy_id, activation_stage)) if system.has_method("should_enemy_be_active") else false
    var director: Node = get_node_or_null("/root/LabyrinthEncounterDirector")
    if should_be_active and director != null and director.has_method("is_enemy_enabled"):
        should_be_active = bool(director.call("is_enemy_enabled", enemy_id, activation_stage))

    var authoritative: bool = _is_authoritative_simulation()

    if authoritative:
        var became_active: bool = should_be_active and not active
        if became_active:
            global_position = home_position
            remote_target_position = home_position
            attack_timer = maxf(attack_timer, 0.75)
        active = should_be_active
        visible = active
        if active:
            _drive_authoritative(delta, system)
        _send_network_state(delta)
    else:
        active = should_be_active and active
        visible = active
        if remote_has_state:
            global_position = global_position.lerp(remote_target_position, clampf(delta * 12.0, 0.0, 1.0))
            rotation.y = lerp_angle(rotation.y, remote_target_yaw, clampf(delta * 10.0, 0.0, 1.0))

func _drive_authoritative(delta: float, system: Node) -> void:
    var target: Dictionary = _select_target()
    var goal: Vector3 = home_position
    var target_peer: int = 0
    var target_lit: bool = false

    if not target.is_empty():
        var position_value: Variant = target.get("position", null)
        if position_value is Vector3:
            goal = position_value
            target_peer = int(target.get("peer_id", 0))
            target_lit = bool(target.get("in_light", false))

    if enemy_kind == "crawler" and target_lit:
        target_peer = 0
        goal = home_position

    if target_peer <= 0:
        var noise_goal: Variant = _best_noise_goal()
        if noise_goal is Vector3 and enemy_kind == "mourner":
            goal = noise_goal
        else:
            patrol_phase += delta * 0.42
            var patrol_radius: float = 4.2 if enemy_kind == "mourner" else 5.8
            goal = home_position + Vector3(sin(patrol_phase) * patrol_radius, 0.0, cos(patrol_phase * 0.77) * patrol_radius)

    var aggression: float = float(system.call("get_enemy_aggression_multiplier")) if system.has_method("get_enemy_aggression_multiplier") else 1.0
    var speed: float = move_speed * aggression
    if enemy_kind == "mourner" and target_lit:
        speed *= 0.58
    elif enemy_kind == "crawler" and target_peer > 0:
        speed *= 1.16

    var next_point: Vector3 = _next_navigation_point(goal)
    next_point.y = global_position.y
    var direction: Vector3 = next_point - global_position
    direction.y = 0.0
    if direction.length() > 0.08:
        direction = direction.normalized()
        global_position += direction * speed * delta
        var look_target: Vector3 = global_position + direction
        look_target.y = global_position.y + (0.58 if enemy_kind == "crawler" else 1.25)
        look_at(look_target, Vector3.UP)

    last_target_peer = target_peer
    if target_peer > 0 and attack_timer <= 0.0:
        var target_position: Vector3 = goal
        target_position.y = global_position.y
        if global_position.distance_to(target_position) <= attack_distance and _line_clear_to(target_position):
            _attack_target(target_peer)

func _select_target() -> Dictionary:
    var result: Dictionary = {}
    var best_distance: float = INF
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))

    if online:
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop == null or not coop.has_method("_get_active_peer_ids") or not coop.has_method("_get_survivor_state"):
            return result
        var ids_value: Variant = coop.call("_get_active_peer_ids")
        if not (ids_value is Array):
            return result
        for peer_variant: Variant in Array(ids_value):
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
            if distance > detection_radius or distance >= best_distance:
                continue
            best_distance = distance
            result = {
                "peer_id": peer_id,
                "position": position,
                "in_light": bool(state.get("in_light", false))
            }
        return result

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return result
    var local_distance: float = _horizontal_distance(global_position, player.global_position)
    if local_distance > detection_radius:
        return result
    var player_lit: bool = player.has_method("is_in_light") and bool(player.call("is_in_light"))
    return {
        "peer_id": 1,
        "position": player.global_position,
        "in_light": player_lit
    }

func _best_noise_goal() -> Variant:
    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation == null or not navigation.has_method("_best_audible_noise"):
        return null
    var noise_value: Variant = navigation.call("_best_audible_noise", global_position)
    if not (noise_value is Dictionary):
        return null
    var noise: Dictionary = Dictionary(noise_value)
    return noise.get("position", null)

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
    attack_timer = attack_cooldown_seconds
    var source_name: String = "The Mourner" if enemy_kind == "mourner" else "The Crawler"
    _report_noise(0.85, "%s attack" % source_name)

    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online:
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null and coop.has_method("damage_survivor"):
            coop.call("damage_survivor", peer_id, attack_damage, source_name)
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null and player.has_method("apply_damage"):
        player.call("apply_damage", attack_damage, source_name)

func _send_network_state(delta: float) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return
    if not network.has_method("is_server") or not bool(network.call("is_server")):
        return
    send_timer -= delta
    if send_timer > 0.0:
        return
    send_timer = 0.10
    _receive_enemy_state.rpc(global_position, rotation.y, active)

@rpc("authority", "call_remote", "unreliable", 9)
func _receive_enemy_state(position: Vector3, yaw: float, enabled: bool) -> void:
    remote_target_position = position
    remote_target_yaw = yaw
    remote_has_state = true
    active = enabled
    visible = enabled

func _is_authoritative_simulation() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return true
    return network.has_method("is_server") and bool(network.call("is_server"))

func _report_noise(strength: float, label: String) -> void:
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise != null and noise.has_method("report_noise"):
        noise.call("report_noise", global_position, strength, label)

func _build_visual() -> void:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.018, 0.018, 0.020, 1.0) if enemy_kind == "mourner" else Color(0.028, 0.020, 0.018, 1.0)
    material.roughness = 1.0

    var eye_material: StandardMaterial3D = StandardMaterial3D.new()
    eye_material.albedo_color = Color(0.62, 0.60, 0.50, 1.0) if enemy_kind == "mourner" else Color(0.54, 0.12, 0.08, 1.0)
    eye_material.emission_enabled = true
    eye_material.emission = eye_material.albedo_color
    eye_material.emission_energy_multiplier = 2.1

    if enemy_kind == "mourner":
        var body_mesh: CapsuleMesh = CapsuleMesh.new()
        body_mesh.radius = 0.34
        body_mesh.height = 2.25
        body_mesh.radial_segments = 10
        body_mesh.rings = 5
        var body: MeshInstance3D = MeshInstance3D.new()
        body.mesh = body_mesh
        body.material_override = material
        body.position.y = 1.18
        add_child(body)

        var eye_positions: Array[float] = [-0.10, 0.10]
        for eye_x: float in eye_positions:
            var eye_mesh: SphereMesh = SphereMesh.new()
            eye_mesh.radius = 0.045
            eye_mesh.height = 0.09
            eye_mesh.radial_segments = 6
            eye_mesh.rings = 3
            var eye: MeshInstance3D = MeshInstance3D.new()
            eye.mesh = eye_mesh
            eye.material_override = eye_material
            eye.position = Vector3(eye_x, 1.72, -0.30)
            add_child(eye)
    else:
        var crawler_mesh: CapsuleMesh = CapsuleMesh.new()
        crawler_mesh.radius = 0.32
        crawler_mesh.height = 1.65
        crawler_mesh.radial_segments = 10
        crawler_mesh.rings = 4
        var crawler: MeshInstance3D = MeshInstance3D.new()
        crawler.mesh = crawler_mesh
        crawler.material_override = material
        crawler.rotation.x = deg_to_rad(90.0)
        crawler.position.y = 0.42
        add_child(crawler)

        var crawler_eye_mesh: SphereMesh = SphereMesh.new()
        crawler_eye_mesh.radius = 0.07
        crawler_eye_mesh.height = 0.14
        crawler_eye_mesh.radial_segments = 6
        crawler_eye_mesh.rings = 3
        var crawler_eye: MeshInstance3D = MeshInstance3D.new()
        crawler_eye.mesh = crawler_eye_mesh
        crawler_eye.material_override = eye_material
        crawler_eye.position = Vector3(0.0, 0.50, -0.76)
        add_child(crawler_eye)

func _horizontal_distance(first: Vector3, second: Vector3) -> float:
    return Vector2(first.x - second.x, first.z - second.z).length()
