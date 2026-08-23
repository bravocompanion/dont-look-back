extends "res://scripts/progression_menu_system_v71.gd"

var active_talent_tree_v72: String = "SURVIVAL"

func _build_talents_tab_v68(progression: Node, player_level: int, points_available: int) -> void:
    _add_section_v68("TALENT TREE — %d POINTS AVAILABLE" % points_available)
    _add_info_v68("Choose a specialization, then advance through its branches. Higher tiers require both survivor level and the connected prerequisite rank.", 13)

    var tree_names: Array = Array(progression.call("get_talent_tree_names_v72")) if progression.has_method("get_talent_tree_names_v72") else ["SURVIVAL", "SCOUT", "TECHNICIAN", "INVESTIGATOR"]
    if active_talent_tree_v72 not in tree_names and not tree_names.is_empty():
        active_talent_tree_v72 = str(tree_names[0])

    _build_tree_selector_v72(tree_names)
    _add_subsection_v68("%s TREE" % active_talent_tree_v72)

    var tiers: Array = Array(progression.call("get_talent_tree_tiers_v72", active_talent_tree_v72)) if progression.has_method("get_talent_tree_tiers_v72") else []
    if tiers.is_empty():
        _add_info_v68("Talent tree data unavailable.", 14)
        return

    if _talent_tree_compact_v72():
        _build_vertical_tree_v72(progression, tiers, player_level, points_available)
    else:
        _build_horizontal_tree_v72(progression, tiers, player_level, points_available)

func _build_tree_selector_v72(tree_names: Array) -> void:
    var compact: bool = _talent_tree_compact_v72()
    var selector: Container
    if compact:
        var grid: GridContainer = GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 6)
        grid.add_theme_constant_override("v_separation", 6)
        selector = grid
    else:
        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        selector = row
    selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(selector)

    for tree_value: Variant in tree_names:
        var tree_name: String = str(tree_value)
        var button: Button = Button.new()
        button.text = ("● " if tree_name == active_talent_tree_v72 else "") + tree_name
        button.focus_mode = Control.FOCUS_NONE
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.custom_minimum_size = Vector2(0, 42 if compact else 38)
        button.disabled = tree_name == active_talent_tree_v72
        button.pressed.connect(_select_talent_tree_v72.bind(tree_name))
        selector.add_child(button)

func _build_vertical_tree_v72(progression: Node, tiers: Array, player_level: int, points_available: int) -> void:
    var stack: VBoxContainer = VBoxContainer.new()
    stack.add_theme_constant_override("separation", 7)
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(stack)

    for tier_index: int in range(tiers.size()):
        var tier_value: Variant = tiers[tier_index]
        if not (tier_value is Dictionary):
            continue
        var tier: Dictionary = Dictionary(tier_value)
        var tier_level: int = int(tier.get("level", 1))
        var header: Label = Label.new()
        header.text = "%s  •  LEVEL %d" % [str(tier.get("name", "TIER")), tier_level]
        header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        header.add_theme_font_size_override("font_size", 14)
        header.add_theme_color_override("font_color", Color(0.72, 0.80, 0.86, 1.0))
        stack.add_child(header)

        var nodes: Array = Array(tier.get("talents", []))
        for talent_value: Variant in nodes:
            _add_talent_tree_node_v72(stack, progression, str(talent_value), player_level, points_available, true)

        if tier_index < tiers.size() - 1:
            var connector: Label = Label.new()
            connector.text = "│\n▼"
            connector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            connector.add_theme_font_size_override("font_size", 16)
            connector.add_theme_color_override("font_color", Color(0.48, 0.56, 0.62, 0.9))
            stack.add_child(connector)

func _build_horizontal_tree_v72(progression: Node, tiers: Array, player_level: int, points_available: int) -> void:
    var tree_row: HBoxContainer = HBoxContainer.new()
    tree_row.add_theme_constant_override("separation", 6)
    tree_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(tree_row)

    for tier_index: int in range(tiers.size()):
        var tier_value: Variant = tiers[tier_index]
        if not (tier_value is Dictionary):
            continue
        var tier: Dictionary = Dictionary(tier_value)
        var column: VBoxContainer = VBoxContainer.new()
        column.add_theme_constant_override("separation", 7)
        column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        column.custom_minimum_size = Vector2(168, 0)
        tree_row.add_child(column)

        var tier_level: int = int(tier.get("level", 1))
        var header: Label = Label.new()
        header.text = "%s\nLV %d" % [str(tier.get("name", "TIER")), tier_level]
        header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        header.add_theme_font_size_override("font_size", 12)
        header.add_theme_color_override("font_color", Color(0.72, 0.80, 0.86, 1.0))
        column.add_child(header)

        var nodes: Array = Array(tier.get("talents", []))
        for talent_value: Variant in nodes:
            _add_talent_tree_node_v72(column, progression, str(talent_value), player_level, points_available, false)

        if tier_index < tiers.size() - 1:
            var connector: Label = Label.new()
            connector.text = "▶"
            connector.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            connector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            connector.custom_minimum_size = Vector2(22, 200)
            connector.add_theme_font_size_override("font_size", 18)
            connector.add_theme_color_override("font_color", Color(0.48, 0.56, 0.62, 0.9))
            tree_row.add_child(connector)

func _add_talent_tree_node_v72(parent: Container, progression: Node, talent_id: String, player_level: int, points_available: int, compact: bool) -> void:
    var data: Dictionary = Dictionary(progression.call("get_talent_definition_v68", talent_id))
    var state: Dictionary = Dictionary(progression.call("get_talent_tree_node_state_v72", talent_id)) if progression.has_method("get_talent_tree_node_state_v72") else {}
    var rank: int = int(state.get("rank", progression.call("get_talent_rank_v68", talent_id)))
    var max_rank: int = int(state.get("max_rank", data.get("max_rank", 1)))
    var min_level: int = int(state.get("min_level", data.get("min_level", 1)))
    var required_name: String = str(state.get("required_name", ""))
    var required_rank: int = int(state.get("required_rank", 0))
    var required_ok: bool = bool(state.get("required_ok", true))
    var level_ok: bool = bool(state.get("level_ok", player_level >= min_level))
    var maxed: bool = bool(state.get("maxed", rank >= max_rank))
    var can_unlock: bool = bool(state.get("can_unlock", false))

    var card: PanelContainer = PanelContainer.new()
    card.add_theme_stylebox_override("panel", _tree_node_style_v72(maxed, can_unlock, rank > 0))
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.custom_minimum_size = Vector2(0, 142 if compact else 172)
    parent.add_child(card)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 9)
    margin.add_theme_constant_override("margin_bottom", 9)
    card.add_child(margin)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    margin.add_child(box)

    var title: Label = Label.new()
    title.text = "%s  %d/%d" % [str(data.get("name", talent_id)).to_upper(), rank, max_rank]
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title.add_theme_font_size_override("font_size", 14 if compact else 13)
    box.add_child(title)

    var branch: Label = Label.new()
    if required_name.is_empty():
        branch.text = "ROOT NODE  •  LV %d" % min_level
    else:
        branch.text = "← %s %d  •  LV %d" % [required_name.to_upper(), required_rank, min_level]
    branch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    branch.add_theme_font_size_override("font_size", 11)
    branch.add_theme_color_override("font_color", Color(0.62, 0.70, 0.76, 1.0))
    box.add_child(branch)

    var description: Label = Label.new()
    description.text = str(data.get("description", ""))
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.size_flags_vertical = Control.SIZE_EXPAND_FILL
    description.add_theme_font_size_override("font_size", 12)
    box.add_child(description)

    var button: Button = Button.new()
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(0, 38)
    if maxed:
        button.text = "MAXED"
    elif not level_ok:
        button.text = "LOCKED • LV %d" % min_level
    elif not required_ok:
        button.text = "LOCKED • PREREQUISITE"
    elif points_available <= 0:
        button.text = "NEED TALENT POINT"
    elif rank > 0:
        button.text = "+ RANK"
    else:
        button.text = "UNLOCK"
    button.disabled = not can_unlock
    button.pressed.connect(_unlock_talent_v68.bind(talent_id))
    box.add_child(button)

func _tree_node_style_v72(maxed: bool, available: bool, invested: bool) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    if maxed:
        style.bg_color = Color(0.055, 0.10, 0.08, 0.96)
        style.border_color = Color(0.38, 0.68, 0.52, 0.82)
    elif available:
        style.bg_color = Color(0.075, 0.085, 0.10, 0.98)
        style.border_color = Color(0.52, 0.66, 0.78, 0.90)
    elif invested:
        style.bg_color = Color(0.055, 0.065, 0.08, 0.96)
        style.border_color = Color(0.38, 0.50, 0.60, 0.72)
    else:
        style.bg_color = Color(0.026, 0.031, 0.038, 0.96)
        style.border_color = Color(0.25, 0.29, 0.34, 0.62)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 7
    style.corner_radius_top_right = 7
    style.corner_radius_bottom_left = 7
    style.corner_radius_bottom_right = 7
    return style

func _select_talent_tree_v72(tree_name: String) -> void:
    active_talent_tree_v72 = tree_name.to_upper()
    last_signature = ""
    _refresh_v68()

func _talent_tree_compact_v72() -> bool:
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    return viewport.x < 800.0 or _mobile_v68()

func get_progression_menu_tree_contract_v72() -> Dictionary:
    return {
        "talents_render_as_tree": true,
        "tree_selector": true,
        "tiered_prerequisite_nodes": true,
        "desktop_horizontal": true,
        "mobile_vertical": true,
        "uses_existing_unlock_api": true,
        "input_lock_retained": true,
        "v071_safe_hud_contract_retained": true
    }
