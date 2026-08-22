extends "res://scripts/wildlife_animal_v50.gd"

# v0.51: after the 3 second +20% wounded flee burst, passive wildlife returns
# to its true base movement speed. The legacy parent AI used an additional 1.48x
# Deer / 1.70x Rabbit proximity flee multiplier, which made them faster after the
# wound timer ended than during the intended wounded response.
func _physics_process(delta: float) -> void:
    if remote_controlled or not alive:
        velocity = Vector3.ZERO
        return

    # v0.50 owns the short wounded response: exactly +20% speed for 3 seconds.
    if wounded_seconds > 0.0:
        super._physics_process(delta)
        return

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO
        _pick_wander_target()

    attack_timer = maxf(0.0, attack_timer - delta)
    retarget_timer -= delta

    var nearest: CharacterBody3D = _nearest_player()
    var goal: Vector3 = wander_target
    var speed: float = move_speed

    if nearest != null:
        var offset: Vector3 = nearest.global_position - global_position
        offset.y = 0.0
        var distance: float = offset.length()
        var hostile: bool = animal_kind == "wolf" or animal_kind == "boar"

        if hostile and distance <= alert_radius:
            goal = nearest.global_position
            speed *= 1.18 if animal_kind == "wolf" else 1.28
            if distance <= attack_distance and attack_timer <= 0.0:
                _attack_player(nearest)
        elif not hostile and distance <= alert_radius:
            # Deer/Rabbit still flee from a nearby survivor, but at their real
            # species base move_speed. No hidden post-wound speed multiplier.
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

    var direction: Vector3 = goal - global_position
    direction.y = 0.0
    if direction.length() > 0.22:
        direction = direction.normalized()
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), clampf(delta * 7.0, 0.0, 1.0))
    else:
        velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 6.0 * delta)

    move_and_slide()
    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO
