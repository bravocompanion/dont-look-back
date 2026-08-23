extends "res://scripts/progression_feedback_hud_v69.gd"

func _process(delta: float) -> void:
    super._process(delta)
    if panel == null or toast_label == null:
        return
    if _modal_ui_locked_v71():
        panel.visible = false
        toast_label.visible = false
        return
    # Toast and XP strip share one lane; a toast temporarily replaces the strip
    # instead of stacking another row on top of the objective.
    if toast_label.visible:
        panel.visible = false
    elif _gameplay_active_v69() and _local_player_v69() != null:
        panel.visible = true

func _layout_v69() -> void:
    if panel == null or toast_label == null:
        return
    var coordinator: Node = get_node_or_null("/root/UIRuntimeCoordinator")
    if coordinator == null or not coordinator.has_method("get_layout_v71"):
        super._layout_v69()
        return
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    var layout: Dictionary = Dictionary(coordinator.call("get_layout_v71", viewport))
    var progress_value: Variant = layout.get("progression", null)
    var toast_value: Variant = layout.get("toast", null)
    if progress_value is Rect2:
        var progress_rect: Rect2 = progress_value
        panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
        panel.position = progress_rect.position
        panel.size = progress_rect.size
    if toast_value is Rect2:
        var toast_rect: Rect2 = toast_value
        toast_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
        toast_label.position = toast_rect.position
        toast_label.size = toast_rect.size
    var compact: bool = bool(layout.get("compact", false))
    level_label.add_theme_font_size_override("font_size", 11 if compact else 13)
    points_label.add_theme_font_size_override("font_size", 10 if compact else 11)
    xp_bar.custom_minimum_size = Vector2(90.0 if compact else 150.0, 9.0 if compact else 11.0)
    toast_label.add_theme_font_size_override("font_size", 11 if compact else 13)

func _modal_ui_locked_v71() -> bool:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    return input_lock != null and input_lock.has_method("is_locked") and bool(input_lock.call("is_locked"))

func get_feedback_hud_collision_contract_v71() -> Dictionary:
    return {
        "uses_coordinator": true,
        "toast_replaces_strip": true,
        "hides_during_modal_ui": true,
        "top_status_overlap": false,
        "objective_overlap": false,
        "desktop_responsive": true,
        "mobile_responsive": true
    }
