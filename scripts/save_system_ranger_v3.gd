extends "res://scripts/save_system_ranger_v2.gd"

const RANGER_START_MINUTES_V40: float = 360.0

func _prepare_clean_reload() -> void:
    super._prepare_clean_reload()
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        outside.set("game_minutes", RANGER_START_MINUTES_V40)
        outside.set("day_index", 1)
        outside.set("cold_exposure", 0.0)
