extends "res://scripts/forest_world_expansion_v3.gd"

const DAY_READABILITY_FILL: float = 0.20
const FULL_DARKNESS_AMBIENT: float = 0.05

func _build_readability_lights() -> void:
    super._build_readability_lights()
    if natural_fill != null and is_instance_valid(natural_fill):
        natural_fill.light_energy = DAY_READABILITY_FILL

func _apply_readability_lighting(scene: Node) -> void:
    var daylight: float = _current_daylight_factor()

    if natural_fill != null and is_instance_valid(natural_fill):
        # Objects receive ~20% neutral fill in daylight. It fades away with
        # the sun so full darkness is governed by the 5% ambient floor.
        natural_fill.light_energy = DAY_READABILITY_FILL * daylight

    var world_environment: WorldEnvironment = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if world_environment == null or world_environment.environment == null:
        return
    var environment: Environment = world_environment.environment
    environment.ambient_light_energy = maxf(FULL_DARKNESS_AMBIENT, environment.ambient_light_energy)

func _current_daylight_factor() -> float:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return 0.0

    var minute: float = fposmod(float(outside.get("game_minutes")), 1440.0)
    if minute >= 420.0 and minute < 1020.0:
        return 1.0
    if minute >= 1020.0 and minute < 1140.0:
        return 1.0 - clampf((minute - 1020.0) / 120.0, 0.0, 1.0)
    if minute >= 300.0 and minute < 420.0:
        return clampf((minute - 300.0) / 120.0, 0.0, 1.0)
    return 0.0
