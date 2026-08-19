extends "res://scripts/hud_layout_system_v40.gd"

var radiation_cell_v41: VBoxContainer = null
var radiation_icon_v41: TextureRect = null
var radiation_value_v41: Label = null
var radiation_bar_v41: ProgressBar = null

func _process(delta: float) -> void:
    super._process(delta)
    _ensure_radiation_cell_v41()
    _update_radiation_cell_v41()
    _layout_radiation_cell_v41()

func _release_player() -> void:
    super._release_player()
    radiation_cell_v41 = null
    radiation_icon_v41 = null
    radiation_value_v41 = null
    radiation_bar_v41 = null

func _ensure_radiation_cell_v41() -> void:
    if top_row == null or not is_instance_valid(top_row):
        radiation_cell_v41 = null
        return
    if radiation_cell_v41 != null and is_instance_valid(radiation_cell_v41) and radiation_cell_v41.get_parent() == top_row:
        return

    radiation_cell_v41 = top_row.get_node_or_null("Stat_RadiationV41") as VBoxContainer
    if radiation_cell_v41 == null:
        radiation_cell_v41 = VBoxContainer.new()
        radiation_cell_v41.name = "Stat_RadiationV41"
        radiation_cell_v41.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        radiation_cell_v41.add_theme_constant_override("separation", 1)
        top_row.add_child(radiation_cell_v41)

        var header: HBoxContainer = HBoxContainer.new()
        header.name = "IconHeaderV41"
        header.alignment = BoxContainer.ALIGNMENT_CENTER
        header.add_theme_constant_override("separation", 5)
        radiation_cell_v41.add_child(header)

        radiation_icon_v41 = TextureRect.new()
        radiation_icon_v41.name = "Icon"
        radiation_icon_v41.mouse_filter = Control.MOUSE_FILTER_IGNORE
        radiation_icon_v41.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        radiation_icon_v41.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        radiation_icon_v41.texture = load("res://assets/ui/hud/icon_radiation.svg") as Texture2D
        radiation_icon_v41.modulate = Color(0.62, 0.92, 0.30, 1.0)
        radiation_icon_v41.tooltip_text = "Radiation Exposure"
        header.add_child(radiation_icon_v41)

        radiation_value_v41 = Label.new()
        radiation_value_v41.name = "Value"
        radiation_value_v41.text = "0"
        radiation_value_v41.tooltip_text = "Radiation Exposure"
        header.add_child(radiation_value_v41)

        radiation_bar_v41 = ProgressBar.new()
        radiation_bar_v41.name = "Bar"
        radiation_bar_v41.min_value = 0.0
        radiation_bar_v41.max_value = 100.0
        radiation_bar_v41.value = 0.0
        radiation_bar_v41.show_percentage = false
        radiation_bar_v41.mouse_filter = Control.MOUSE_FILTER_IGNORE
        radiation_bar_v41.custom_minimum_size = Vector2(0.0, 7.0)
        radiation_bar_v41.add_theme_stylebox_override("background", _v40_bar_background())
        radiation_bar_v41.add_theme_stylebox_override("fill", _v40_bar_fill(Color(0.62, 0.92, 0.30, 1.0)))
        radiation_cell_v41.add_child(radiation_bar_v41)
    else:
        radiation_icon_v41 = radiation_cell_v41.get_node_or_null("IconHeaderV41/Icon") as TextureRect
        radiation_value_v41 = radiation_cell_v41.get_node_or_null("IconHeaderV41/Value") as Label
        radiation_bar_v41 = radiation_cell_v41.get_node_or_null("Bar") as ProgressBar

func _update_radiation_cell_v41() -> void:
    if radiation_value_v41 == null or radiation_bar_v41 == null:
        return
    var radiation_system: Node = get_node_or_null("/root/RadiationSystem")
    var value: float = 0.0
    if radiation_system != null and radiation_system.has_method("get_radiation"):
        value = clampf(float(radiation_system.call("get_radiation")), 0.0, 100.0)
    radiation_value_v41.text = "%d" % int(round(value))
    radiation_bar_v41.value = value

func _layout_radiation_cell_v41() -> void:
    if radiation_cell_v41 == null:
        return
    var compact: bool = _is_mobile_layout() or get_viewport().get_visible_rect().size.x < 800.0
    var icon_size: float = 16.0 if compact else 20.0
    if radiation_icon_v41 != null:
        radiation_icon_v41.custom_minimum_size = Vector2(icon_size, icon_size)
    if radiation_value_v41 != null:
        radiation_value_v41.add_theme_font_size_override("font_size", 10 if compact else 12)
        radiation_value_v41.custom_minimum_size = Vector2(26.0 if compact else 32.0, 18.0 if compact else 22.0)
