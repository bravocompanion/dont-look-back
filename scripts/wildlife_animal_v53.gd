extends "res://scripts/wildlife_animal_v52.gd"

# v0.53 hard movement caps. These limits apply to every authoritative AI state
# and to remote interpolation, so no inherited chase/flee multiplier or network
# correction can make an animal visually exceed its species cap.
@export var rabbit_speed_cap_v53: float = 3.36
@export var deer_speed_cap_v53: float = 2.64
@export var boar_speed_cap_v53: float = 3.00
@export var wolf_speed_cap_v53: float = 3.60

func _physics_process(delta: float) -> void:
    if remote_controlled or not alive:
        velocity = Vector3.ZERO
        return

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO
        _pick_wander_target()

    attack_timer = maxf(0.0, attack_timer - delta)
    retarget_timer -= delta

    # Wounded behavior stays exactly 3 seconds at +20%, but the final velocity
    # is still clamped by the same species hard cap.
    if wounded_seconds > 0.0:
        _update_wound_trail(delta)
        _update_wounded_flee_v53(delta)
        return

    var nearest: CharacterBody3D = _nearest_player()
    var goal: Vector3 = wander_target
    var desired_speed: float = move_speed

    if nearest != null:
        var offset: Vector3 = nearest.global_position - global_position
        offset.y = 0.0
        var distance: float = offset.length()
        var hostile: bool = animal_kind == "wolf" or animal_kind == "boar"

        if hostile and distance <= alert_radius:
            goal = nearest.global_position
            desired_speed *= 1.18 if animal_kind == "wolf" else 1.28
            if distance <= attack_distance and attack_timer <= 0.0:
                _attack_player(nearest)
        elif not hostile and distance <= alert_radius:
            var away: Vector3 = -offset.normalized() if distance > 0.05 else Vector3(1.0, 0.0, 0.0)
            goal = global_position + away * 13.0
        elif retarget_timer <= 0.0:
            _pick_wander_target()
            goal = wander_target
    elif retarget_timer <= 0.0:
        _pick_wander_target()
        goal = wander_target

    if _position_in_safe_zone(goal):
        goal = _safe_adjust_position(goal)

    desired_speed = minf(desired_speed, _movement_speed_cap_v53())
    var direction: Vector3 = goal - global_position
    direction.y = 0.0
    if direction.length() > 0.22:
        direction = direction.normalized()
        velocity.x = direction.x * desired_speed
        velocity.z = direction.z * desired_speed
        rotation.y = lerp_angle(
            rotation.y,
            atan2(-direction.x, -direction.z),
            clampf(delta * 7.0, 0.0, 1.0)
        )
    else:
        velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 6.0 * delta)

    _clamp_horizontal_velocity_v53()
    move_and_slide()
    _clamp_horizontal_velocity_v53()

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO

func _update_wounded_flee_v53(delta: float) -> void:
    var away_direction: Vector3 = flee_escape_direction_v52
    var threat_value: Variant = _hunter_position(flee_hunter_peer_id)
    var threat_position: Vector3 = Vector3.ZERO
    var has_threat: bool = threat_value is Vector3
    var threat_distance_before: float = -1.0

    if has_threat:
        threat_position = threat_value
        var away_now: Vector3 = global_position - threat_position
        away_now.y = 0.0
        threat_distance_before = away_now.length()
        if threat_distance_before > 0.05:
            away_now /= threat_distance_before
            if away_direction.length_squared() <= 0.0025 or away_direction.dot(away_now) < 0.82:
                away_direction = away_now

    if away_direction.length_squared() <= 0.0025:
        away_direction = Vector3(0.0, 0.0, -1.0)
    else:
        away_direction = away_direction.normalized()
    flee_escape_direction_v52 = away_direction

    var flee_speed: float = minf(move_speed * wounded_flee_speed_multiplier, _movement_speed_cap_v53())
    var target_velocity: Vector3 = away_direction * flee_speed
    velocity.x = move_toward(velocity.x, target_velocity.x, 9.0 * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, 9.0 * delta)
    _clamp_horizontal_velocity_v53()

    rotation.y = lerp_angle(
        rotation.y,
        atan2(-away_direction.x, -away_direction.z),
        clampf(delta * 5.0, 0.0, 1.0)
    )

    move_and_slide()
    _clamp_horizontal_velocity_v53()

    # If collision sliding moves the animal closer to the shooter, force the
    # next frame directly outward but still never above the hard cap.
    if has_threat and threat_distance_before >= 0.0:
        var post_offset: Vector3 = global_position - threat_position
        post_offset.y = 0.0
        var post_distance: float = post_offset.length()
        if post_distance + 0.02 < threat_distance_before and post_distance > 0.05:
            flee_escape_direction_v52 = post_offset.normalized()
            velocity.x = flee_escape_direction_v52.x * flee_speed
            velocity.z = flee_escape_direction_v52.z * flee_speed
            _clamp_horizontal_velocity_v53()

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO

func _process(delta: float) -> void:
    if not remote_controlled or not alive:
        return

    var safe_remote: Vector3 = _safe_adjust_position(remote_position)
    var horizontal_offset: Vector3 = safe_remote - global_position
    horizontal_offset.y = 0.0
    var horizontal_distance: float = horizontal_offset.length()
    var max_step: float = _movement_speed_cap_v53() * maxf(0.0, delta)

    if horizontal_distance > 0.001:
        var step_distance: float = minf(horizontal_distance, max_step)
        var horizontal_step: Vector3 = horizontal_offset / horizontal_distance * step_distance
        global_position.x += horizontal_step.x
        global_position.z += horizontal_step.z

    global_position.y = lerpf(global_position.y, safe_remote.y, clampf(delta * 10.0, 0.0, 1.0))
    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
    rotation.y = lerp_angle(rotation.y, remote_yaw, clampf(delta * 9.0, 0.0, 1.0))

func _movement_speed_cap_v53() -> float:
    match animal_kind:
        "rabbit":
            return maxf(0.1, rabbit_speed_cap_v53)
        "boar":
            return maxf(0.1, boar_speed_cap_v53)
        "wolf":
            return maxf(0.1, wolf_speed_cap_v53)
        _:
            return maxf(0.1, deer_speed_cap_v53)

func _clamp_horizontal_velocity_v53() -> void:
    var horizontal: Vector2 = Vector2(velocity.x, velocity.z)
    var speed_cap: float = _movement_speed_cap_v53()
    if horizontal.length() <= speed_cap:
        return
    horizontal = horizontal.normalized() * speed_cap
    velocity.x = horizontal.x
    velocity.z = horizontal.y
