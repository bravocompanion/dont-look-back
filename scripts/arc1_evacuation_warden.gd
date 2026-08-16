extends "res://scripts/arc1_warden.gd"

func _process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    pulse_time += delta

    var evacuation: Node = get_node_or_null("/root/LabyrinthEvacuationSystem")
    var should_be_active: bool = evacuation != null and evacuation.has_method("is_escape_active") and bool(evacuation.call("is_escape_active"))
    var major: Node = get_node_or_null("/root/LabyrinthMajorSystem")

    if _is_authoritative():
        var became_active: bool = should_be_active and not active
        active = should_be_active
        if became_active:
            global_position = home_position
            attack_timer = 0.85
        visible = active
        if active:
            if major != null:
                _drive_authoritative(delta, major)
            else:
                var target: Dictionary = _select_target()
                if not target.is_empty():
                    var target_value: Variant = target.get("position", null)
                    if target_value is Vector3:
                        var target_position: Vector3 = target_value
                        _move_toward_goal(target_position, move_speed, delta)
        _broadcast_state(delta)
    else:
        active = remote_active
        visible = remote_active
        if remote_has_state and remote_active:
            global_position = global_position.lerp(remote_position, clampf(delta * 11.0, 0.0, 1.0))
            rotation.y = lerp_angle(rotation.y, remote_yaw, clampf(delta * 9.0, 0.0, 1.0))

    _update_pulse()
