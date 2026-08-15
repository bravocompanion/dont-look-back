extends "res://scripts/player.gd"

@export var jump_velocity: float = 4.6
@export var jump_stamina_cost: float = 8.0
@export var max_step_height: float = 0.80
@export var step_probe_multiplier: float = 2.4
@export var coyote_time: float = 0.11
@export var jump_buffer_time: float = 0.13

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

func _ready() -> void:
    super._ready()
    controls_label.text = "WASD Move   Shift Sprint   Space Jump   E Interact   F Flashlight   B Battery   1 Food   2 Water   3 Medkit"

func _process_mobile_actions() -> void:
    super._process_mobile_actions()
    if is_dead or not MobileControls.is_mobile_active():
        return
    if MobileControls.consume_action("jump"):
        _queue_jump()

func _unhandled_input(event: InputEvent) -> void:
    super._unhandled_input(event)
    if is_dead or MobileControls.is_mobile_active():
        return
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_SPACE:
            _queue_jump()
            get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    var grounded_before_move: bool = is_on_floor()
    if grounded_before_move:
        coyote_timer = coyote_time
    else:
        coyote_timer = maxf(0.0, coyote_timer - delta)
    jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

    if not grounded_before_move:
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.1

    var jumped_this_frame: bool = false
    if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and _can_jump_now():
        velocity.y = jump_velocity
        stamina = maxf(0.0, stamina - jump_stamina_cost)
        jump_buffer_timer = 0.0
        coyote_timer = 0.0
        grounded_before_move = false
        jumped_this_frame = true

    var x_input: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
    var z_input: float = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
    var input_vector: Vector2 = Vector2(x_input, z_input)

    if MobileControls.is_mobile_active():
        input_vector += MobileControls.get_move_vector()

    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    var keyboard_sprint: bool = Input.is_physical_key_pressed(KEY_SHIFT)
    var touch_sprint: bool = MobileControls.is_mobile_active() and MobileControls.is_sprint_pressed()
    var wants_sprint: bool = (keyboard_sprint or touch_sprint) and input_vector.length() > 0.1
    var can_sprint: bool = stamina > 0.5 and hunger > 5.0 and thirst > 5.0
    is_sprinting = wants_sprint and can_sprint

    if is_sprinting:
        stamina = maxf(0.0, stamina - stamina_drain_per_second * delta)
    else:
        var regen_multiplier: float = 1.0
        if hunger < 30.0:
            regen_multiplier *= 0.65
        if thirst < 30.0:
            regen_multiplier *= 0.55
        if darkness_exposure >= 75.0:
            regen_multiplier *= 0.75
        stamina = minf(max_stamina, stamina + stamina_regen_per_second * regen_multiplier * delta)

    var condition_speed_multiplier: float = 1.0
    if hunger < 15.0 or thirst < 15.0:
        condition_speed_multiplier = 0.82

    var current_speed: float = move_speed * condition_speed_multiplier
    if is_sprinting:
        current_speed *= sprint_multiplier

    var direction: Vector3 = (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
    var target_x: float = direction.x * current_speed
    var target_z: float = direction.z * current_speed
    velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target_z, acceleration * delta)

    if grounded_before_move and not jumped_this_frame and direction.length_squared() > 0.01:
        _try_step_up(direction, current_speed, delta)

    move_and_slide()
    _update_footsteps(delta)
    _update_interaction_hint()

func _queue_jump() -> void:
    jump_buffer_timer = jump_buffer_time

func _can_jump_now() -> bool:
    if stamina < jump_stamina_cost:
        return false
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null and bool(coop.get("local_downed")):
        return false
    return true

func _try_step_up(direction: Vector3, horizontal_speed: float, delta: float) -> bool:
    var allowed_step: float = _effective_step_height()
    if allowed_step <= 0.05 or horizontal_speed <= 0.05:
        return false

    var probe_distance: float = clampf(horizontal_speed * delta * step_probe_multiplier, 0.08, 0.30)
    var probe_motion: Vector3 = direction.normalized() * probe_distance
    if not test_move(global_transform, probe_motion):
        return false

    var up_motion: Vector3 = Vector3.UP * allowed_step
    if test_move(global_transform, up_motion):
        return false

    var raised_transform: Transform3D = global_transform.translated(up_motion)
    if test_move(raised_transform, probe_motion):
        return false

    var current_hit: Dictionary = _floor_hit(global_position, global_position.y + 0.22, global_position.y - 1.55)
    if current_hit.is_empty():
        return false

    var future_position: Vector3 = global_position + probe_motion
    var future_hit: Dictionary = _floor_hit(
        future_position,
        global_position.y + allowed_step + 0.32,
        global_position.y - 1.20
    )
    if future_hit.is_empty():
        return false

    var current_point_value: Variant = current_hit.get("position", null)
    var future_point_value: Variant = future_hit.get("position", null)
    if not (current_point_value is Vector3) or not (future_point_value is Vector3):
        return false

    var current_point: Vector3 = current_point_value
    var future_point: Vector3 = future_point_value
    var step_height: float = future_point.y - current_point.y
    if step_height <= 0.025 or step_height > allowed_step:
        return false

    var lift: Vector3 = Vector3.UP * (step_height + 0.025)
    if test_move(global_transform, lift):
        return false

    global_position += lift
    velocity.y = maxf(0.0, velocity.y)
    return true

func _effective_step_height() -> float:
    var allowed: float = max_step_height
    var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null and collision.shape is CapsuleShape3D:
        var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
        var half_player_height: float = capsule.height * 0.5
        allowed = minf(allowed, maxf(0.0, half_player_height - 0.05))
    return allowed

func _floor_hit(horizontal_position: Vector3, top_y: float, bottom_y: float) -> Dictionary:
    var world: World3D = get_world_3d()
    if world == null:
        return {}
    var start: Vector3 = Vector3(horizontal_position.x, top_y, horizontal_position.z)
    var finish: Vector3 = Vector3(horizontal_position.x, bottom_y, horizontal_position.z)
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, finish)
    var excludes: Array[RID] = [get_rid()]
    query.exclude = excludes
    query.collide_with_areas = false
    query.collide_with_bodies = true
    return world.direct_space_state.intersect_ray(query)
