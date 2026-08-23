extends "res://scripts/movement_system_v41.gd"

# v0.67 applies carry-weight penalties without duplicating the core locomotion
# controller. Player movement properties are temporarily adjusted for one
# physics tick, then restored so other systems continue to see canonical base
# tuning values.

func _physics_process(delta: float) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        super._physics_process(delta)
        return

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry == null or not carry.has_method("get_movement_penalties_v67"):
        super._physics_process(delta)
        return

    var penalties: Dictionary = Dictionary(carry.call("get_movement_penalties_v67", player))
    var speed_multiplier: float = clampf(float(penalties.get("speed_multiplier", 1.0)), 0.1, 1.0)
    var drain_multiplier: float = maxf(0.0, float(penalties.get("sprint_drain_multiplier", 1.0)))
    var regen_multiplier: float = maxf(0.0, float(penalties.get("stamina_regen_multiplier", 1.0)))
    var sprint_allowed: bool = bool(penalties.get("sprint_allowed", true))

    var base_move_speed: float = float(player.get("move_speed"))
    var base_stamina_drain: float = float(player.get("stamina_drain_per_second"))
    var base_stamina_regen: float = float(player.get("stamina_regen_per_second"))
    var stamina_before: float = float(player.get("stamina"))

    player.set("move_speed", base_move_speed * speed_multiplier)
    player.set("stamina_drain_per_second", base_stamina_drain * drain_multiplier)
    player.set("stamina_regen_per_second", base_stamina_regen * regen_multiplier)

    # The inherited controller decides sprint eligibility from stamina. A zero
    # temporary value cleanly suppresses sprint while overweight without adding
    # a second input path. The real stamina value is restored after the tick.
    if not sprint_allowed:
        player.set("stamina", 0.0)

    super._physics_process(delta)

    if not sprint_allowed:
        player.set("stamina", stamina_before)
        player.set("is_sprinting", false)

    player.set("move_speed", base_move_speed)
    player.set("stamina_drain_per_second", base_stamina_drain)
    player.set("stamina_regen_per_second", base_stamina_regen)

func get_weight_movement_contract_v67() -> Dictionary:
    return {
        "loaded_speed_multiplier": 1.0,
        "loaded_sprint_drain_multiplier": 1.15,
        "loaded_stamina_regen_multiplier": 0.90,
        "heavy_speed_multiplier": 0.92,
        "heavy_sprint_drain_multiplier": 1.35,
        "heavy_stamina_regen_multiplier": 0.75,
        "overweight_speed_multiplier": 0.78,
        "overweight_sprint_allowed": false
    }
