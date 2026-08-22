extends "res://scripts/wildlife_animal_v53.gd"

# v0.64 wounded-flee stability.
# Repeat hits refresh the wound window but never stack speed. Heading changes are
# rate-limited, and collision avoidance chooses a stable tangent for a short lock
# instead of re-solving left/right every frame.
@export var wounded_heading_turn_rate_degrees_v64: float = 145.0
@export var wounded_body_turn_rate_degrees_v64: float = 180.0
@export var repeat_hit_heading_lock_seconds_v64: float = 0.32
@export var obstacle_heading_lock_seconds_v64: float = 0.34
@export var wounded_acceleration_v64: float = 7.5

var flee_heading_v64: Vector3 = Vector3.ZERO
var flee_avoidance_heading_v64: Vector3 = Vector3.ZERO
var flee_repeat_hit_lock_v64: float = 0.0
var flee_obstacle_lock_v64: float = 0.0

func configure(id_value: String, kind_value: String, spawn_position: Vector3, is_remote: bool) -> void:
    super.configure(id_value, kind_value, spawn_position, is_remote)
    _reset_flee_stability_v64()

func reset_animal(spawn_position: Vector3) -> void:
    super.reset_animal(spawn_position)
    _reset_flee_stability_v64()

func take_hunting_damage(amount: float, hunter_peer_id: int) -> void:
    if not alive or remote_controlled:
        return

    var was_wounded: bool = wounded_seconds > 0.0
    var previous_heading: Vector3 = flee_heading_v64
    if previous_heading.length_squared() <= 0.0025:
        previous_heading = flee_escape_direction_v52
    if previous_heading.length_squared() > 0.0025:
        previous_heading = previous_heading.normalized()

    super.take_hunting_damage(amount, hunter_peer_id)

    if not alive:
        _reset_flee_stability_v64()
        return

    var away_now: Vector3 = _hunter_away_direction_v64()
    if was_wounded and previous_heading.length_squared() > 0.0025:
        # A second non-lethal hit may refresh the flee timer, but it cannot snap
        # the animal into an instant opposite heading. The target will be blended
        # toward the new hunter-away vector after this short lock.
        flee_heading_v64 = previous_heading
        flee_repeat_hit_lock_v64 = repeat_hit_heading_lock_seconds_v64
    elif away_now.length_squared() > 0.0025:
        flee_heading_v64 = away_now
    elif flee_escape_direction_v52.length_squared() > 0.0025:
        flee_heading_v64 = flee_escape_direction_v52.normalized()
    else:
        flee_heading_v64 = Vector3(0.0, 0.0, -1.0)

    flee_escape_direction_v52 = flee_heading_v64
    flee_obstacle_lock_v64 = 0.0
    flee_avoidance_heading_v64 = Vector3.ZERO

# Overrides the v0.53 wounded step invoked by its _physics_process().
func _update_wounded_flee_v53(delta: float) -> void:
    flee_repeat_hit_lock_v64 = maxf(0.0, flee_repeat_hit_lock_v64 - delta)
    flee_obstacle_lock_v64 = maxf(0.0, flee_obstacle_lock_v64 - delta)

    var away_direction: Vector3 = _hunter_away_direction_v64()
    if away_direction.length_squared() <= 0.0025:
        away_direction = flee_escape_direction_v52
    if away_direction.length_squared() <= 0.0025:
        away_direction = Vector3(0.0, 0.0, -1.0)
    else:
        away_direction = away_direction.normalized()

    if flee_heading_v64.length_squared() <= 0.0025:
        flee_heading_v64 = away_direction
    else:
        flee_heading_v64 = flee_heading_v64.normalized()

    var target_heading: Vector3 = away_direction
    if flee_obstacle_lock_v64 > 0.0 and flee_avoidance_heading_v64.length_squared() > 0.0025:
        target_heading = flee_avoidance_heading_v64.normalized()
    elif flee_repeat_hit_lock_v64 > 0.0:
        target_heading = flee_heading_v64

    flee_heading_v64 = _turn_heading_toward_v64(
        flee_heading_v64,
        target_heading,
        deg_to_rad(wounded_heading_turn_rate_degrees_v64) * maxf(0.0, delta)
    )
    flee_escape_direction_v52 = flee_heading_v64

    var flee_speed: float = minf(move_speed * wounded_flee_speed_multiplier, _movement_speed_cap_v53())
    var target_velocity: Vector3 = flee_heading_v64 * flee_speed
    velocity.x = move_toward(velocity.x, target_velocity.x, wounded_acceleration_v64 * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, wounded_acceleration_v64 * delta)
    _clamp_horizontal_velocity_v53()

    _turn_body_toward_heading_v64(flee_heading_v64, delta)
    move_and_slide()
    _clamp_horizontal_velocity_v53()

    var avoidance: Vector3 = _best_collision_tangent_v64(away_direction, flee_heading_v64)
    if avoidance.length_squared() > 0.0025:
        flee_avoidance_heading_v64 = avoidance
        flee_obstacle_lock_v64 = obstacle_heading_lock_seconds_v64

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO

func _hunter_away_direction_v64() -> Vector3:
    var threat_value: Variant = _hunter_position(flee_hunter_peer_id)
    if not (threat_value is Vector3):
        return Vector3.ZERO
    var away: Vector3 = global_position - Vector3(threat_value)
    away.y = 0.0
    if away.length_squared() <= 0.0025:
        return Vector3.ZERO
    return away.normalized()

func _turn_heading_toward_v64(current: Vector3, target: Vector3, max_angle: float) -> Vector3:
    var current_flat: Vector3 = Vector3(current.x, 0.0, current.z)
    var target_flat: Vector3 = Vector3(target.x, 0.0, target.z)
    if current_flat.length_squared() <= 0.0025:
        return target_flat.normalized() if target_flat.length_squared() > 0.0025 else Vector3(0.0, 0.0, -1.0)
    if target_flat.length_squared() <= 0.0025:
        return current_flat.normalized()

    current_flat = current_flat.normalized()
    target_flat = target_flat.normalized()
    var current_yaw: float = atan2(-current_flat.x, -current_flat.z)
    var target_yaw: float = atan2(-target_flat.x, -target_flat.z)
    var yaw_error: float = wrapf(target_yaw - current_yaw, -PI, PI)
    var next_yaw: float = current_yaw + clampf(yaw_error, -max_angle, max_angle)
    return Vector3(-sin(next_yaw), 0.0, -cos(next_yaw)).normalized()

func _turn_body_toward_heading_v64(heading: Vector3, delta: float) -> void:
    if heading.length_squared() <= 0.0025:
        return
    var target_yaw: float = atan2(-heading.x, -heading.z)
    var yaw_error: float = wrapf(target_yaw - rotation.y, -PI, PI)
    var max_step: float = deg_to_rad(wounded_body_turn_rate_degrees_v64) * maxf(0.0, delta)
    rotation.y = wrapf(rotation.y + clampf(yaw_error, -max_step, max_step), -PI, PI)

func _best_collision_tangent_v64(away_direction: Vector3, current_heading: Vector3) -> Vector3:
    var collision_count: int = get_slide_collision_count()
    if collision_count <= 0:
        return Vector3.ZERO

    var away: Vector3 = away_direction.normalized() if away_direction.length_squared() > 0.0025 else current_heading.normalized()
    var current: Vector3 = current_heading.normalized() if current_heading.length_squared() > 0.0025 else away
    var best_heading: Vector3 = Vector3.ZERO
    var best_score: float = -INF

    for index: int in range(collision_count):
        var collision: KinematicCollision3D = get_slide_collision(index)
        if collision == null:
            continue
        var normal: Vector3 = collision.get_normal()
        normal.y = 0.0
        if normal.length_squared() <= 0.01:
            continue
        normal = normal.normalized()
        var tangent_a: Vector3 = Vector3(-normal.z, 0.0, normal.x).normalized()
        var tangent_b: Vector3 = -tangent_a
        for candidate: Vector3 in [tangent_a, tangent_b]:
            var score: float = candidate.dot(away) * 0.72 + candidate.dot(current) * 0.28
            if score > best_score:
                best_score = score
                best_heading = candidate

    # Refuse an avoidance direction that meaningfully drives back toward the hunter.
    if best_heading.length_squared() <= 0.0025 or best_heading.dot(away) < -0.15:
        return Vector3.ZERO
    return best_heading.normalized()

func _reset_flee_stability_v64() -> void:
    flee_heading_v64 = Vector3.ZERO
    flee_avoidance_heading_v64 = Vector3.ZERO
    flee_repeat_hit_lock_v64 = 0.0
    flee_obstacle_lock_v64 = 0.0

func get_flee_stability_contract_v64() -> Dictionary:
    return {
        "repeat_hit_speed_stacks": false,
        "wounded_speed_multiplier": wounded_flee_speed_multiplier,
        "speed_cap": _movement_speed_cap_v53(),
        "heading_turn_rate_degrees": wounded_heading_turn_rate_degrees_v64,
        "body_turn_rate_degrees": wounded_body_turn_rate_degrees_v64,
        "repeat_hit_heading_lock_seconds": repeat_hit_heading_lock_seconds_v64,
        "obstacle_heading_lock_seconds": obstacle_heading_lock_seconds_v64
    }
