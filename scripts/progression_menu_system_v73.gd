extends "res://scripts/progression_menu_system_v72_runtime.gd"

const TALENT_GRAPH_SCRIPT_V73: Script = preload("res://scripts/talent_tree_graph_v73.gd")

var selected_talent_by_tree_v73: Dictionary = {}

func _build_talents_tab_v68(progression: Node, player_level: int, points_available: int) -> void:
    _add_section_v68("TALENT TREE — %d POINTS AVAILABLE" % points_available)
    _add_info_v68("Select a node to inspect it. Bright branch lines show satisfied prerequisites; invested paths become stronger. Unlocking still requires the explicit action below.", 13)

    var tree_names: Array = Array(progression.call("get_talent_tree_names_v72")) if progression.has_method("get_talent_tree_names_v72") else ["SURVIVAL", "SCOUT", "TECHNICIAN", "INVESTIGATOR"]
    if active_talent_tree_v72 not in tree_names and not tree_names.is_empty():
        active_talent_tree_v72 = str(tree_names[0])
    _build_tree_selector_v72(tree_names)

    var selected_id: String = str(selected_talent_by_tree_v73.get(active_talent_tree_v72, ""))
    if selected_id.is_empty() or str(progression.call("get_talent_definition_v68", selected_id).get("tree", "")).to_upper() != active_talent_tree_v72:
        selected_id = _default_selected_talent_v73(progression, active_talent_tree_v72)
        selected_talent_by_tree_v73[active_talent_tree_v72] = selected_id

    var graph: Control = TALENT_GRAPH_SCRIPT_V73.new() as Control
    graph.name = "TalentTreeGraphV73"
    graph.call("configure_v73", progression, active_talent_tree_v72, _talent_tree_compact_v72(), selected_id)
    graph.connect("talent_selected_v73", Callable(self, "_select_visual_talent_v73"))
    content.add_child(graph)

    _build_selected_talent_detail_v73(progression, selected_id, player_level, points_available)

func _build_selected_talent_detail_v73(progression: Node, talent_id: String, player_level: int, points_available: int) -> void:
    if talent_id.is_empty():
        _add_info_v68("No talent node selected.", 14)
        return
    var data: Dictionary = Dictionary(progression.call("get_talent_definition_v68", talent_id))
    var state: Dictionary = Dictionary(progression.call("get_talent_tree_node_state_v72", talent_id))
    if data.is_empty() or state.is_empty():
        _add_info_v68("Selected talent data unavailable.", 14)
        return

    var rank: int = int(state.get("rank", 0))
    var max_rank: int = maxi(1, int(state.get("max_rank", data.get("max_rank", 1))))
    var min_level: int = int(state.get("min_level", data.get("min_level", 1)))
    var required_name: String = str(state.get("required_name", ""))
    var required_rank: int = int(state.get("required_rank", 0))
    var maxed: bool = bool(state.get("maxed", rank >= max_rank))
    var level_ok: bool = bool(state.get("level_ok", player_level >= min_level))
    var requirement_ok: bool = bool(state.get("required_ok", true))
    var can_unlock: bool = bool(state.get("can_unlock", false))

    var panel_detail: PanelContainer = PanelContainer.new()
    panel_detail.add_theme_stylebox_override("panel", _tree_node_style_v72(maxed, can_unlock, rank > 0))
    content.add_child(panel_detail)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel_detail.add_child(margin)

    var compact: bool = _talent_tree_compact_v72()
    var body: Container
    if compact:
        var vertical: VBoxContainer = VBoxContainer.new()
        vertical.add_theme_constant_override("separation", 8)
        body = vertical
    else:
        var horizontal: HBoxContainer = HBoxContainer.new()
        horizontal.add_theme_constant_override("separation", 14)
        body = horizontal
    margin.add_child(body)

    var icon: TextureRect = TextureRect.new()
    icon.custom_minimum_size = Vector2(82, 82)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var registry: Node = get_node_or_null("/root/TalentIconRegistry")
    if registry != null and registry.has_method("get_talent_icon_v73"):
        icon.texture = registry.call("get_talent_icon_v73", talent_id) as Texture2D
    body.add_child(icon)

    var info_box: VBoxContainer = VBoxContainer.new()
    info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_box.add_theme_constant_override("separation", 4)
    body.add_child(info_box)

    var title: Label = Label.new()
    title.text = "%s  %d/%d" % [str(data.get("name", talent_id)).to_upper(), rank, max_rank]
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title.add_theme_font_size_override("font_size", 17)
    info_box.add_child(title)

    var gate: Label = Label.new()
    gate.text = "%s • LEVEL %d" % [str(data.get("tree", active_talent_tree_v72)), min_level]
    if not required_name.is_empty():
        gate.text += " • REQUIRES %s %d" % [required_name.to_upper(), required_rank]
    gate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    gate.add_theme_font_size_override("font_size", 11)
    gate.add_theme_color_override("font_color", Color(0.62, 0.70, 0.76, 1.0))
    info_box.add_child(gate)

    var description: Label = Label.new()
    description.text = str(data.get("description", ""))
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.add_theme_font_size_override("font_size", 13)
    info_box.add_child(description)

    var action: Button = Button.new()
    action.focus_mode = Control.FOCUS_NONE
    action.custom_minimum_size = Vector2(0, 42)
    if maxed:
        action.text = "MAXED"
    elif not level_ok:
        action.text = "LOCKED • REQUIRES LEVEL %d" % min_level
    elif not requirement_ok:
        action.text = "LOCKED • PREREQUISITE NOT MET"
    elif points_available <= 0:
        action.text = "NEED TALENT POINT"
    elif rank > 0:
        action.text = "+ RANK  •  SPEND 1 TALENT POINT"
    else:
        action.text = "UNLOCK  •  SPEND 1 TALENT POINT"
    action.disabled = not can_unlock
    action.pressed.connect(_unlock_selected_talent_v73.bind(talent_id))
    info_box.add_child(action)

func _default_selected_talent_v73(progression: Node, tree_name: String) -> String:
    var tiers: Array = Array(progression.call("get_talent_tree_tiers_v72", tree_name)) if progression.has_method("get_talent_tree_tiers_v72") else []
    var first_id: String = ""
    var first_invested: String = ""
    for tier_value: Variant in tiers:
        if not (tier_value is Dictionary):
            continue
        for talent_value: Variant in Array(Dictionary(tier_value).get("talents", [])):
            var talent_id: String = str(talent_value)
            if first_id.is_empty():
                first_id = talent_id
            var state: Dictionary = Dictionary(progression.call("get_talent_tree_node_state_v72", talent_id))
            if bool(state.get("can_unlock", false)):
                return talent_id
            if first_invested.is_empty() and int(state.get("rank", 0)) > 0:
                first_invested = talent_id
    return first_invested if not first_invested.is_empty() else first_id

func _select_visual_talent_v73(talent_id: String) -> void:
    selected_talent_by_tree_v73[active_talent_tree_v72] = talent_id
    last_signature = ""
    _refresh_v68()

func _select_talent_tree_v72(tree_name: String) -> void:
    active_talent_tree_v72 = tree_name.to_upper()
    last_signature = ""
    _refresh_v68()

func _unlock_selected_talent_v73(talent_id: String) -> void:
    selected_talent_by_tree_v73[active_talent_tree_v72] = talent_id
    _unlock_talent_v68(talent_id)

func get_progression_menu_visual_tree_contract_v73() -> Dictionary:
    return {
        "graph_control": "talent_tree_graph_v73.gd",
        "true_parent_child_lines": true,
        "unique_icon_per_talent_node": true,
        "node_click_selects_only": true,
        "explicit_unlock_button": true,
        "long_description_moved_to_detail_panel": true,
        "flat_text_card_tree_replaced": true,
        "uses_existing_unlock_api": true,
        "v071_input_lock_retained": true,
        "v072_responsive_breakpoint_retained": true,
        "mobile_responsive": true,
        "desktop_responsive": true
    }
