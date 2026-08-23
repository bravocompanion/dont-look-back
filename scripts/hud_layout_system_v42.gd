extends "res://scripts/hud_layout_system_v41.gd"

func _layout_primary_objective() -> void:
    if tracked_player == null or primary_objective == null or not is_instance_valid(primary_objective):
        return
    var coordinator: Node = get_node_or_null("/root/UIRuntimeCoordinator")
    if coordinator == null or not coordinator.has_method("get_layout_v71"):
        super._layout_primary_objective()
        return
    var viewport: Vector2 = tracked_player.get_viewport().get_visible_rect().size
    var layout: Dictionary = Dictionary(coordinator.call("get_layout_v71", viewport))
    var rect_value: Variant = layout.get("objective", null)
    if not (rect_value is Rect2):
        super._layout_primary_objective()
        return
    var rect: Rect2 = rect_value
    primary_objective.set_anchors_preset(Control.PRESET_TOP_LEFT)
    primary_objective.position = rect.position
    primary_objective.size = rect.size
    primary_objective.max_lines_visible = 2
    primary_objective.add_theme_font_size_override("font_size", 14 if bool(layout.get("compact", false)) else 19)

func get_hud_collision_contract_v71() -> Dictionary:
    return {
        "objective_uses_coordinator": true,
        "status_bar_ownership_retained": true,
        "legacy_hud_suppression_retained": true,
        "desktop_responsive": true,
        "mobile_responsive": true
    }
