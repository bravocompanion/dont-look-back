extends "res://scripts/shelter_system_ranger_v6.gd"

func sleep_until_morning(player: CharacterBody3D) -> bool:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return false

    var start_minutes: float = float(outside.get("game_minutes"))
    var start_day: int = int(outside.get("day_index"))
    var full_day_seconds: float = maxf(60.0, float(outside.get("full_day_seconds")))
    var simulated_seconds: float = _sleep_duration_seconds_v54(start_minutes, full_day_seconds)

    var resource_multiplier: float = maxf(1.0, sleep_resource_draw_multiplier_v54)
    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    var tower_extra_draw: float = 0.0
    if generator_running and radiation != null and radiation.has_method("is_tower_built") and bool(radiation.call("is_tower_built")):
        tower_extra_draw = 0.35
    var generator_draw_rate: float = resource_multiplier * (1.0 + tower_extra_draw)
    var generator_sim_available: float = generator_fuel_seconds / generator_draw_rate if generator_running and generator_fuel_seconds > 0.0 else 0.0
    var generator_sim_used: float = minf(simulated_seconds, generator_sim_available)

    var success: bool = super.sleep_until_morning(player)
    if not success:
        return false

    if _network_online_v54() and _is_host_v54() and simulated_seconds > 0.001:
        var final_day: int = start_day + 1 if start_minutes >= 1080.0 else start_day
        _apply_shared_sleep_cost_v54_remote.rpc(
            start_minutes,
            start_day,
            final_day,
            full_day_seconds,
            simulated_seconds,
            generator_sim_used
        )
    return true

@rpc("authority", "call_remote", "reliable", 45)
func _apply_shared_sleep_cost_v54_remote(
    start_minutes: float,
    start_day: int,
    final_day: int,
    full_day_seconds: float,
    simulated_seconds: float,
    generator_sim_used: float
) -> void:
    var player: CharacterBody3D = _local_sleep_player_v54()
    if player == null or bool(player.get("is_dead")):
        return

    var safe_generator_seconds: float = clampf(generator_sim_used, 0.0, simulated_seconds)
    _simulate_radiation_timeline_v54(
        player,
        start_minutes,
        start_day,
        full_day_seconds,
        safe_generator_seconds,
        true
    )

    var minutes_per_second: float = 1440.0 / maxf(60.0, full_day_seconds)
    var after_generator_minutes: float = start_minutes + safe_generator_seconds * minutes_per_second
    var after_generator_day: int = start_day
    while after_generator_minutes >= 1440.0:
        after_generator_minutes -= 1440.0
        after_generator_day += 1

    var fire_only_seconds: float = maxf(0.0, simulated_seconds - safe_generator_seconds)
    _simulate_radiation_timeline_v54(
        player,
        after_generator_minutes,
        after_generator_day,
        full_day_seconds,
        fire_only_seconds,
        false
    )

    var metabolic_cost: Vector2 = _sleep_metabolic_cost_v54(
        start_minutes,
        start_day,
        full_day_seconds,
        simulated_seconds
    )
    player.set("hunger", maxf(0.0, float(player.get("hunger")) - metabolic_cost.x))
    player.set("thirst", maxf(0.0, float(player.get("thirst")) - metabolic_cost.y))
    player.set("stamina", float(player.get("max_stamina")))
    player.set("darkness_exposure", 0.0)

    if float(player.get("hunger")) > 20.0 and float(player.get("thirst")) > 20.0 and not bool(player.get("is_dead")):
        if player.has_method("heal"):
            player.call("heal", 10.0)

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        outside.set("game_minutes", 420.0)
        outside.set("day_index", final_day)
        outside.set("cold_exposure", 0.0)

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null and not bool(player.get("is_dead")):
        objective.text = "The team survived the night. Shared sleep advanced your hunger, thirst, and radiation exposure."

func _sleep_duration_seconds_v54(start_minutes: float, full_day_seconds: float) -> float:
    var sleep_hours: float = 0.0
    if start_minutes >= 1080.0:
        sleep_hours = (1440.0 - start_minutes + 420.0) / 60.0
    elif start_minutes < 300.0:
        sleep_hours = (420.0 - start_minutes) / 60.0
    return maxf(0.0, sleep_hours * full_day_seconds / 24.0)

func _local_sleep_player_v54() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
    for node: Node in get_tree().get_nodes_in_group("player"):
        var candidate: CharacterBody3D = node as CharacterBody3D
        if candidate == null:
            continue
        if fallback == null:
            fallback = candidate
        var camera: Camera3D = candidate.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return candidate
    return fallback

func _network_online_v54() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host_v54() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))
