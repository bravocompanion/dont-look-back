extends Node3D

@export var player_path: NodePath
@export var objective_label_path: NodePath
@export var panic_label_path: NodePath
@export var panic_overlay_path: NodePath
@export var caught_panel_path: NodePath
@export var walk_speed: float = 1.65
@export var panic_speed: float = 2.35
@export var catch_distance: float = 1.15
@export var watch_dot_threshold: float = 0.72
@export var attack_damage: float = 28.0
@export var attack_cooldown: float = 2.4
@export var retreat_distance: float = 3.8

var active: bool = false
var panic: float = 0.0
var can_move: bool = false
var base_flashlight_energy: float = 3.5
var attack_timer: float = 0.0

func _ready() -> void:
    visible = false

func appear() -> void:
    var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D
    if player == null:
        return

    global_position = Vector3(
        clampf(player.global_position.x, -1.35, 1.35),
        0.0,
        minf(player.global_position.z + 5.0, 10.4)
    )

    visible = true
    active = true
    panic = 12.0
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
    panic = 0.0
    attack_timer = 0.0
    _update_hud()

    var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D
    if player != null:
        var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
        if flashlight != null:
            flashlight.light_energy = base_flashlight_energy

func _process(delta: float) -> void:
    if attack_timer > 0.0:
        attack_timer = maxf(0.0, attack_timer - delta)

    if not active or not visible:
        return

    var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D
    if player == null:
        return

    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return

    var target_position: Vector3 = Vector3(player.global_position.x, global_position.y, player.global_position.z)
    var distance: float = global_position.distance_to(target_position)
    var watched: bool = _is_being_watched(camera, player)

    if can_move and not watched:
        var direction: Vector3 = target_position - global_position
        direction.y = 0.0
        if direction.length() > 0.01:
            direction = direction.normalized()
            var speed: float = panic_speed if panic >= 60.0 else walk_speed
            global_position += direction * speed * delta
            look_at(Vector3(player.global_position.x, 1.25, player.global_position.z), Vector3.UP)

    distance = global_position.distance_to(target_position)
    _update_panic(delta, distance, watched)
    _update_flashlight(player)
    _update_hud()

    if distance <= catch_distance and attack_timer <= 0.0:
        _attack_player(player, target_position)

func _attack_player(player: CharacterBody3D, target_position: Vector3) -> void:
    attack_timer = attack_cooldown
    panic = minf(100.0, panic + 20.0)

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

    global_position += retreat_direction * retreat_distance
    global_position.x = clampf(global_position.x, -1.45, 1.45)
    global_position.z = clampf(global_position.z, -10.0, 10.4)

    can_move = false
    await get_tree().create_timer(0.55).timeout
    if active:
        can_move = true

func _is_being_watched(camera: Camera3D, player: CharacterBody3D) -> bool:
    var monster_focus: Vector3 = global_position + Vector3(0.0, 1.35, 0.0)
    if not camera.is_position_in_frustum(monster_focus):
        return false

    var forward: Vector3 = -camera.global_transform.basis.z.normalized()
    var to_monster: Vector3 = (monster_focus - camera.global_position).normalized()
    if forward.dot(to_monster) < watch_dot_threshold:
        return false

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera.global_position, monster_focus)
    query.exclude = [player.get_rid()]
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty()

func _update_panic(delta: float, distance: float, watched: bool) -> void:
    if watched:
        if distance < 4.5:
            panic += (4.5 - distance) * 1.8 * delta
        else:
            panic -= 7.5 * delta
    else:
        var proximity: float = clampf(11.0 - distance, 0.0, 11.0)
        panic += (4.0 + proximity * 1.55) * delta

    panic = clampf(panic, 0.0, 100.0)

func _update_flashlight(player: CharacterBody3D) -> void:
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if flashlight == null:
        return

    if panic < 72.0:
        flashlight.light_energy = base_flashlight_energy
        return

    var pulse: float = 0.72 + 0.28 * absf(sin(float(Time.get_ticks_msec()) / 85.0))
    var panic_factor: float = lerpf(1.0, 0.58, (panic - 72.0) / 28.0)
    flashlight.light_energy = base_flashlight_energy * pulse * panic_factor

func _update_hud() -> void:
    var panic_label: Label = get_node_or_null(panic_label_path) as Label
    if panic_label != null:
        panic_label.text = "PANIC %d%%" % int(round(panic))

    var overlay: ColorRect = get_node_or_null(panic_overlay_path) as ColorRect
    if overlay != null:
        var alpha: float = lerpf(0.0, 0.23, panic / 100.0)
        overlay.color = Color(0.18, 0.0, 0.0, alpha)
