extends "res://scripts/journal_system_ranger_v4.gd"

# v0.38 English-only journal layer.
# Removes runtime language switching from mission text.

func _is_id() -> bool:
    return false

func _pick(_id_text: String, en_text: String) -> String:
    return en_text
