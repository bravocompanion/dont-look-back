extends "res://scripts/shelter_system_ranger_v9.gd"

func _update_status_label(player: CharacterBody3D) -> void:
    super._update_status_label(player)
    if status_label == null:
        return

    var yard_safe: bool = generator_running or campfire_burn_seconds > 0.05
    var width: float = player.get_viewport().get_visible_rect().size.x if player != null else 1280.0
    if width < 800.0:
        status_label.text += "  |  %s" % ("YARD SAFE" if yard_safe else "YARD EXPOSED")
    else:
        status_label.text += "  |  RANGER YARD: %s" % ("PROTECTED" if yard_safe else "EXPOSED")
