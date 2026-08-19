extends "res://scripts/hud_layout_system_v32b.gd"

# v0.39 stable HUD ownership.
# Legacy gameplay scripts may continue writing to their original labels, but
# only this system controls what is visible. This prevents anchor/font/position
# oscillation between Player, Shelter, Outside, weather and condition systems.

var primary_objective: Label = null

func _ready() -> void:
    super._ready()
    process_priority = 420

func _process(delta: float) -> void:
    super._process(delta)
    _enforce_stable_hud()

func _apply_gameplay_layout() -> void:
    super._apply_gameplay_layout()
    _ensure_primary_objective()
    _layout_primary_objective()
    _enforce_stable_hud()

func _ensure_primary_objective() -> void:
    if tracked_hud == null or not is_instance_valid(tracked_hud):
        primary_objective = null
        return
    if primary_objective != null and is_instance_valid(primary_objective) and primary_objective.get_parent() == tracked_hud:
        return

    primary_objective = tracked_hud.get_node_or_null("PrimaryObjectiveV39") as Label
    if primary_objective == null:
        primary_objective = Label.new()
        primary_objective.name = "PrimaryObjectiveV39"
        primary_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
        primary_objective.z_index = 120
        primary_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        primary_objective.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        primary_objective.max_lines_visible = 2
        primary_objective.add_theme_color_override("font_color", Color(0.94, 0.95, 0.96, 1.0))
        primary_objective.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
        primary_objective.add_theme_constant_override("shadow_offset_x", 1)
        primary_objective.add_theme_constant_override("shadow_offset_y", 1)
        tracked_hud.add_child(primary_objective)

func _layout_primary_objective() -> void:
    if tracked_player == null or primary_objective == null or not is_instance_valid(primary_objective):
        return

    var size: Vector2 = tracked_player.get_viewport().get_visible_rect().size
    var compact: bool = _is_mobile_layout() or size.x < 800.0
    var margin: float = 10.0 if compact else 24.0
    var bar_height: float = 46.0 if compact else 52.0
    var top_margin: float = 5.0 if compact else 16.0
    var status_reserve: float = 106.0 if compact else 132.0
    var objective_y: float = bar_height + top_margin + 7.0
    var objective_height: float = 42.0 if compact else 46.0

    primary_objective.set_anchors_preset(Control.PRESET_TOP_LEFT)
    primary_objective.position = Vector2(margin, objective_y)
    primary_objective.size = Vector2(maxf(120.0, size.x - margin * 2.0 - status_reserve), objective_height)
    primary_objective.add_theme_font_size_override("font_size", 14 if compact else 19)

func _enforce_stable_hud() -> void:
    if tracked_player == null or tracked_hud == null or not is_instance_valid(tracked_hud):
        primary_objective = null
        return

    _ensure_primary_objective()
    if primary_objective == null:
        return

    var source_objective: Label = tracked_player.get_node_or_null("HUD/Objective") as Label
    if source_objective != null:
        if primary_objective.text != source_objective.text:
            primary_objective.text = source_objective.text
        source_objective.visible = false

    _hide_hud_node("CaseFile")
    _hide_hud_node("ShelterStatus")
    _hide_hud_node("PanicLabel")
    _hide_hud_node("InventoryLabel")
    _hide_hud_node("OutsideStatus")
    _hide_hud_node("ConditionStatus")
    _hide_hud_node("SurvivalPanel")
    _hide_hud_node("IconSurvivalHUD")

    primary_objective.visible = tracked_hud.visible and not bool(tracked_player.get("is_dead"))
    _layout_primary_objective()

func _hide_hud_node(node_name: String) -> void:
    if tracked_hud == null:
        return
    var control: Control = tracked_hud.get_node_or_null(NodePath(node_name)) as Control
    if control != null:
        control.visible = false
