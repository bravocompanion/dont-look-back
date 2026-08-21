extends "res://scripts/wildlife_animal_v45.gd"

# v0.48: an arrow hit forces every living wildlife target into a real flee state.
# The flee threat is the hunter who caused the wound, not whichever player happens
# to become nearest on the next frame. This prevents wounded animals from orbiting
# or circling around survivors after impact.

var flee_hunter_peer_id: int = 0
var flee_threat_position: Vector3 = Vector3.ZERO
var flee_threat_valid: bool = false
var flee_side_sign: float = 1.0
var flee_last_direction: Vector3 = Vector3(0.0, 0.0, -1.0)
var flee_last_distance: float = -1.0

func take_hunting_damage(amount: float, hunter_peer_id: int) -> void:
    if not alive or remote_controlled:
        return

    flee_hunter_peer_id = hunter_peer_id
    var threat_value: Variant = _hunter_position(hunter_peer_id)
    if threat_value is Vector3:
        flee_threat_position = threat_value
        flee_threat_valid = true
    else:
        var nearest: CharacterBody3D = _nearest_player()
        if nearest != null:
            flee_threat_position = nearest.global_position
            flee_threat_valid = true

    if flee_threat_valid:
        var away: Vector3 = global_position - flee_threat_position
        away.y = 0.0
        if away.length_squared() > 0.0025:
            flee_last_direction = away.normalized()
        flee_last_distance = away.length()

    flee_side_sign = -1.0 if (abs(hash("%s:%d" % [animal_id, hunter_peer_id])) % 2) == 0 else 1.0
    super.take_hunting_damage(amount, hunter_peer_id)

func _physics_process(delta: float) -> void:
    if remote_controlled or not alive:
        velocity = Vector3.ZERO
        return

    # Outside a wound response, retain the normal species behaviour from v0.45.
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

    # Small stable lateral bias helps slide around trees/rocks, but the direct-away
    # component dominates so steering cannot turn into a circular orbit.
    var lateral: Vector3 = Vector3(-away_direction.z, 0.0, away_direction.x) * flee_side_sign
    var desired_direction: Vector3 = (away_direction * 0.96 + lateral * 0.12).normalized()
    if desired_direction.dot(away_direction) < 0.88:
        desired_direction = away_direction

    var flee_speed_multiplier: float = 1.55
    match animal_kind:
        "rabbit": flee_speed_multiplier = 1.90
        "deer": flee_speed_multiplier = 1.62
        "wolf": flee_speed_multiplier = 1.58
        "boar": flee_speed_multiplier = 1.48
    var flee_speed: float = move_speed * flee_speed_multiplier

    # If the last movement reduced distance from the hunter, discard lateral bias
    # immediately and run directly away on the next step.
    if flee_last_distance >= 0.0 and threat_distance >= 0.0 and threat_distance + 0.04 < flee_last_distance:
        desired_direction = away_direction
        flee_side_sign *= -1.0

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

func reset_animal(spawn_position: Vector3) -> void:
    flee_hunter_peer_id = 0
    flee_threat_position = Vector3.ZERO
    flee_threat_valid = false
    flee_last_direction = Vector3(0.0, 0.0, -1.0)
    flee_last_distance = -1.0
    super.reset_animal(spawn_position)

func _hunter_position(peer_id: int) -> Variant:
    # Local/authority-owned player nodes first.
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null or bool(player.get("is_dead")):
            continue
        if peer_id <= 0 or player.get_multiplayer_authority() == peer_id:
            return player.global_position

    # On the host, remote survivor transforms are already tracked by NetworkManager.
    # Using that exact peer position keeps co-op wildlife fleeing from the shooter,
    # rather than accidentally choosing the host as its threat.
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        var targets_value: Variant = network.get("remote_targets")
        if targets_value is Dictionary:
            var targets: Dictionary = targets_value
            var peer_state_value: Variant = targets.get(peer_id, null)
            if peer_state_value is Dictionary:
                var peer_state: Dictionary = peer_state_value
                var transform_value: Variant = peer_state.get("transform", null)
                if transform_value is Transform3D:
                    var peer_transform: Transform3D = transform_value
                    return peer_transform.origin

    return null
