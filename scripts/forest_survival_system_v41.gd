extends "res://scripts/forest_survival_system_v29_status_menu.gd"

func _process(delta: float) -> void:
    super._process(delta)
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var day_index: int = int(outside.get("day_index")) if outside != null else 1
    if day_index <= 1:
        animal_respawn_seconds = 120.0
    elif day_index == 2:
        animal_respawn_seconds = 100.0
    elif day_index <= 4:
        animal_respawn_seconds = 88.0
    else:
        animal_respawn_seconds = 76.0

func _apply_weather_survival(player: CharacterBody3D, delta: float) -> void:
    var sheltered: bool = player.global_position.distance_to(SHELTER_CENTER) <= 6.0
    var rain_multiplier: float = 1.0
    if player.has_method("has_item") and bool(player.call("has_item", "raincoat")):
        rain_multiplier = 0.25
    elif player.has_method("has_item") and bool(player.call("has_item", "radiation_suit")):
        rain_multiplier = 0.60

    if sheltered:
        wetness = maxf(0.0, wetness - 18.0 * delta)
    elif current_weather == "storm":
        wetness = minf(100.0, wetness + 7.5 * rain_multiplier * delta)
    elif current_weather == "rain":
        wetness = minf(100.0, wetness + 4.2 * rain_multiplier * delta)
    else:
        wetness = maxf(0.0, wetness - (2.0 if current_weather == "clear" else 0.8) * delta)

    if wetness >= 55.0:
        var stamina_loss: float = (0.24 if wetness < 82.0 else 0.48) * delta
        player.set("stamina", maxf(0.0, float(player.get("stamina")) - stamina_loss))

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null and not sheltered and wetness >= 65.0:
        var extra_cold: float = (0.55 if current_weather == "storm" else 0.25) * delta
        outside.set("cold_exposure", minf(100.0, float(outside.get("cold_exposure")) + extra_cold))
