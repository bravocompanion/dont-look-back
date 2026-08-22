extends "res://scripts/radiation_survival_system_v41.gd"

# v0.54 time-skip hook used by shelter sleep. The caller supplies the day
# being simulated and whether the generator protects the ranger yard for this
# segment, so sleeping cannot bypass Day-3+ radiation.
func apply_sleep_exposure_v54(
    player: CharacterBody3D,
    simulated_seconds: float,
    simulated_day_index: int,
    generator_protected: bool
) -> void:
    if player == null or simulated_seconds <= 0.0:
        return

    var remaining: float = simulated_seconds
    while remaining > 0.001:
        var step: float = minf(1.0, remaining)
        remaining -= step
        _advance_sleep_radiation_v54(player, step, simulated_day_index, generator_protected)

func _advance_sleep_radiation_v54(
    player: CharacterBody3D,
    delta: float,
    simulated_day_index: int,
    generator_protected: bool
) -> void:
    if simulated_day_index < RADIATION_START_DAY:
        radiation_rate = -0.45
        radiation = maxf(0.0, radiation + radiation_rate * delta)
    elif generator_protected:
        radiation_rate = -1.20
        radiation = maxf(0.0, radiation + radiation_rate * delta)
    else:
        var base_rate: float = 0.10
        if simulated_day_index == 4:
            base_rate = 0.14
        elif simulated_day_index >= 5:
            base_rate = minf(0.32, 0.18 + float(simulated_day_index - 5) * 0.018)

        var weather_multiplier: float = 1.0
        var forest_runtime: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
        if forest_runtime != null:
            var weather: String = str(forest_runtime.get("current_weather"))
            if weather == "rain":
                weather_multiplier = 1.12
            elif weather == "storm":
                weather_multiplier = 1.35

        var gear_multiplier: float = 1.0
        if player.has_method("has_item") and bool(player.call("has_item", "radiation_suit")):
            gear_multiplier = 0.22

        radiation_rate = base_rate * weather_multiplier * gear_multiplier
        radiation = minf(100.0, radiation + radiation_rate * delta)

    if radiation >= 35.0:
        player.set("stamina", maxf(0.0, float(player.get("stamina")) - 0.08 * delta))
    if radiation >= 55.0:
        player.set("thirst", maxf(0.0, float(player.get("thirst")) - 0.035 * delta))

    damage_timer -= delta
    if damage_timer > 0.0:
        return
    damage_timer = 3.0

    var damage: float = 0.0
    if radiation >= 90.0:
        damage = 5.0
    elif radiation >= 72.0:
        damage = 2.5
    if damage > 0.0 and player.has_method("apply_damage"):
        player.call("apply_damage", damage, "radiation exposure during sleep")
