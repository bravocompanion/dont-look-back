extends "res://scripts/wildlife_animal.gd"

# v0.45: wildlife uses real numerical health pools instead of tiny hit counters.
# Movement/behaviour still comes from the proven base wildlife script.
func _apply_kind_stats() -> void:
    super._apply_kind_stats()
    match animal_kind:
        "rabbit":
            max_health = 45.0
        "boar":
            max_health = 260.0
        "wolf":
            max_health = 190.0
        _:
            max_health = 150.0
