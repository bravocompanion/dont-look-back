extends "res://scripts/hud_layout_system_v39.gd"

# v0.40 compact icon-based top HUD. Existing SVG assets are reused so there is
# still only one survival HUD owner and no duplicate vertical panel.
const ICON_PATHS_V40: Dictionary = {
    "health": "res://assets/ui/hud/icon_health.svg",
    "hunger": "res://assets/ui/hud/icon_hunger.svg",
    "thirst": "res://assets/ui/hud/icon_thirst.svg",
    "stamina": "res://assets/ui/hud/icon_stamina.svg",
    "battery": "res://assets/ui/hud/icon_battery.svg",
    "darkness": "res://assets/ui/hud/icon_darkness.svg"
}
const ICON_COLORS_V40: Dictionary = {
    "health": Color(0.92, 0.20, 0.24, 1.0),
    "hunger": Color(0.93, 0.60, 0.20, 1.0),
    "thirst": Color(0.22, 0.62, 0.96, 1.0),
    "stamina": Color(0.35, 0.86, 0.48, 1.0),
    "battery": Color(0.96, 0.83, 0.25, 1.0),
    "darkness": Color(0.68, 0.42, 0.92, 1.0)
}
const TOOLTIP_NAMES_V40: Dictionary = {
    "health": "Health",
    "hunger": "Hunger",
    "thirst": "Thirst",
    "stamina": "Stamina",
    "battery": "Flashlight Battery",
    "darkness": "Darkness Exposure"
}

var icon_value_labels_v40: Dictionary = {}
var icon_nodes_v40: Dictionary = {}

func _process(delta: float) -> void:
    super._process(delta)
    _ensure_icon_headers_v40()
    _update_icon_values_v40()
    _layout_icon_headers_v40()

func _release_player() -> void:
    super._release_player()
    icon_value_labels_v40.clear()
    icon_nodes_v40.clear()

func _ensure_icon_headers_v40() -> void:
    if top_row == null or not is_instance_valid(top_row):
        icon_value_labels_v40.clear()
        icon_nodes_v40.clear()
        return

    for child: Node in top_row.get_children():
        var cell: VBoxContainer = child as VBoxContainer
        if cell == null:
            continue
        var stat_id: String = str(cell.get_meta("stat_id", ""))
        if stat_id.is_empty() or not ICON_PATHS_V40.has(stat_id):
            continue

        var legacy_value: Label = cell.get_node_or_null("Value") as Label
        if legacy_value != null:
            legacy_value.visible = false

        var header: HBoxContainer = cell.get_node_or_null("IconHeaderV40") as HBoxContainer
        if header == null:
            header = HBoxContainer.new()
            header.name = "IconHeaderV40"
            header.mouse_filter = Control.MOUSE_FILTER_IGNORE
            header.alignment = BoxContainer.ALIGNMENT_CENTER
            header.add_theme_constant_override("separation", 5)
            cell.add_child(header)
            cell.move_child(header, 0)

            var icon: TextureRect = TextureRect.new()
            icon.name = "Icon"
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.texture = load(str(ICON_PATHS_V40.get(stat_id, ""))) as Texture2D
            icon.modulate = Color(ICON_COLORS_V40.get(stat_id, Color.WHITE))
            icon.tooltip_text = str(TOOLTIP_NAMES_V40.get(stat_id, stat_id.capitalize()))
            header.add_child(icon)

            var value_label: Label = Label.new()
            value_label.name = "IconValue"
            value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
            value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            value_label.tooltip_text = str(TOOLTIP_NAMES_V40.get(stat_id, stat_id.capitalize()))
            header.add_child(value_label)

        var icon_node: TextureRect = header.get_node_or_null("Icon") as TextureRect
        var value_node: Label = header.get_node_or_null("IconValue") as Label
        if icon_node != null:
            icon_nodes_v40[stat_id] = icon_node
        if value_node != null:
            icon_value_labels_v40[stat_id] = value_node

        var bar: ProgressBar = cell.get_node_or_null("Bar") as ProgressBar
        if bar != null:
            bar.add_theme_stylebox_override("background", _v40_bar_background())
            bar.add_theme_stylebox_override("fill", _v40_bar_fill(Color(ICON_COLORS_V40.get(stat_id, Color.WHITE))))

func _update_icon_values_v40() -> void:
    if tracked_player == null or not is_instance_valid(tracked_player):
        return

    for stat_id: String in STAT_ORDER:
        var label: Label = icon_value_labels_v40.get(stat_id) as Label
        if label == null or not is_instance_valid(label):
            continue
        var value: float = 0.0
        match stat_id:
            "health": value = float(tracked_player.get("health"))
            "hunger": value = float(tracked_player.get("hunger"))
            "thirst": value = float(tracked_player.get("thirst"))
            "stamina": value = float(tracked_player.get("stamina"))
            "battery": value = float(tracked_player.get("flashlight_battery"))
            "darkness": value = float(tracked_player.get("darkness_exposure"))
        label.text = "%d" % int(round(value))

func _layout_icon_headers_v40() -> void:
    if top_row == null or not is_instance_valid(top_row):
        return
    var compact: bool = _is_mobile_layout() or get_viewport().get_visible_rect().size.x < 800.0
    var icon_size: float = 16.0 if compact else 20.0
    var font_size: int = 10 if compact else 12
    var header_height: float = 18.0 if compact else 22.0

    for stat_id: String in STAT_ORDER:
        var icon: TextureRect = icon_nodes_v40.get(stat_id) as TextureRect
        var value_label: Label = icon_value_labels_v40.get(stat_id) as Label
        if icon != null and is_instance_valid(icon):
            icon.custom_minimum_size = Vector2(icon_size, icon_size)
        if value_label != null and is_instance_valid(value_label):
            value_label.add_theme_font_size_override("font_size", font_size)
            value_label.custom_minimum_size = Vector2(28.0 if compact else 34.0, header_height)

func _v40_bar_background() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.055, 0.062, 0.072, 0.94)
    style.corner_radius_top_left = 3
    style.corner_radius_top_right = 3
    style.corner_radius_bottom_left = 3
    style.corner_radius_bottom_right = 3
    return style

func _v40_bar_fill(color: Color) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 3
    style.corner_radius_top_right = 3
    style.corner_radius_bottom_left = 3
    style.corner_radius_bottom_right = 3
    return style
