extends Node3D

@export var player_path: NodePath
@export var objective_label_path: NodePath
@export var panic_label_path: NodePath
@export var panic_overlay_path: NodePath
@export var caught_panel_path: NodePath
@export var walk_speed: float = 1.65
@export var panic_speed: float = 3.00
@export var base_move_speed: float = 1.65
@export var max_move_speed: float = 3.00
@export var catch_distance: float = 1.15
@export var watch_dot_threshold: float = 0.72
@export var attack_damage: float = 28.0
@export var attack_cooldown: float = 2.40
@export var min_attack_cooldown: float = 1.05
@export var retreat_distance: float = 3.8
@export var spawn_distance: float = 4.2

var active: bool = false
var panic: float = 0.0
var can_move: bool = false
var attack_timer: float = 0.0

func _ready() -> void:
    visible = false

func appear() -> void:
    appear_near_player()

func appear_near_player() -> void:
    var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D
    if player == null:
        return

    global_position = _find_near_spawn(player)
    visible = true
    active = true
    panic = clampf(float(player.get("flashlight_panic")), 0.0, 100.0)
    can_move = false
    attack_timer = 0.0
    _update_hud()

    await get_tree().create_timer(0.65).timeout
    if active:
        can_move = true

func stop_stalking() -> void:
    active = false
    can_move = false
    visible = false
    attack_timer = 0.0
    _update_hud()

func get_current_move_speed() -> float:
    var ratio: float = clampf(panic / 100.0, 0.0, 1.0)
    return lerpf(base_move_speed, max_move_speed, ratio)

func get_current_attack_cooldown() -> float:
    var ratio: float = clampf(panic / 100.0, 0.0, 1.0)
    return lerpf(attack_cooldown, min_attack_cooldown, ratio)

func _process(delta: float) -> void:
    if attack_timer > 0.0:
        attack_timer = maxf(0.0, attack_timer - delta)

    if not active or not visible:
        return

    var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D
    if player == null:
        return

    panic = clampf(float(player.get("flashlight_panic")), 0.0, 100.0)
    _update_hud()

    if _network_online():
        return

    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return

    var target_position: Vector3 = Vector3(player.global_position.x, global_position.y, player.global_position.z)
    var distance: float = global_position.distance_to(target_position)
    var watched: bool = _is_being_watched(camera, player)

    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    var navigation_owns_movement: bool = navigation != null
    if can_move and not watched and not navigation_owns_movement:
        var direction: Vector3 = target_position - global_position
        direction.y = 0.0
        if direction.length() > 0.01:
            direction = direction.normalized()
            global_position += direction * get_current_move_speed() * delta
            look_at(Vector3(player.global_position.x, 1.25, player.global_position.z), Vector3.UP)

    distance = global_position.distance_to(target_position)
    if distance <= catch_distance and attack_timer <= 0.0:
        _attack_player(player, target_position)

func _attack_player(player: CharacterBody3D, target_position: Vector3) -> void:
    attack_timer = get_current_attack_cooldown()

    var died: bool = false
    if player.has_method("apply_damage"):
        died = bool(player.call("apply_damage", attack_damage, "The Tenant"))

    if died:
        active = false
        can_move = false
        return

    var retreat_direction: Vector3 = global_position - target_position
    retreat_direction.y = 0.0
    if retreat_direction.length() <= 0.01:
        retreat_direction = Vector3(0.0, 0.0, 1.0)
    else:
        retreat_direction = retreat_direction.normalized()

    global_position = _clamp_tenant_position(global_position + retreat_direction * retreat_distance)
    can_move = false
    await get_tree().create_timer(0.55).timeout
    if active:
        can_move = true

func _is_being_watched(camera: Camera3D, player: CharacterBody3D) -> bool:
    var monster_focus: Vector3 = global_position + Vector3(0.0, 1.35, 0.0)
    if not camera.is_position_in_frustum(monster_focus):
        return false

    var forward: Vector3 = -camera.global_transform.basis.z.normalized()
    var to_monster: Vector3 = monster_focus - camera.global_position
    if to_monster.length() <= 0.01:
        return true
    to_monster = to_monster.normalized()
    if forward.dot(to_monster) < watch_dot_threshold:
        return false

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera.global_position, monster_focus)
    var excludes: Array[RID] = [player.get_rid()]
    query.exclude = excludes
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty()

func _find_near_spawn(player: CharacterBody3D) -> Vector3:
    var backward: Vector3 = player.global_transform.basis.z
    backward.y = 0.0
    if backward.length() <= 0.01:
        backward = Vector3(0.0, 0.0, 1.0)
    else:
        backward = backward.normalized()
    var right: Vector3 = Vector3(backward.z, 0.0, -backward.x)
    var floor_y: float = player.global_position.y - 0.92

    var candidates: Array[Vector3] = [
        player.global_position + backward * spawn_distance,
        player.global_position + backward * 3.5 + right * 2.2,
        player.global_position + backward * 3.5 - right * 2.2,
        player.global_position - backward * 3.8
    ]

    for raw_candidate: Vector3 in candidates:
        var candidate: Vector3 = Vector3(raw_candidate.x, floor_y, raw_candidate.z)
        candidate = _clamp_tenant_position(candidate)
        if _spawn_segment_clear(player.global_position, candidate):
            return candidate

    var fallback: Vector3 = Vector3(
        player.global_position.x + backward.x * spawn_distance,
        floor_y,
        player.global_position.z + backward.z * spawn_distance
    )
    return _clamp_tenant_position(fallback)

func _spawn_segment_clear(from_position: Vector3, to_position: Vector3) -> bool:
    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation != null and navigation.has_method("_segment_clear"):
        return bool(navigation.call("_segment_clear", from_position, to_position, 0.18))
    return true

func _clamp_tenant_position(position: Vector3) -> Vector3:
    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation != null and navigation.has_method("_clamp_monster_position"):
        var clamped_value: Variant = navigation.call("_clamp_monster_position", position)
        if clamped_value is Vector3:
            return clamped_value
    return position

func _update_hud() -> void:
    var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D
    var local_panic: float = panic
    if player != null:
        local_panic = clampf(float(player.get("flashlight_panic")), 0.0, 100.0)

    var panic_label: Label = get_node_or_null(panic_label_path) as Label
    if panic_label != null:
        var language: Node = get_node_or_null("/root/LanguageSystem")
        var prefix: String = "PANIK" if language != null and language.has_method("is_indonesian") and bool(language.call("is_indonesian")) else "PANIC"
        panic_label.text = "%s %d%%" % [prefix, int(round(local_panic))]

    var overlay: ColorRect = get_node_or_null(panic_overlay_path) as ColorRect
    if overlay != null:
        var alpha: float = lerpf(0.0, 0.23, local_panic / 100.0)
        overlay.color = Color(0.18, 0.0, 0.0, alpha)

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))
