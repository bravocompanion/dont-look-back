extends Node

const HUD_NODE_NAME: String = "IconSurvivalHUD"
const ICON_PATHS: Dictionary = {
    "health": "res://assets/ui/hud/icon_health.svg",
    "hunger": "res://assets/ui/hud/icon_hunger.svg",
    "thirst": "res://assets/ui/hud/icon_thirst.svg",
    "stamina": "res://assets/ui/hud/icon_stamina.svg",
    "battery": "res://assets/ui/hud/icon_battery.svg",
    "darkness": "res://assets/ui/hud/icon_darkness.svg"
}
const STAT_COLORS: Dictionary = {
    "health": Color(0.92, 0.20, 0.24, 1.0),
    "hunger": Color(0.93, 0.60, 0.20, 1.0),
    "thirst": Color(0.22, 0.62, 0.96, 1.0),
    "stamina": Color(0.35, 0.86, 0.48, 1.0),
    "battery": Color(0.96, 0.83, 0.25, 1.0),
    "darkness": Color(0.68, 0.42, 0.92, 1.0)
}
const TOOLTIP_NAMES: Dictionary = {
    "health": "Health",
    "hunger": "Hunger",
    "thirst": "Thirst",
    "stamina": "Stamina",
    "battery": "Flashlight battery",
    "darkness": "Darkness exposure"
}

var active_player: CharacterBody3D
var panel: PanelContainer
var stats_box: VBoxContainer
var rows: Dictionary = {}
var player_probe_timer: float = 0.0
var refresh_timer: float = 0.0
var layout_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_try_bind_local_player")

func _process(delta: float) -> void:
    player_probe_timer -= delta
    if player_probe_timer <= 0.0:
        player_probe_timer = 0.45
        if not is_instance_valid(active_player) or not _is_local_player(active_player) or not is_instance_valid(panel):
            _try_bind_local_player()

    if not is_instance_valid(active_player) or not is_instance_valid(panel):
        return

    refresh_timer -= delta
    if refresh_timer <= 0.0:
        refresh_timer = 0.08
        _update_stats()

    layout_timer -= delta
    if layout_timer <= 0.0:
        layout_timer = 0.45
        _hide_legacy_survival_panel()
        _apply_responsive_layout()

func _try_bind_local_player() -> void:
    var candidate: CharacterBody3D = _find_local_player()
    if candidate == null:
        active_player = null
        panel = null
        rows.clear()
        return

    if candidate == active_player and is_instance_valid(panel):
        return

    active_player = candidate
    rows.clear()
    panel = null
    stats_box = null

    var hud: CanvasLayer = active_player.get_node_or_null("HUD") as CanvasLayer
    if hud == null:
        return

    var stale: Node = hud.get_node_or_null(HUD_NODE_NAME)
    if stale != null:
        stale.queue_free()

    _hide_legacy_survival_panel()
    _build_icon_hud(hud)
    _apply_responsive_layout()
    _update_stats()

func _find_local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null or player.get_node_or_null("HUD") == null:
            continue
        if fallback == null:
            fallback = player
        if _is_local_player(player):
            return player
    return fallback

func _is_local_player(player: CharacterBody3D) -> bool:
    if player == null:
        return false
    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    return camera != null and camera.current

func _hide_legacy_survival_panel() -> void:
    if not is_instance_valid(active_player):
        return
    var legacy: Control = active_player.get_node_or_null("HUD/SurvivalPanel") as Control
    if legacy != null:
        legacy.visible = false

func _build_icon_hud(hud: CanvasLayer) -> void:
    panel = PanelContainer.new()
    panel.name = HUD_NODE_NAME
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.anchor_left = 1.0
    panel.anchor_top = 0.0
    panel.anchor_right = 1.0
    panel.anchor_bottom = 0.0
    panel.add_theme_stylebox_override("panel", _make_panel_style())
    hud.add_child(panel)

    stats_box = VBoxContainer.new()
    stats_box.name = "Stats"
    stats_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stats_box.add_theme_constant_override("separation", 4)
    panel.add_child(stats_box)

    _add_stat_row("health")
    _add_stat_row("hunger")
    _add_stat_row("thirst")
    _add_stat_row("stamina")
    _add_stat_row("battery")
    _add_stat_row("darkness")

func _add_stat_row(stat_key: String) -> void:
    var row: HBoxContainer = HBoxContainer.new()
    row.name = stat_key.capitalize()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.tooltip_text = str(TOOLTIP_NAMES.get(stat_key, stat_key))
    row.add_theme_constant_override("separation", 6)
    stats_box.add_child(row)

    var icon: TextureRect = TextureRect.new()
    icon.name = "Icon"
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture = load(str(ICON_PATHS[stat_key])) as Texture2D
    icon.modulate = STAT_COLORS[stat_key]
    row.add_child(icon)

    var bar: ProgressBar = ProgressBar.new()
    bar.name = "Bar"
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.min_value = 0.0
    bar.max_value = 100.0
    bar.value = 100.0
    bar.show_percentage = false
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    bar.add_theme_stylebox_override("background", _make_bar_background())
    bar.add_theme_stylebox_override("fill", _make_bar_fill(STAT_COLORS[stat_key]))
    row.add_child(bar)

    var value_label: Label = Label.new()
    value_label.name = "Value"
    value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    value_label.text = "100"
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value_label.add_theme_color_override("font_color", Color(0.93, 0.94, 0.96, 1.0))
    value_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
    value_label.add_theme_constant_override("shadow_offset_x", 1)
    value_label.add_theme_constant_override("shadow_offset_y", 1)
    row.add_child(value_label)

    rows[stat_key] = {
        "row": row,
        "icon": icon,
        "bar": bar,
        "value": value_label
    }

func _make_panel_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.016, 0.023, 0.82)
    style.border_color = Color(0.58, 0.62, 0.70, 0.22)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 9
    style.corner_radius_top_right = 9
    style.corner_radius_bottom_left = 9
    style.corner_radius_bottom_right = 9
    style.content_margin_left = 9.0
    style.content_margin_right = 9.0
    style.content_margin_top = 8.0
    style.content_margin_bottom = 8.0
    return style

func _make_bar_background() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.07, 0.08, 0.10, 0.92)
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    return style

func _make_bar_fill(color: Color) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    return style

func _apply_responsive_layout() -> void:
    if not is_instance_valid(panel):
        return

    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var mobile_active: bool = false
    var mobile_controls: Node = get_node_or_null("/root/MobileControls")
    if mobile_controls != null and mobile_controls.has_method("is_mobile_active"):
        mobile_active = bool(mobile_controls.call("is_mobile_active"))

    var compact: bool = viewport_size.x < 800.0 or mobile_active
    var panel_width: float = 172.0 if compact else 248.0
    var top_offset: float = 88.0 if compact else 72.0
    var right_margin: float = 10.0 if compact else 28.0
    var icon_size: float = 22.0 if compact else 27.0
    var bar_width: float = 76.0 if compact else 136.0
    var bar_height: float = 9.0 if compact else 11.0
    var value_width: float = 34.0 if compact else 40.0
    var font_size: int = 13 if compact else 15
    var row_height: float = 24.0 if compact else 29.0
    var panel_height: float = 176.0 if compact else 208.0

    panel.offset_left = -panel_width - right_margin
    panel.offset_top = top_offset
    panel.offset_right = -right_margin
    panel.offset_bottom = top_offset + panel_height

    for key_variant: Variant in rows.keys():
        var entry: Dictionary = rows[key_variant]
        var row: HBoxContainer = entry["row"] as HBoxContainer
        var icon: TextureRect = entry["icon"] as TextureRect
        var bar: ProgressBar = entry["bar"] as ProgressBar
        var value_label: Label = entry["value"] as Label
        row.custom_minimum_size = Vector2(0.0, row_height)
        icon.custom_minimum_size = Vector2(icon_size, icon_size)
        bar.custom_minimum_size = Vector2(bar_width, bar_height)
        value_label.custom_minimum_size = Vector2(value_width, 0.0)
        value_label.add_theme_font_size_override("font_size", font_size)

func _update_stats() -> void:
    if not is_instance_valid(active_player):
        return

    _set_stat("health", _player_float("health"), _player_float("max_health", 100.0))
    _set_stat("hunger", _player_float("hunger"), _player_float("max_hunger", 100.0))
    _set_stat("thirst", _player_float("thirst"), _player_float("max_thirst", 100.0))
    _set_stat("stamina", _player_float("stamina"), _player_float("max_stamina", 100.0))
    _set_stat("battery", _player_float("flashlight_battery"), _player_float("max_flashlight_battery", 100.0))
    _set_stat("darkness", _player_float("darkness_exposure"), 100.0)

func _player_float(property_name: String, fallback: float = 0.0) -> float:
    if not is_instance_valid(active_player):
        return fallback
    var value: Variant = active_player.get(property_name)
    if value == null:
        return fallback
    return float(value)

func _set_stat(stat_key: String, current: float, maximum: float) -> void:
    if not rows.has(stat_key):
        return

    var percent: float = 0.0
    if maximum > 0.0:
        percent = clampf((current / maximum) * 100.0, 0.0, 100.0)

    var entry: Dictionary = rows[stat_key]
    var bar: ProgressBar = entry["bar"] as ProgressBar
    var icon: TextureRect = entry["icon"] as TextureRect
    var value_label: Label = entry["value"] as Label
    bar.value = percent
    value_label.text = "%d" % int(round(percent))

    var pulse_alpha: float = 1.0
    if _is_warning(stat_key, percent):
        pulse_alpha = 0.56 + 0.44 * absf(sin(float(Time.get_ticks_msec()) / 170.0))
    var base_color: Color = STAT_COLORS[stat_key]
    icon.modulate = Color(base_color.r, base_color.g, base_color.b, pulse_alpha)
    value_label.modulate = Color(1.0, 1.0, 1.0, pulse_alpha)

func _is_warning(stat_key: String, percent: float) -> bool:
    if stat_key == "darkness":
        return percent >= 72.0
    if stat_key == "stamina":
        return percent <= 12.0
    if stat_key == "battery":
        return percent <= 20.0
    if stat_key == "health":
        return percent <= 28.0
    return percent <= 18.0
