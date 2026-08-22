extends "res://scripts/shelter_system_ranger_v8.gd"

func _update_status_label(player: CharacterBody3D) -> void:
    super._update_status_label(player)
    if status_label == null:
        return
    var condition: int = get_generator_condition_percent_v55()
    var broken_text: String = " BROKEN" if generator_broken_v55 else ""
    var width: float = player.get_viewport().get_visible_rect().size.x if player != null else 1280.0
    if width < 800.0:
        status_label.text += "  COND %d%%%s" % [condition, broken_text]
    else:
        status_label.text += "  |  CONDITION %d%%%s" % [condition, broken_text]
