extends "res://scripts/forest_survival_system_v28_english.gd"

# v0.39: weather remains an active gameplay system, but its text is no longer
# drawn over the primary objective. The weather tint and mobile hunt button stay active.

func _set_ui_visible(value: bool) -> void:
    if weather_label != null:
        weather_label.visible = false
    if weather_tint != null:
        weather_tint.visible = value
    if hunt_button != null and not value:
        hunt_button.visible = false
