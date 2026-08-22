extends "res://scripts/wildlife_animal_v51.gd"

const CORPSE_INTERACT_SCRIPT_V52: String = "res://scripts/wildlife_corpse_interactable_v52.gd"

# v0.52:
# - wounded flee is straight-away steering with a hard 1.20x speed cap
# - no lateral orbit term while wounded
# - dead animals fall onto their side instead of remaining upright
# - dead-body collision remains non-blocking while a separate Area3D handles harvest

var flee_escape_direction_v52: Vector3 = Vector3.ZERO
var corpse_collected_v52: bool = false
var corpse_interaction_v52: Area3D

func _finish_setup() -> void:
    super._finish_setup()
    _ensure_corpse_interaction_v52()
    _set_corpse_interaction_enabled_v52(false)

func configure(id_value: String, kind_value: String, spawn_position: Vector3, is_remote: bool) -> void:
    super.configure(id_value, kind_value, spawn_position, is_remote)
    corpse_collected_v52 = false
    flee_escape_direction_v52 = Vector3.ZERO

func take_hunting_damage(amount: float, hunter_peer_id: int) -> void:
    if not alive or remote_controlled:
        return

    var was_alive: bool = alive
    super.take_hunting_damage(amount, hunter_peer_id)

    if was_alive and not alive:
        corpse_collected_v52 = false
        flee_escape_direction_v52 = Vector3.ZERO
        _enter_corpse_pose_v52()
        return

    if alive:
        var threat_value: Variant = _hunter_position(hunter_peer_id)
        if threat_value is Vector3:
            var threat_position: Vector3 = threat_value
            var away: Vector3 = global_position - threat_position
            away.y = 0.0
            if away.length_squared() > 0.0025:
                flee_escape_direction_v52 = away.normalized()
        if flee_escape_direction_v52.length_squared() <= 0.0025:
            flee_escape_direction_v52 = flee_last_direction.normalized()

func _physics_process(delta: float) -> void:
    if remote_controlled or not alive:
        velocity = Vector3.ZERO
        return

    if wounded_seconds <= 0.0:
        super._physics_process(delta)
        return

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO

    attack_timer = maxf(0.0, attack_timer - delta)
    retarget_timer = maxf(0.0, retarget_timer - delta)
    _update_wound_trail(delta)

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

    # Exact requested wounded speed: +20%, no hidden species multiplier.
    var flee_speed: float = move_speed * wounded_flee_speed_multiplier
    var target_velocity: Vector3 = away_direction * flee_speed
    velocity.x = move_toward(velocity.x, target_velocity.x, 9.0 * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, 9.0 * delta)

    var horizontal_velocity: Vector2 = Vector2(velocity.x, velocity.z)
    if horizontal_velocity.length() > flee_speed:
        horizontal_velocity = horizontal_velocity.normalized() * flee_speed
        velocity.x = horizontal_velocity.x
        velocity.z = horizontal_velocity.y

    rotation.y = lerp_angle(
        rotation.y,
        atan2(-away_direction.x, -away_direction.z),
        clampf(delta * 5.0, 0.0, 1.0)
    )

    move_and_slide()

    # A collision slide must never turn wounded flee into an orbit around the
    # shooter. If distance shrank, force the next velocity directly outward.
    if has_threat and threat_distance_before >= 0.0:
        var post_offset: Vector3 = global_position - threat_position
        post_offset.y = 0.0
        var post_distance: float = post_offset.length()
        if post_distance + 0.02 < threat_distance_before and post_distance > 0.05:
            flee_escape_direction_v52 = post_offset.normalized()
            velocity.x = flee_escape_direction_v52.x * flee_speed
            velocity.z = flee_escape_direction_v52.z * flee_speed

    if _position_in_safe_zone(global_position):
        global_position = _safe_adjust_position(global_position)
        velocity = Vector3.ZERO

func apply_remote_state(position_value: Vector3, yaw: float, alive_value: bool, health_value: float) -> void:
    super.apply_remote_state(position_value, yaw, alive_value, health_value)
    if alive_value:
        corpse_collected_v52 = false
        rotation.x = 0.0
        rotation.z = 0.0
        _set_corpse_interaction_enabled_v52(false)
        return

    rotation.y = yaw
    if corpse_collected_v52:
        visible = false
        _set_corpse_interaction_enabled_v52(false)
    else:
        _enter_corpse_pose_v52()

func reset_animal(spawn_position: Vector3) -> void:
    corpse_collected_v52 = false
    flee_escape_direction_v52 = Vector3.ZERO
    rotation.x = 0.0
    rotation.z = 0.0
    super.reset_animal(spawn_position)
    _set_corpse_interaction_enabled_v52(false)

func is_corpse_collectible_v52() -> bool:
    return not alive and not corpse_collected_v52 and visible

func get_corpse_interaction_text_v52() -> String:
    if not is_corpse_collectible_v52():
        return ""
    return "Harvest %s carcass" % animal_kind.capitalize()

func request_corpse_collect_v52() -> void:
    if not is_corpse_collectible_v52():
        return
    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system != null and system.has_method("request_corpse_harvest_v52"):
        system.call("request_corpse_harvest_v52", animal_id)

func set_corpse_collected_v52(collected: bool) -> void:
    corpse_collected_v52 = collected
    if alive:
        visible = true
        _set_corpse_interaction_enabled_v52(false)
        return
    visible = not collected
    _set_corpse_interaction_enabled_v52(not collected)

func _enter_corpse_pose_v52() -> void:
    visible = not corpse_collected_v52
    velocity = Vector3.ZERO
    _set_collision_enabled(false)

    # Prototype corpse pose: deterministic left/right fall so every peer sees
    # the same orientation. A production death animation can replace this later.
    var fall_sign: float = -1.0 if (abs(hash(animal_id)) % 2) == 0 else 1.0
    rotation.x = 0.0
    rotation.z = deg_to_rad(90.0 * fall_sign)
    _ensure_corpse_interaction_v52()
    _set_corpse_interaction_enabled_v52(not corpse_collected_v52)

func _ensure_corpse_interaction_v52() -> void:
    if corpse_interaction_v52 != null and is_instance_valid(corpse_interaction_v52):
        return

    corpse_interaction_v52 = get_node_or_null("CorpseInteractionV52") as Area3D
    if corpse_interaction_v52 != null:
        return

    var interact_script: Script = load(CORPSE_INTERACT_SCRIPT_V52) as Script
    if interact_script == null:
        return

    corpse_interaction_v52 = Area3D.new()
    corpse_interaction_v52.name = "CorpseInteractionV52"
    corpse_interaction_v52.set_script(interact_script)
    corpse_interaction_v52.collision_layer = 0
    corpse_interaction_v52.collision_mask = 0
    corpse_interaction_v52.monitoring = false
    corpse_interaction_v52.monitorable = true
    add_child(corpse_interaction_v52)

    var shape_node: CollisionShape3D = CollisionShape3D.new()
    shape_node.name = "CollisionShape3D"
    var shape: SphereShape3D = SphereShape3D.new()
    match animal_kind:
        "rabbit": shape.radius = 0.62
        "deer": shape.radius = 1.05
        _: shape.radius = 0.92
    shape_node.shape = shape
    corpse_interaction_v52.add_child(shape_node)

func _set_corpse_interaction_enabled_v52(enabled: bool) -> void:
    _ensure_corpse_interaction_v52()
    if corpse_interaction_v52 == null:
        return
    # Layer switching is deferred so a lethal arrow impact cannot modify query
    # participation while the physics server is still flushing the hit.
    corpse_interaction_v52.set_deferred("collision_layer", 1 if enabled else 0)
