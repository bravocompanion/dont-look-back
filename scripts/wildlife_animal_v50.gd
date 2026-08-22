extends "res://scripts/wildlife_animal_v49.gd"

# v0.50: wounded wildlife gets only a short, controlled flee burst.
# Every non-lethal arrow hit refreshes a 3 second flee window at +20% move speed.
@export var wounded_flee_duration_seconds: float = 3.0
@export var wounded_flee_speed_multiplier: float = 1.20

func take_hunting_damage(amount: float, hunter_peer_id: int) -> void:
    super.take_hunting_damage(amount, hunter_peer_id)
    if alive and not remote_controlled:
        wounded_seconds = wounded_flee_duration_seconds

func _physics_process(delta: float) -> void:
    if remote_controlled or not alive:
        velocity = Vector3.ZERO
        return

    # After the short wound response, restore the normal species AI immediately.
    if wounded_seconds <= 0.0:
        super._physics_process(delta)
        return

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO

    attack_timer = maxf(0.0, attack_timer - delta)
    retarget_timer = maxf(0.0, retarget_timer - delta)
    _update_wound_trail(delta)

    var refreshed_threat: Variant = _hunter_position(flee_hunter_peer_id)
    if refreshed_threat is Vector3:
        flee_threat_position = refreshed_threat
        flee_threat_valid = true

    var away_direction: Vector3 = flee_last_direction
    var threat_distance: float = flee_last_distance
    if flee_threat_valid:
        var away_offset: Vector3 = global_position - flee_threat_position
        away_offset.y = 0.0
        threat_distance = away_offset.length()
        if threat_distance > 0.05:
            away_direction = away_offset / threat_distance
            flee_last_direction = away_direction

    if away_direction.length_squared() <= 0.0025:
        away_direction = Vector3(0.0, 0.0, -1.0)

    # Keep the anti-orbit steering from v0.48, but remove the very large
    # species-specific flee speed bonuses. The direct-away component dominates.
    var lateral: Vector3 = Vector3(-away_direction.z, 0.0, away_direction.x) * flee_side_sign
    var desired_direction: Vector3 = (away_direction * 0.96 + lateral * 0.12).normalized()
    if desired_direction.dot(away_direction) < 0.88:
        desired_direction = away_direction

    if flee_last_distance >= 0.0 and threat_distance >= 0.0 and threat_distance + 0.04 < flee_last_distance:
        desired_direction = away_direction
        flee_side_sign *= -1.0

    var flee_speed: float = move_speed * wounded_flee_speed_multiplier
    velocity.x = move_toward(velocity.x, desired_direction.x * flee_speed, 12.0 * delta)
    velocity.z = move_toward(velocity.z, desired_direction.z * flee_speed, 12.0 * delta)
    rotation.y = lerp_angle(
        rotation.y,
        atan2(-desired_direction.x, -desired_direction.z),
        clampf(delta * 8.5, 0.0, 1.0)
    )

    move_and_slide()

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO

    if flee_threat_valid:
        var post_offset: Vector3 = global_position - flee_threat_position
        post_offset.y = 0.0
        flee_last_distance = post_offset.length()
    else:
        flee_last_distance = -1.0
