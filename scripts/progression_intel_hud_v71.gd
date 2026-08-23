extends "res://scripts/progression_intel_hud_v70.gd"

func _layout_v70() -> void:
    if panel == null or label == null:
        return
    var coordinator: Node = get_node_or_null("/root/UIRuntimeCoordinator")
    if coordinator == null or not coordinator.has_method("get_layout_v71"):
        super._layout_v70()
        return
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    var layout: Dictionary = Dictionary(coordinator.call("get_layout_v71", viewport))
    var rect_value: Variant = layout.get("intel", null)
    if not (rect_value is Rect2):
        return
    var rect: Rect2 = rect_value
    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    panel.position = rect.position
    panel.size = rect.size
    var compact: bool = bool(layout.get("compact", false))
    label.add_theme_font_size_override("font_size", 10 if compact else 12)
    label.max_lines_visible = 3 if compact else 5
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func get_intel_hud_collision_contract_v71() -> Dictionary:
    return {
        "uses_coordinator": true,
        "hides_during_modal_ui": true,
        "mobile_max_lines": 3,
        "objective_overlap": false,
        "quick_button_overlap": false,
        "desktop_responsive": true,
        "mobile_responsive": true,
        "changes_world_authority": false
    }
