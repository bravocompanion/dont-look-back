extends "res://scripts/wildlife_animal_v48.gd"

# v0.49: lethal arrow hits keep the wildlife body visible as a corpse until the
# existing respawn/reset cycle revives the animal. Collision is disabled so the
# corpse cannot block movement or absorb later projectile raycasts.

func take_hunting_damage(amount: float, hunter_peer_id: int) -> void:
    if not alive or remote_controlled:
        return

    var applied_damage: float = maxf(0.0, amount)
    if current_health - applied_damage > 0.0:
        super.take_hunting_damage(applied_damage, hunter_peer_id)
        return

    current_health = 0.0
    alive = false
    visible = true
    velocity = Vector3.ZERO
    wounded_seconds = 0.0
    blood_mark_timer = 0.0
    _set_collision_enabled(false)

    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system != null and system.has_method("on_animal_killed"):
        system.call("on_animal_killed", animal_id, animal_kind, hunter_peer_id, global_position)

func apply_remote_state(position_value: Vector3, yaw: float, alive_value: bool, health_value: float) -> void:
    remote_position = _safe_adjust_position(position_value)
    remote_yaw = yaw
    current_health = health_value

    if alive_value:
        if not alive:
            alive = true
            visible = true
            _set_collision_enabled(true)
        return

    alive = false
    visible = true
    velocity = Vector3.ZERO
    _set_collision_enabled(false)

func reset_animal(spawn_position: Vector3) -> void:
    super.reset_animal(spawn_position)
    visible = true
    _set_collision_enabled(true)
