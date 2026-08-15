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

var active := false
var caught := false
var panic: float = 0.0
var can_move := false
var base_flashlight_energy: float = 3.5
var restart_requested := false

func _ready() -> void:
    visible = false

func appear() -> void:
    var player := get_node_or_null(player_path) as CharacterBody3D
    if player == null:
        return

    # The prototype hallway progresses toward -Z, so +Z is always the safe
    # "behind the player" spawn side even if the player enters while looking sideways.
    global_position = Vector3(
        clamp(player.global_position.x, -1.35, 1.35),
        0.0,
        min(player.global_position.z + 5.0, 10.4)
    )

    visible = true
    active = true
    caught = false
    panic = 12.0
    can_move = false
    _update_hud()

    await get_tree().create_timer(0.65).timeout
    can_move = true

func stop_stalking() -> void:
    active = false
    can_move = false
    visible = false

func _process(delta: float) -> void:
    if caught:
        if not restart_requested and Input.is_physical_key_pressed(KEY_R):
            restart_requested = true
            get_tree().reload_current_scene()
        return

    if not active or not visible:
        return

    var player := get_node_or_null(player_path) as CharacterBody3D
    if player == null:
        return

    var camera := player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return

    var target_position := Vector3(player.global_position.x, global_position.y, player.global_position.z)
    var distance := global_position.distance_to(target_position)
    var watched := _is_being_watched(camera, player)

    if can_move and not watched:
        var direction := target_position - global_position
        direction.y = 0.0
        if direction.length() > 0.01:
            direction = direction.normalized()
            var speed := panic_speed if panic >= 60.0 else walk_speed
            global_position += direction * speed * delta
            look_at(Vector3(player.global_position.x, 1.25, player.global_position.z), Vector3.UP)

    distance = global_position.distance_to(target_position)
    _update_panic(delta, distance, watched)
    _update_flashlight(player)
    _update_hud()

    if distance <= catch_distance:
        _catch_player(player)

func _is_being_watched(camera: Camera3D, player: CharacterBody3D) -> bool:
    var monster_focus := global_position + Vector3(0.0, 1.35, 0.0)
    if not camera.is_position_in_frustum(monster_focus):
        return false

    var forward := -camera.global_transform.basis.z.normalized()
    var to_monster := (monster_focus - camera.global_position).normalized()
    if forward.dot(to_monster) < watch_dot_threshold:
        return false

    var query := PhysicsRayQueryParameters3D.create(camera.global_position, monster_focus)
    query.exclude = [player.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)

    # The Tenant has no collision body in this prototype. An empty ray therefore
    # means nothing solid is blocking the player's view of it.
    return hit.is_empty()

func _update_panic(delta: float, distance: float, watched: bool) -> void:
    if watched:
        if distance < 4.5:
            panic += (4.5 - distance) * 1.8 * delta
        else:
            panic -= 7.5 * delta
    else:
        var proximity := clamp(11.0 - distance, 0.0, 11.0)
        panic += (4.0 + proximity * 1.55) * delta

    panic = clamp(panic, 0.0, 100.0)

func _update_flashlight(player: CharacterBody3D) -> void:
    var flashlight := player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if flashlight == null:
        return

    if panic < 72.0:
        flashlight.light_energy = base_flashlight_energy
        return

    var pulse := 0.72 + 0.28 * abs(sin(float(Time.get_ticks_msec()) / 85.0))
    var panic_factor := lerp(1.0, 0.58, (panic - 72.0) / 28.0)
    flashlight.light_energy = base_flashlight_energy * pulse * panic_factor

func _update_hud() -> void:
    var panic_label := get_node_or_null(panic_label_path) as Label
    if panic_label != null:
        panic_label.text = "PANIC %d%%" % int(round(panic))

    var overlay := get_node_or_null(panic_overlay_path) as ColorRect
    if overlay != null:
        var alpha := lerp(0.0, 0.23, panic / 100.0)
        overlay.color = Color(0.18, 0.0, 0.0, alpha)

func _catch_player(player: CharacterBody3D) -> void:
    if caught:
        return

    caught = true
    active = false
    panic = 100.0
    _update_hud()

    player.velocity = Vector3.ZERO
    player.set_physics_process(false)
    player.set_process_unhandled_input(false)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    var objective := get_node_or_null(objective_label_path) as Label
    if objective != null:
        objective.text = ""

    var panel := get_node_or_null(caught_panel_path) as Control
    if panel != null:
        panel.visible = true
