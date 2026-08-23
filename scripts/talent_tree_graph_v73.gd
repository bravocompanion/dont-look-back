extends Control

signal talent_selected_v73(talent_id: String)

const NODE_SIZE_V73: Vector2 = Vector2(132, 122)
const COMPACT_MIN_SIZE_V73: Vector2 = Vector2(288, 620)
const DESKTOP_MIN_SIZE_V73: Vector2 = Vector2(748, 316)

var progression_v73: Node
var tree_name_v73: String = "SURVIVAL"
var compact_v73: bool = false
var selected_talent_v73: String = ""
var tiers_v73: Array = []
var edges_v73: Array = []
var node_controls_v73: Dictionary = {}

func configure_v73(progression: Node, tree_name: String, compact: bool, selected_talent: String = "") -> void:
    progression_v73 = progression
    tree_name_v73 = tree_name.to_upper()
    compact_v73 = compact
    selected_talent_v73 = selected_talent
    custom_minimum_size = COMPACT_MIN_SIZE_V73 if compact_v73 else DESKTOP_MIN_SIZE_V73
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mouse_filter = Control.MOUSE_FILTER_PASS
    _rebuild_v73()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and not node_controls_v73.is_empty():
        _layout_nodes_v73()

func _draw() -> void:
    if progression_v73 == null:
        return
    for edge_value: Variant in edges_v73:
        if not (edge_value is Dictionary):
            continue
        var edge: Dictionary = Dictionary(edge_value)
        var parent_id: String = str(edge.get("parent_id", ""))
        var child_id: String = str(edge.get("child_id", ""))
        var parent: Control = node_controls_v73.get(parent_id, null) as Control
        var child: Control = node_controls_v73.get(child_id, null) as Control
        if parent == null or child == null:
            continue
        _draw_edge_v73(parent, child, edge)

func get_graph_contract_v73() -> Dictionary:
    return {
        "graphical_connectors": true,
        "connector_renderer": "native_draw_polyline",
        "arrowheads": true,
        "lines_render_behind_nodes": true,
        "node_icons": true,
        "long_description_inside_node": false,
        "compact_vertical": compact_v73,
        "desktop_horizontal": not compact_v73,
        "node_count": node_controls_v73.size(),
        "edge_count": edges_v73.size()
    }

func _rebuild_v73() -> void:
    for child: Node in get_children():
        child.queue_free()
    node_controls_v73.clear()
    tiers_v73.clear()
    edges_v73.clear()
    if progression_v73 == null:
        queue_redraw()
        return

    if progression_v73.has_method("get_talent_tree_tiers_v72"):
        tiers_v73 = Array(progression_v73.call("get_talent_tree_tiers_v72", tree_name_v73))
    if progression_v73.has_method("get_talent_tree_edges_v73"):
        edges_v73 = Array(progression_v73.call("get_talent_tree_edges_v73", tree_name_v73))

    for tier_value: Variant in tiers_v73:
        if not (tier_value is Dictionary):
            continue
        var tier: Dictionary = Dictionary(tier_value)
        for talent_value: Variant in Array(tier.get("talents", [])):
            var talent_id: String = str(talent_value)
            var node_card: Control = _create_node_v73(talent_id)
            add_child(node_card)
            node_controls_v73[talent_id] = node_card

    call_deferred("_layout_nodes_v73")

func _create_node_v73(talent_id: String) -> Control:
    var data: Dictionary = Dictionary(progression_v73.call("get_talent_definition_v68", talent_id))
    var state: Dictionary = Dictionary(progression_v73.call("get_talent_tree_node_state_v72", talent_id))
    var rank: int = int(state.get("rank", 0))
    var max_rank: int = maxi(1, int(state.get("max_rank", data.get("max_rank", 1))))
    var maxed: bool = bool(state.get("maxed", rank >= max_rank))
    var available: bool = bool(state.get("can_unlock", false))
    var invested: bool = rank > 0
    var selected: bool = talent_id == selected_talent_v73

    var card: PanelContainer = PanelContainer.new()
    card.name = "TalentNode_%s" % talent_id
    card.size = NODE_SIZE_V73
    card.custom_minimum_size = NODE_SIZE_V73
    card.mouse_filter = Control.MOUSE_FILTER_STOP
    card.tooltip_text = str(data.get("description", ""))
    card.add_theme_stylebox_override("panel", _node_style_v73(maxed, available, invested, selected))
    card.gui_input.connect(_node_gui_input_v73.bind(talent_id))

    var margin: MarginContainer = MarginContainer.new()
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_theme_constant_override("margin_left", 7)
    margin.add_theme_constant_override("margin_right", 7)
    margin.add_theme_constant_override("margin_top", 6)
    margin.add_theme_constant_override("margin_bottom", 6)
    card.add_child(margin)

    var box: VBoxContainer = VBoxContainer.new()
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 2)
    margin.add_child(box)

    var icon_rect: TextureRect = TextureRect.new()
    icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon_rect.custom_minimum_size = Vector2(64, 64)
    icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var registry: Node = get_node_or_null("/root/TalentIconRegistry")
    if registry != null and registry.has_method("get_talent_icon_v73"):
        icon_rect.texture = registry.call("get_talent_icon_v73", talent_id) as Texture2D
    icon_rect.modulate = _node_icon_modulate_v73(maxed, available, invested)
    box.add_child(icon_rect)

    var name_label: Label = Label.new()
    name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    name_label.text = str(data.get("name", talent_id)).to_upper()
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    name_label.add_theme_font_size_override("font_size", 11)
    box.add_child(name_label)

    var state_label: Label = Label.new()
    state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    state_label.text = _node_state_text_v73(state, rank, max_rank)
    state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    state_label.add_theme_font_size_override("font_size", 10)
    state_label.add_theme_color_override("font_color", _node_state_color_v73(maxed, available, invested))
    box.add_child(state_label)
    return card

func _layout_nodes_v73() -> void:
    if tiers_v73.is_empty() or node_controls_v73.is_empty():
        queue_redraw()
        return
    var graph_size: Vector2 = Vector2(maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y))
    if compact_v73:
        _layout_vertical_v73(graph_size)
    else:
        _layout_horizontal_v73(graph_size)
    queue_redraw()

func _layout_horizontal_v73(graph_size: Vector2) -> void:
    var tier_count: int = maxi(1, tiers_v73.size())
    var left_margin: float = NODE_SIZE_V73.x * 0.5 + 10.0
    var right_margin: float = left_margin
    var usable_width: float = maxf(1.0, graph_size.x - left_margin - right_margin)
    for tier_index: int in range(tiers_v73.size()):
        var tier: Dictionary = Dictionary(tiers_v73[tier_index])
        var ids: Array = Array(tier.get("talents", []))
        var center_x: float = left_margin if tier_count <= 1 else left_margin + usable_width * float(tier_index) / float(tier_count - 1)
        for node_index: int in range(ids.size()):
            var talent_id: String = str(ids[node_index])
            var node: Control = node_controls_v73.get(talent_id, null) as Control
            if node == null:
                continue
            var center_y: float = graph_size.y * 0.5
            if ids.size() == 2:
                center_y += -70.0 if node_index == 0 else 70.0
            elif ids.size() > 2:
                center_y += (float(node_index) - float(ids.size() - 1) * 0.5) * 96.0
            node.position = Vector2(center_x - NODE_SIZE_V73.x * 0.5, center_y - NODE_SIZE_V73.y * 0.5)
            node.size = NODE_SIZE_V73

func _layout_vertical_v73(graph_size: Vector2) -> void:
    var tier_count: int = maxi(1, tiers_v73.size())
    var top_margin: float = NODE_SIZE_V73.y * 0.5 + 10.0
    var bottom_margin: float = top_margin
    var usable_height: float = maxf(1.0, graph_size.y - top_margin - bottom_margin)
    for tier_index: int in range(tiers_v73.size()):
        var tier: Dictionary = Dictionary(tiers_v73[tier_index])
        var ids: Array = Array(tier.get("talents", []))
        var center_y: float = top_margin if tier_count <= 1 else top_margin + usable_height * float(tier_index) / float(tier_count - 1)
        for node_index: int in range(ids.size()):
            var talent_id: String = str(ids[node_index])
            var node: Control = node_controls_v73.get(talent_id, null) as Control
            if node == null:
                continue
            var center_x: float = graph_size.x * 0.5
            if ids.size() == 2:
                center_x += -70.0 if node_index == 0 else 70.0
            elif ids.size() > 2:
                center_x += (float(node_index) - float(ids.size() - 1) * 0.5) * 92.0
            node.position = Vector2(center_x - NODE_SIZE_V73.x * 0.5, center_y - NODE_SIZE_V73.y * 0.5)
            node.size = NODE_SIZE_V73

func _draw_edge_v73(parent: Control, child: Control, edge: Dictionary) -> void:
    var prerequisite_met: bool = bool(edge.get("prerequisite_met", false))
    var child_invested: bool = bool(edge.get("child_invested", false))
    var child_maxed: bool = bool(edge.get("child_maxed", false))
    var line_color: Color = Color(0.24, 0.28, 0.32, 0.72)
    var glow_color: Color = Color(0.08, 0.10, 0.12, 0.18)
    var width: float = 2.0
    if prerequisite_met:
        line_color = Color(0.28, 0.72, 0.72, 0.92)
        glow_color = Color(0.16, 0.62, 0.64, 0.20)
        width = 2.6
    if child_invested:
        line_color = Color(0.48, 0.82, 0.78, 1.0)
        glow_color = Color(0.22, 0.72, 0.68, 0.28)
        width = 3.2
    if child_maxed:
        line_color = Color(0.76, 0.70, 0.38, 1.0)
        glow_color = Color(0.68, 0.56, 0.18, 0.24)
        width = 3.4

    var points: PackedVector2Array = PackedVector2Array()
    var end_point: Vector2
    if compact_v73:
        var start_point: Vector2 = parent.position + Vector2(parent.size.x * 0.5, parent.size.y)
        end_point = child.position + Vector2(child.size.x * 0.5, 0.0)
        var mid_y: float = (start_point.y + end_point.y) * 0.5
        points.append(start_point)
        points.append(Vector2(start_point.x, mid_y))
        points.append(Vector2(end_point.x, mid_y))
        points.append(end_point)
    else:
        var start_point: Vector2 = parent.position + Vector2(parent.size.x, parent.size.y * 0.5)
        end_point = child.position + Vector2(0.0, child.size.y * 0.5)
        var mid_x: float = (start_point.x + end_point.x) * 0.5
        points.append(start_point)
        points.append(Vector2(mid_x, start_point.y))
        points.append(Vector2(mid_x, end_point.y))
        points.append(end_point)

    draw_polyline(points, glow_color, width + 6.0, true)
    draw_polyline(points, line_color, width, true)
    var arrow: PackedVector2Array = PackedVector2Array()
    if compact_v73:
        arrow.append(end_point)
        arrow.append(end_point + Vector2(-6, -9))
        arrow.append(end_point + Vector2(6, -9))
    else:
        arrow.append(end_point)
        arrow.append(end_point + Vector2(-9, -6))
        arrow.append(end_point + Vector2(-9, 6))
    draw_colored_polygon(arrow, line_color)

func _node_gui_input_v73(event: InputEvent, talent_id: String) -> void:
    var pressed: bool = false
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        pressed = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
    elif event is InputEventScreenTouch:
        pressed = (event as InputEventScreenTouch).pressed
    if not pressed:
        return
    selected_talent_v73 = talent_id
    talent_selected_v73.emit(talent_id)
    accept_event()

func _node_style_v73(maxed: bool, available: bool, invested: bool, selected: bool) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.022, 0.028, 0.034, 0.98)
    style.border_color = Color(0.24, 0.29, 0.34, 0.78)
    var border_width: int = 1
    if invested:
        style.bg_color = Color(0.035, 0.070, 0.072, 0.98)
        style.border_color = Color(0.34, 0.66, 0.64, 0.92)
        border_width = 2
    if available:
        style.bg_color = Color(0.050, 0.080, 0.086, 0.99)
        style.border_color = Color(0.40, 0.78, 0.78, 1.0)
        border_width = 2
    if maxed:
        style.bg_color = Color(0.065, 0.075, 0.040, 0.99)
        style.border_color = Color(0.76, 0.70, 0.38, 1.0)
        border_width = 2
    if selected:
        style.border_color = Color(0.92, 0.82, 0.48, 1.0)
        border_width = 3
    style.set_border_width_all(border_width)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    return style

func _node_icon_modulate_v73(maxed: bool, available: bool, invested: bool) -> Color:
    if maxed:
        return Color(1.0, 0.94, 0.70, 1.0)
    if invested or available:
        return Color.WHITE
    return Color(0.48, 0.52, 0.55, 0.72)

func _node_state_text_v73(state: Dictionary, rank: int, max_rank: int) -> String:
    if bool(state.get("maxed", false)):
        return "MAXED  %d/%d" % [rank, max_rank]
    if rank > 0:
        return "INVESTED  %d/%d" % [rank, max_rank]
    if bool(state.get("can_unlock", false)):
        return "AVAILABLE  %d/%d" % [rank, max_rank]
    return "LOCKED  %d/%d" % [rank, max_rank]

func _node_state_color_v73(maxed: bool, available: bool, invested: bool) -> Color:
    if maxed:
        return Color(0.94, 0.83, 0.48, 1.0)
    if invested:
        return Color(0.50, 0.84, 0.78, 1.0)
    if available:
        return Color(0.58, 0.90, 0.88, 1.0)
    return Color(0.50, 0.54, 0.58, 1.0)
