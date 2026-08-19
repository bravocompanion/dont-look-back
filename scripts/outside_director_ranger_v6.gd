extends "res://scripts/outside_director_ranger_v5.gd"

const RANGER_START_MINUTES_V41: float = 720.0

func _ready() -> void:
    super._ready()
    # New ranger runs begin at 12:00. Save restoration can overwrite this later.
    game_minutes = RANGER_START_MINUTES_V41
