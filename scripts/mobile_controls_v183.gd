extends "res://scripts/mobile_controls.gd"

var jump_button: Button

func _process(delta: float) -> void:
    super._process(delta)

func _build_ui() -> void:
    super._build_ui()
    jump_button = _make_button("JUMP", "jump")

func _layout_ui(viewport_size: Vector2) -> void:
    super._layout_ui(viewport_size)
    if jump_button == null:
        return

    var short_side: float = minf(viewport_size.x, viewport_size.y)
    var action_size: float = clampf(short_side * 0.115, 62.0, 86.0)
    var margin: float = clampf(short_side * 0.035, 16.0, 28.0)
    var gap: float = clampf(short_side * 0.018, 8.0, 14.0)
    jump_button.size = Vector2(action_size, action_size)
    jump_button.position = Vector2(
        viewport_size.x - margin - action_size * 2.0 - gap,
        viewport_size.y - margin - action_size * 3.0 - gap * 2.0
    )
    jump_button.add_theme_font_size_override("font_size", int(clampf(short_side * 0.028, 14.0, 20.0)))

func _update_action_visibility() -> void:
    super._update_action_visibility()
    if jump_button != null:
        jump_button.visible = mobile_active and not dead_mode and not external_blocked and not scene_blocked

func _is_over_action_button(point: Vector2) -> bool:
    if jump_button != null and jump_button.is_visible_in_tree() and jump_button.get_global_rect().has_point(point):
        return true
    return super._is_over_action_button(point)
