extends Node

@export var jump_velocity: float = 4.6
@export var jump_stamina_cost: float = 8.0
@export var max_step_height: float = 0.80
@export var step_probe_multiplier: float = 2.4
@export var coyote_time: float = 0.11
@export var jump_buffer_time: float = 0.13

var tracked_player_id: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_SPACE:
            jump_buffer_timer = jump_buffer_time

func _physics_process(delta: float) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        tracked_player_id = 0
        return

    var player_id: int = int(player.get_instance_id())
    if tracked_player_id != player_id:
        tracked_player_id = player_id
        coyote_timer = 0.0
        jump_buffer_timer = 0.0

    # Disable the legacy straight move_and_slide controller. Survival/HUD logic
    # stays on Player._process(), while this autoload owns locomotion on all maps.
    if player.is_physics_processing():
        player.set_physics_process(false)

    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
    if mobile_active and mobile.has_method("consume_action") and bool(mobile.call("consume_action", "jump")):
        jump_buffer_timer = jump_buffer_time

    if not _movement_allowed(player):
        player.velocity.x = 0.0
        player.velocity.z = 0.0
        return

    var grounded_before_move: bool = player.is_on_floor()
    if grounded_before_move:
        coyote_timer = coyote_time
    else:
        coyote_timer = maxf(0.0, coyote_timer - delta)
    jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

    if not grounded_before_move:
        player.velocity.y -= gravity * delta
    else:
        player.velocity.y = -0.1

    var stamina: float = float(player.get("stamina"))
    var jumped_this_frame: bool = false
    if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and stamina >= jump_stamina_cost:
        player.velocity.y = jump_velocity
        player.set("stamina", maxf(0.0, stamina - jump_stamina_cost))
        jump_buffer_timer = 0.0
        coyote_timer = 0.0
        grounded_before_move = false
        jumped_this_frame = true

    var x_input: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
    var z_input: float = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
    var input_vector: Vector2 = Vector2(x_input, z_input)
    if mobile_active and mobile.has_method("get_move_vector"):
        var move_value: Variant = mobile.call("get_move_vector")
        if move_value is Vector2:
            input_vector += move_value
    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    var keyboard_sprint: bool = Input.is_physical_key_pressed(KEY_SHIFT)
    var touch_sprint: bool = mobile_active and mobile.has_method("is_sprint_pressed") and bool(mobile.call("is_sprint_pressed"))
    var wants_sprint: bool = (keyboard_sprint or touch_sprint) and input_vector.length() > 0.1
    var hunger: float = float(player.get("hunger"))
    var thirst: float = float(player.get("thirst"))
    stamina = float(player.get("stamina"))
    var can_sprint: bool = stamina > 0.5 and hunger > 5.0 and thirst > 5.0
    var is_sprinting: bool = wants_sprint and can_sprint
    player.set("is_sprinting", is_sprinting)

    var stamina_drain: float = float(player.get("stamina_drain_per_second"))
    var stamina_regen: float = float(player.get("stamina_regen_per_second"))
    var max_stamina: float = float(player.get("max_stamina"))
    var darkness_exposure: float = float(player.get("darkness_exposure"))
    if is_sprinting:
        stamina = maxf(0.0, stamina - stamina_drain * delta)
    else:
        var regen_multiplier: float = 1.0
        if hunger < 30.0:
            regen_multiplier *= 0.65
        if thirst < 30.0:
            regen_multiplier *= 0.55
        if darkness_exposure >= 75.0:
            regen_multiplier *= 0.75
        stamina = minf(max_stamina, stamina + stamina_regen * regen_multiplier * delta)
    player.set("stamina", stamina)

    var condition_speed_multiplier: float = 1.0
    if hunger < 15.0 or thirst < 15.0:
        condition_speed_multiplier = 0.82

    var move_speed: float = float(player.get("move_speed"))
    var sprint_multiplier: float = float(player.get("sprint_multiplier"))
    var acceleration: float = float(player.get("acceleration"))
    var current_speed: float = move_speed * condition_speed_multiplier
    if is_sprinting:
        current_speed *= sprint_multiplier

    var direction: Vector3 = (player.transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
    var target_x: float = direction.x * current_speed
    var target_z: float = direction.z * current_speed
    player.velocity.x = move_toward(player.velocity.x, target_x, acceleration * delta)
    player.velocity.z = move_toward(player.velocity.z, target_z, acceleration * delta)

    if grounded_before_move and not jumped_this_frame and direction.length_squared() > 0.01:
        _try_step_up(player, direction, current_speed, delta)

    player.move_and_slide()
    if player.has_method("_update_footsteps"):
        player.call("_update_footsteps", delta)
    if player.has_method("_update_interaction_hint"):
        player.call("_update_interaction_hint")

func _movement_allowed(player: CharacterBody3D) -> bool:
    if bool(player.get("is_dead")):
        return false

    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition != null and bool(transition.get("transitioning")):
        return false

    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return false

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null and bool(coop.get("local_downed")):
        return false

    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online:
        var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
        if polish != null and not bool(polish.get("session_started")):
            return false

    return true

func _try_step_up(player: CharacterBody3D, direction: Vector3, horizontal_speed: float, delta: float) -> bool:
    var allowed_step: float = _effective_step_height(player)
    if allowed_step <= 0.05 or horizontal_speed <= 0.05:
        return false

    var probe_distance: float = clampf(horizontal_speed * delta * step_probe_multiplier, 0.08, 0.30)
    var probe_motion: Vector3 = direction.normalized() * probe_distance
    if not player.test_move(player.global_transform, probe_motion):
        return false

    var up_motion: Vector3 = Vector3.UP * allowed_step
    if player.test_move(player.global_transform, up_motion):
        return false

    var raised_transform: Transform3D = player.global_transform.translated(up_motion)
    if player.test_move(raised_transform, probe_motion):
        return false

    var current_hit: Dictionary = _floor_hit(player, player.global_position, player.global_position.y + 0.22, player.global_position.y - 1.55)
    if current_hit.is_empty():
        return false

    var future_position: Vector3 = player.global_position + probe_motion
    var future_hit: Dictionary = _floor_hit(
        player,
        future_position,
        player.global_position.y + allowed_step + 0.32,
        player.global_position.y - 1.20
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
    if player.test_move(player.global_transform, lift):
        return false

    player.global_position += lift
    player.velocity.y = maxf(0.0, player.velocity.y)
    return true

func _effective_step_height(player: CharacterBody3D) -> float:
    var allowed: float = max_step_height
    var collision: CollisionShape3D = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null and collision.shape is CapsuleShape3D:
        var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
        var half_player_height: float = capsule.height * 0.5
        allowed = minf(allowed, maxf(0.0, half_player_height - 0.05))
    return allowed

func _floor_hit(player: CharacterBody3D, horizontal_position: Vector3, top_y: float, bottom_y: float) -> Dictionary:
    var world: World3D = player.get_world_3d()
    if world == null:
        return {}
    var start: Vector3 = Vector3(horizontal_position.x, top_y, horizontal_position.z)
    var finish: Vector3 = Vector3(horizontal_position.x, bottom_y, horizontal_position.z)
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, finish)
    var excludes: Array[RID] = [player.get_rid()]
    query.exclude = excludes
    query.collide_with_areas = false
    query.collide_with_bodies = true
    return world.direct_space_state.intersect_ray(query)
