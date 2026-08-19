extends "res://scripts/night_threat_system.gd"

func _process(delta: float) -> void:
    super._process(delta)
    _apply_day_escalation()

func _apply_day_escalation() -> void:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var day_index: int = int(outside.get("day_index")) if outside != null else 1

    var threshold_adjust: float = 0.0
    var cooldown_multiplier: float = 1.0
    var speed_multiplier: float = 1.0
    var damage_multiplier: float = 1.0

    if day_index <= 1:
        threshold_adjust = 8.0
        cooldown_multiplier = 1.28
        speed_multiplier = 0.90
        damage_multiplier = 0.88
    elif day_index == 2:
        threshold_adjust = 2.0
        cooldown_multiplier = 1.08
        speed_multiplier = 0.97
        damage_multiplier = 0.96
    elif day_index == 3:
        threshold_adjust = -4.0
        cooldown_multiplier = 0.88
        speed_multiplier = 1.08
        damage_multiplier = 1.10
    elif day_index == 4:
        threshold_adjust = -7.0
        cooldown_multiplier = 0.80
        speed_multiplier = 1.12
        damage_multiplier = 1.15
    else:
        threshold_adjust = -10.0
        cooldown_multiplier = 0.72
        speed_multiplier = 1.18
        damage_multiplier = 1.22

    var darkness: Node = get_node_or_null("/root/DarknessDirector")
    if darkness != null:
        darkness.set("spawn_threshold", clampf(float(darkness.get("spawn_threshold")) + threshold_adjust, 34.0, 88.0))
        darkness.set("spawn_cooldown_seconds", maxf(3.5, float(darkness.get("spawn_cooldown_seconds")) * cooldown_multiplier))

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        coop.set("dark_spawn_threshold", clampf(float(coop.get("dark_spawn_threshold")) + threshold_adjust, 34.0, 88.0))
        coop.set("dark_move_speed", float(coop.get("dark_move_speed")) * speed_multiplier)
        coop.set("dark_attack_damage", float(coop.get("dark_attack_damage")) * damage_multiplier)

    if not _network_online():
        var creature: Node = get_tree().get_first_node_in_group("darkness_creature")
        if creature != null:
            creature.set("move_speed", float(creature.get("move_speed")) * speed_multiplier)
            creature.set("attack_damage", float(creature.get("attack_damage")) * damage_multiplier)

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))
