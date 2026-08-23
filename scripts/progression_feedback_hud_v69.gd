extends Node

# Compact always-on progression feedback. The full build/talent interface stays
# in ProgressionMenuSystem; this HUD only answers: what level am I, how close is
# the next level, and what progression event just happened?

var layer: CanvasLayer
var panel: PanelContainer
var level_label: Label
var xp_bar: ProgressBar
var points_label: Label
var toast_label: Label
var toast_seconds: float = 0.0
var refresh_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 530
    _build_ui_v69()
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null:
        if progression.has_signal("progression_feedback") and not progression.progression_feedback.is_connected(_on_progression_feedback_v69):
            progression.progression_feedback.connect(_on_progression_feedback_v69)
        if progression.has_signal("progression_changed") and not progression.progression_changed.is_connected(_refresh_now_v69):
            progression.progression_changed.connect(_refresh_now_v69)

func _process(delta: float) -> void:
    var player: CharacterBody3D = _local_player_v69()
    var gameplay: bool = player != null and _gameplay_active_v69()
    if panel != null:
        panel.visible = gameplay
    if toast_label != null and not gameplay:
        toast_label.visible = false
    if not gameplay:
        return

    refresh_timer -= delta
    if refresh_timer <= 0.0:
        refresh_timer = 0.20
        _refresh_now_v69()
    _layout_v69()

    if toast_seconds > 0.0:
        toast_seconds = maxf(0.0, toast_seconds - delta)
        toast_label.visible = toast_seconds > 0.0

func _build_ui_v69() -> void:
    layer = CanvasLayer.new()
    layer.name = "ProgressionFeedbackHUDV69"
    layer.layer = 68
    add_child(layer)

    panel = PanelContainer.new()
    panel.name = "ProgressionStrip"
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", _panel_style_v69())
    layer.add_child(panel)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_top", 5)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_bottom", 5)
    panel.add_child(margin)

    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    margin.add_child(row)

    level_label = Label.new()
    level_label.text = "LV 1"
    level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    level_label.add_theme_font_size_override("font_size", 13)
    row.add_child(level_label)

    xp_bar = ProgressBar.new()
    xp_bar.show_percentage = false
    xp_bar.min_value = 0.0
    xp_bar.max_value = 120.0
    xp_bar.value = 0.0
    xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    xp_bar.custom_minimum_size = Vector2(140.0, 10.0)
    xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(xp_bar)

    points_label = Label.new()
    points_label.text = ""
    points_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    points_label.add_theme_font_size_override("font_size", 11)
    row.add_child(points_label)

    toast_label = Label.new()
    toast_label.name = "ProgressionToast"
    toast_label.visible = false
    toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toast_label.add_theme_font_size_override("font_size", 13)
    toast_label.add_theme_stylebox_override("normal", _toast_style_v69())
    layer.add_child(toast_label)

    _layout_v69()

func _refresh_now_v69() -> void:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression == null or level_label == null:
        return

    var current_level: int = int(progression.get("level"))
    var current_xp: int = int(progression.get("xp_in_level"))
    var talent_points: int = int(progression.get("talent_points"))
    var stat_points: int = int(progression.get("stat_points"))
    var next_xp: int = int(progression.call("xp_to_next_level_v68", current_level)) if progression.has_method("xp_to_next_level_v68") else 0

    level_label.text = "LV %d" % current_level
    if next_xp <= 0:
        xp_bar.max_value = 1.0
        xp_bar.value = 1.0
        xp_bar.tooltip_text = "Maximum survivor level reached."
    else:
        xp_bar.max_value = maxf(1.0, float(next_xp))
        xp_bar.value = clampf(float(current_xp), 0.0, float(next_xp))
        xp_bar.tooltip_text = "%d / %d XP to next level" % [current_xp, next_xp]

    var parts: PackedStringArray = PackedStringArray()
    if talent_points > 0:
        parts.append("TP %d" % talent_points)
    if stat_points > 0:
        parts.append("SP %d" % stat_points)
    points_label.text = " • ".join(parts)

func _on_progression_feedback_v69(message: String) -> void:
    if toast_label == null or message.strip_edges().is_empty():
        return
    toast_label.text = message.strip_edges()
    toast_seconds = 3.6
    toast_label.visible = _gameplay_active_v69() and _local_player_v69() != null
    _refresh_now_v69()

func _layout_v69() -> void:
    if panel == null or toast_label == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = _mobile_active_v69() or size.x < 800.0
    var panel_width: float = minf(260.0 if compact else 390.0, maxf(200.0, size.x - 24.0))
    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    panel.position = Vector2((size.x - panel_width) * 0.5, 8.0)
    panel.size = Vector2(panel_width, 34.0 if compact else 38.0)
    level_label.add_theme_font_size_override("font_size", 11 if compact else 13)
    points_label.add_theme_font_size_override("font_size", 10 if compact else 11)
    xp_bar.custom_minimum_size = Vector2(90.0 if compact else 150.0, 9.0 if compact else 11.0)

    var toast_width: float = minf(430.0 if compact else 620.0, maxf(220.0, size.x - 24.0))
    toast_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
    toast_label.position = Vector2((size.x - toast_width) * 0.5, 48.0 if compact else 54.0)
    toast_label.size = Vector2(toast_width, 42.0 if compact else 46.0)

func _panel_style_v69() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.015, 0.020, 0.028, 0.88)
    style.border_color = Color(0.42, 0.48, 0.54, 0.45)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 7
    style.corner_radius_top_right = 7
    style.corner_radius_bottom_left = 7
    style.corner_radius_bottom_right = 7
    return style

func _toast_style_v69() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.010, 0.014, 0.020, 0.90)
    style.border_color = Color(0.48, 0.56, 0.62, 0.50)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 7
    style.corner_radius_top_right = 7
    style.corner_radius_bottom_left = 7
    style.corner_radius_bottom_right = 7
    style.content_margin_left = 10.0
    style.content_margin_right = 10.0
    return style

func _gameplay_active_v69() -> bool:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return false
    return scene.scene_file_path not in ["res://scenes/main_menu.tscn", "res://scenes/main_menu_ranger.tscn"]

func _mobile_active_v69() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

func _local_player_v69() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback

func get_feedback_hud_contract_v69() -> Dictionary:
    return {
        "shows_level": true,
        "shows_xp_progress": true,
        "shows_unspent_points": true,
        "shows_event_toasts": true,
        "mobile_responsive": true,
        "desktop_responsive": true,
        "requires_new_art": false
    }
