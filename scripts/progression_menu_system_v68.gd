extends Node

const LOCK_REASON: String = "PROGRESSION_MENU_V68"
const TAB_OVERVIEW: String = "OVERVIEW"
const TAB_STATS: String = "STATS"
const TAB_TALENTS: String = "TALENTS"
const TAB_KNOWLEDGE: String = "KNOWLEDGE"

var active_player: CharacterBody3D
var layer: CanvasLayer
var overlay: ColorRect
var panel: PanelContainer
var title_label: Label
var subtitle_label: Label
var tab_row: HBoxContainer
var content: VBoxContainer
var open_button: Button
var menu_open: bool = false
var active_tab: String = TAB_OVERVIEW
var probe_timer: float = 0.0
var layout_timer: float = 0.0
var last_signature: String = ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 620
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null:
        var change_callback: Callable = Callable(self, "_on_progression_changed_v68")
        var feedback_callback: Callable = Callable(self, "_on_progression_feedback_v68")
        if progression.has_signal("progression_changed") and not progression.is_connected("progression_changed", change_callback):
            progression.connect("progression_changed", change_callback)
        if progression.has_signal("progression_feedback") and not progression.is_connected("progression_feedback", feedback_callback):
            progression.connect("progression_feedback", feedback_callback)
    call_deferred("_bind_player_v68")

func _process(delta: float) -> void:
    probe_timer -= delta
    if probe_timer <= 0.0:
        probe_timer = 0.30
        _bind_player_v68()
    if active_player == null or layer == null:
        return
    if menu_open and _blocked_elsewhere_v68():
        _set_open_v68(false)
    if open_button != null:
        open_button.visible = not menu_open and not _blocked_elsewhere_v68()
    if menu_open:
        var signature: String = _signature_v68()
        if signature != last_signature:
            last_signature = signature
            _refresh_v68()
    layout_timer -= delta
    if layout_timer <= 0.0:
        layout_timer = 0.35
        _layout_v68()

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    if menu_open and key_event.physical_keycode == KEY_ESCAPE:
        _set_open_v68(false)
        get_viewport().set_input_as_handled()
        return
    if key_event.physical_keycode != KEY_P:
        return
    if menu_open:
        _set_open_v68(false)
        get_viewport().set_input_as_handled()
    elif not _blocked_elsewhere_v68():
        _set_open_v68(true)
        get_viewport().set_input_as_handled()

func is_open() -> bool:
    return menu_open

func _bind_player_v68() -> void:
    var candidate: CharacterBody3D = _local_player_v68()
    if candidate == active_player and layer != null and is_instance_valid(layer):
        return
    if menu_open:
        _set_open_v68(false)
    if layer != null and is_instance_valid(layer):
        layer.queue_free()
    active_player = candidate
    layer = null
    overlay = null
    panel = null
    open_button = null
    content = null
    if active_player != null:
        _build_ui_v68()

func _build_ui_v68() -> void:
    layer = CanvasLayer.new()
    layer.name = "ProgressionMenuV68"
    layer.layer = 118
    add_child(layer)

    overlay = ColorRect.new()
    overlay.color = Color(0.0, 0.0, 0.0, 0.76)
    overlay.visible = false
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(overlay)

    open_button = Button.new()
    open_button.name = "ProgressionButton"
    open_button.text = "PROG" if _mobile_v68() else "P"
    open_button.tooltip_text = "Level / Stats / Talents / Knowledge"
    open_button.focus_mode = Control.FOCUS_NONE
    open_button.pressed.connect(_open_pressed_v68)
    layer.add_child(open_button)

    panel = PanelContainer.new()
    panel.visible = false
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    panel.add_theme_stylebox_override("panel", _panel_style_v68())
    layer.add_child(panel)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(margin)

    var root_box: VBoxContainer = VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 9)
    margin.add_child(root_box)

    var header: HBoxContainer = HBoxContainer.new()
    root_box.add_child(header)
    title_label = Label.new()
    title_label.text = "SURVIVOR PROGRESSION"
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_font_size_override("font_size", 25)
    header.add_child(title_label)
    var close_button: Button = Button.new()
    close_button.text = "CLOSE"
    close_button.custom_minimum_size = Vector2(92, 40)
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.pressed.connect(_close_pressed_v68)
    header.add_child(close_button)

    subtitle_label = Label.new()
    subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle_label.add_theme_font_size_override("font_size", 13)
    subtitle_label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.78, 1.0))
    root_box.add_child(subtitle_label)

    tab_row = HBoxContainer.new()
    tab_row.add_theme_constant_override("separation", 6)
    root_box.add_child(tab_row)
    var tabs: Array[String] = [TAB_OVERVIEW, TAB_STATS, TAB_TALENTS, TAB_KNOWLEDGE]
    for tab_name: String in tabs:
        var tab_button: Button = Button.new()
        tab_button.text = tab_name
        tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab_button.focus_mode = Control.FOCUS_NONE
        tab_button.pressed.connect(_select_tab_v68.bind(tab_name))
        tab_row.add_child(tab_button)

    root_box.add_child(HSeparator.new())
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root_box.add_child(scroll)

    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 8)
    scroll.add_child(content)

    var footer: Label = Label.new()
    footer.text = "Progression improves preparation, information and efficiency — threats never become harmless."
    footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 12)
    footer.add_theme_color_override("font_color", Color(0.58, 0.62, 0.68, 1.0))
    root_box.add_child(footer)

    _layout_v68()
    _refresh_v68()

func _refresh_v68() -> void:
    if content == null:
        return
    for child: Node in content.get_children():
        child.queue_free()
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression == null or not progression.has_method("get_progression_summary_v68"):
        _add_info_v68("Progression system unavailable.", 16)
        return
    var summary: Dictionary = Dictionary(progression.call("get_progression_summary_v68"))
    var level: int = int(summary.get("level", 1))
    var xp: int = int(summary.get("xp", 0))
    var next_xp: int = int(summary.get("xp_to_next", 0))
    var tp: int = int(summary.get("talent_points", 0))
    var sp: int = int(summary.get("stat_points", 0))
    subtitle_label.text = "LEVEL %d  •  XP %s  •  TALENT POINTS %d  •  STAT POINTS %d" % [level, "MAX" if next_xp <= 0 else "%d/%d" % [xp, next_xp], tp, sp]
    match active_tab:
        TAB_STATS:
            _build_stats_tab_v68(progression, sp)
        TAB_TALENTS:
            _build_talents_tab_v68(progression, level, tp)
        TAB_KNOWLEDGE:
            _build_knowledge_tab_v68(progression)
        _:
            _build_overview_tab_v68(progression, summary)

func _build_overview_tab_v68(progression: Node, summary: Dictionary) -> void:
    _add_section_v68("LEVELING")
    var level: int = int(summary.get("level", 1))
    var xp: int = int(summary.get("xp", 0))
    var next_xp: int = int(summary.get("xp_to_next", 0))
    _add_info_v68("Level %d / 30\n%s" % [level, "Maximum survivor experience reached." if next_xp <= 0 else "%d XP / %d XP to next level" % [xp, next_xp]], 18)
    if next_xp > 0:
        var bar: ProgressBar = ProgressBar.new()
        bar.min_value = 0.0
        bar.max_value = float(next_xp)
        bar.value = float(xp)
        bar.show_percentage = true
        bar.custom_minimum_size = Vector2(0, 30)
        content.add_child(bar)

    _add_section_v68("BUILD SUMMARY")
    var stats_dict: Dictionary = Dictionary(summary.get("stats", {}))
    var stat_parts: PackedStringArray = PackedStringArray()
    var stat_ids: Array = Array(progression.call("get_stat_ids_v68")) if progression.has_method("get_stat_ids_v68") else []
    for stat_variant: Variant in stat_ids:
        var stat_id: String = str(stat_variant)
        stat_parts.append("%s %d" % [str(progression.call("get_stat_name_v68", stat_id)), int(stats_dict.get(stat_id, 0))])
    _add_info_v68(" • ".join(stat_parts), 14)

    var talents: Dictionary = Dictionary(summary.get("talents", {}))
    var invested: int = 0
    for value: Variant in talents.values():
        invested += int(value)
    _add_info_v68("Talent ranks invested: %d\nKnowledge: %d / %d" % [invested, int(summary.get("knowledge_count", 0)), int(summary.get("knowledge_total", 0))], 14)

    _add_section_v68("XP SOURCES")
    _add_info_v68("Explore new maps • log evidence • synthesize clues • first-time crafting • repair/start shelter power • revive teammates • survive nights.\nNormal resource farming and threat kills do not generate repeatable XP.", 14)

func _build_stats_tab_v68(progression: Node, points_available: int) -> void:
    _add_section_v68("CORE STATS — %d POINTS AVAILABLE" % points_available)
    var stat_ids: Array = Array(progression.call("get_stat_ids_v68")) if progression.has_method("get_stat_ids_v68") else []
    var max_stat: int = int(progression.call("get_max_stat_value_v68")) if progression.has_method("get_max_stat_value_v68") else 15
    for stat_variant: Variant in stat_ids:
        var stat_id: String = str(stat_variant)
        var value: int = int(progression.call("get_stat_v68", stat_id))
        var row_panel: PanelContainer = _new_row_panel_v68()
        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        row_panel.add_child(row)
        var info: Label = Label.new()
        info.text = "%s  %d/%d\n%s" % [str(progression.call("get_stat_name_v68", stat_id)).to_upper(), value, max_stat, str(progression.call("get_stat_description_v68", stat_id))]
        info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var add_button: Button = Button.new()
        add_button.text = "+1"
        add_button.custom_minimum_size = Vector2(64, 42)
        add_button.focus_mode = Control.FOCUS_NONE
        add_button.disabled = points_available <= 0 or value >= max_stat
        add_button.pressed.connect(_spend_stat_v68.bind(stat_id))
        row.add_child(add_button)

func _build_talents_tab_v68(progression: Node, player_level: int, points_available: int) -> void:
    _add_section_v68("TALENT TREES — %d POINTS AVAILABLE" % points_available)
    var talent_order: Array = Array(progression.call("get_talent_order_v68")) if progression.has_method("get_talent_order_v68") else []
    var trees: Array[String] = ["SURVIVAL", "SCOUT", "TECHNICIAN", "INVESTIGATOR"]
    for tree_name: String in trees:
        _add_subsection_v68(tree_name)
        for talent_variant: Variant in talent_order:
            var talent_id: String = str(talent_variant)
            var data: Dictionary = Dictionary(progression.call("get_talent_definition_v68", talent_id))
            if str(data.get("tree", "")) != tree_name:
                continue
            var rank: int = int(progression.call("get_talent_rank_v68", talent_id))
            var max_rank: int = int(data.get("max_rank", 1))
            var min_level: int = int(data.get("min_level", 1))
            var requirement_ok: bool = true
            var requirement_text: String = ""
            var required: String = str(data.get("requires", ""))
            if not required.is_empty():
                var needed_rank: int = int(data.get("requires_rank", 1))
                var required_data: Dictionary = Dictionary(progression.call("get_talent_definition_v68", required))
                requirement_ok = int(progression.call("get_talent_rank_v68", required)) >= needed_rank
                requirement_text = " • requires %s %d" % [str(required_data.get("name", required)), needed_rank]
            var row_panel: PanelContainer = _new_row_panel_v68()
            var row: HBoxContainer = HBoxContainer.new()
            row.add_theme_constant_override("separation", 10)
            row_panel.add_child(row)
            var info: Label = Label.new()
            info.text = "%s  %d/%d  [Lv %d]%s\n%s" % [str(data.get("name", talent_id)).to_upper(), rank, max_rank, min_level, requirement_text, str(data.get("description", ""))]
            info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(info)
            var unlock_button: Button = Button.new()
            unlock_button.text = "MAX" if rank >= max_rank else "UNLOCK"
            unlock_button.custom_minimum_size = Vector2(92, 44)
            unlock_button.focus_mode = Control.FOCUS_NONE
            unlock_button.disabled = rank >= max_rank or points_available <= 0 or player_level < min_level or not requirement_ok
            unlock_button.pressed.connect(_unlock_talent_v68.bind(talent_id))
            row.add_child(unlock_button)

func _build_knowledge_tab_v68(progression: Node) -> void:
    var unlocked: Dictionary = Dictionary(progression.call("get_knowledge_v68"))
    var knowledge_order: Array = Array(progression.call("get_knowledge_order_v68")) if progression.has_method("get_knowledge_order_v68") else []
    _add_section_v68("KNOWLEDGE JOURNAL — %d / %d" % [unlocked.size(), knowledge_order.size()])
    var hint_level: int = int(progression.call("get_knowledge_hint_level_v68"))
    var categories: Array[String] = ["SURVIVAL", "TECHNOLOGY", "WILDLIFE", "WORLD", "THREAT", "ANOMALY"]
    for category: String in categories:
        var matching: Array[String] = []
        for knowledge_variant: Variant in knowledge_order:
            var knowledge_id: String = str(knowledge_variant)
            if not bool(unlocked.get(knowledge_id, false)):
                continue
            var data: Dictionary = Dictionary(progression.call("get_knowledge_definition_v68", knowledge_id))
            if str(data.get("category", "")) == category:
                matching.append(knowledge_id)
        if matching.is_empty():
            continue
        _add_subsection_v68(category)
        for knowledge_id: String in matching:
            var data: Dictionary = Dictionary(progression.call("get_knowledge_definition_v68", knowledge_id))
            var text: String = "%s\n%s" % [str(data.get("title", knowledge_id)).to_upper(), str(data.get("body", ""))]
            if hint_level >= 2:
                text += "\nANALYSIS: %s" % str(data.get("advanced", ""))
            _add_card_v68(text)

func _new_row_panel_v68() -> PanelContainer:
    var row_panel: PanelContainer = PanelContainer.new()
    row_panel.add_theme_stylebox_override("panel", _row_style_v68())
    content.add_child(row_panel)
    return row_panel

func _add_section_v68(text: String) -> void:
    var label: Label = Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 20)
    label.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95, 1.0))
    content.add_child(label)

func _add_subsection_v68(text: String) -> void:
    var label: Label = Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 16)
    label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.84, 1.0))
    content.add_child(label)

func _add_info_v68(text: String, font_size: int) -> void:
    var label: Label = Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", font_size)
    content.add_child(label)

func _add_card_v68(text: String) -> void:
    var card: PanelContainer = PanelContainer.new()
    card.add_theme_stylebox_override("panel", _row_style_v68())
    content.add_child(card)
    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    card.add_child(margin)
    var label: Label = Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 14)
    margin.add_child(label)

func _select_tab_v68(tab_name: String) -> void:
    active_tab = tab_name
    last_signature = ""
    _refresh_v68()

func _spend_stat_v68(stat_id: String) -> void:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("spend_stat_point_v68") and bool(progression.call("spend_stat_point_v68", stat_id)):
        last_signature = ""
        _refresh_v68()

func _unlock_talent_v68(talent_id: String) -> void:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("unlock_talent_v68") and bool(progression.call("unlock_talent_v68", talent_id)):
        last_signature = ""
        _refresh_v68()

func _open_pressed_v68() -> void:
    if not _blocked_elsewhere_v68():
        _set_open_v68(true)

func _close_pressed_v68() -> void:
    _set_open_v68(false)

func _set_open_v68(value: bool) -> void:
    if value and _blocked_elsewhere_v68():
        return
    if menu_open == value:
        return
    menu_open = value
    if overlay != null:
        overlay.visible = value
    if panel != null:
        panel.visible = value
    if open_button != null:
        open_button.visible = not value
    if value:
        active_tab = TAB_OVERVIEW
        last_signature = ""
        _acquire_lock_v68()
        _set_mobile_blocked_v68(true)
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        _refresh_v68()
    else:
        _release_lock_v68()
        _set_mobile_blocked_v68(false)
        if not _mobile_v68() and not _blocked_elsewhere_v68():
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _blocked_elsewhere_v68() -> bool:
    var front: Node = get_node_or_null("/root/FrontEndSystem")
    if front != null and bool(front.get("menu_open")):
        return true
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
        return true
    var stash: Node = get_node_or_null("/root/StashMenuSystem")
    if stash != null and stash.has_method("is_open") and bool(stash.call("is_open")):
        return true
    var status: Node = get_node_or_null("/root/FieldStatusMenuSystem")
    if status != null and status.has_method("is_open") and bool(status.call("is_open")):
        return true
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return true
    var inventory: Node = get_node_or_null("/root/SurvivalSystem/InventoryMenuRuntime")
    if inventory != null and inventory.has_method("is_open") and bool(inventory.call("is_open")):
        return true
    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition != null and bool(transition.get("transitioning")):
        return true
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null and bool(coop.get("local_downed")):
        return true
    return false

func _layout_v68() -> void:
    if panel == null or open_button == null or title_label == null:
        return
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = viewport.x < 800.0 or _mobile_v68()
    if compact:
        panel.size = Vector2(maxf(300.0, viewport.x - 20.0), maxf(380.0, viewport.y - 20.0))
        panel.position = Vector2(10, 10)
        open_button.size = Vector2(76, 46)
        open_button.position = Vector2(maxf(8.0, viewport.x - 86.0), 76.0)
        open_button.text = "PROG"
        title_label.add_theme_font_size_override("font_size", 20)
    else:
        panel.size = Vector2(minf(920.0, viewport.x - 80.0), minf(680.0, viewport.y - 60.0))
        panel.position = (viewport - panel.size) * 0.5
        open_button.size = Vector2(52, 42)
        open_button.position = Vector2(28, 222)
        open_button.text = "P"
        title_label.add_theme_font_size_override("font_size", 25)

func _signature_v68() -> String:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression == null or not progression.has_method("get_progression_summary_v68"):
        return "none"
    var summary: Dictionary = Dictionary(progression.call("get_progression_summary_v68"))
    return "%s|%s|%s|%s|%s|%s|%s|%s" % [
        active_tab,
        str(summary.get("level", 1)),
        str(summary.get("xp", 0)),
        str(summary.get("talent_points", 0)),
        str(summary.get("stat_points", 0)),
        str(summary.get("stats", {})),
        str(summary.get("talents", {})),
        str(summary.get("knowledge", {}))
    ]

func _on_progression_changed_v68() -> void:
    last_signature = ""

func _on_progression_feedback_v68(message: String) -> void:
    if active_player == null or message.is_empty():
        return
    var objective: Label = active_player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = message

func _acquire_lock_v68() -> void:
    var lock: Node = get_node_or_null("/root/GameplayInputLock")
    if lock != null and lock.has_method("acquire"):
        lock.call("acquire", LOCK_REASON)

func _release_lock_v68() -> void:
    var lock: Node = get_node_or_null("/root/GameplayInputLock")
    if lock != null and lock.has_method("release"):
        lock.call("release", LOCK_REASON)

func _set_mobile_blocked_v68(blocked: bool) -> void:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile != null and mobile.has_method("set_external_blocked"):
        mobile.call("set_external_blocked", blocked)

func _mobile_v68() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

func _local_player_v68() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null or player.get_node_or_null("HUD") == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback

func _panel_style_v68() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.024, 0.031, 0.98)
    style.border_color = Color(0.26, 0.31, 0.36, 1.0)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    return style

func _row_style_v68() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.045, 0.055, 0.066, 0.94)
    style.border_color = Color(0.16, 0.19, 0.23, 1.0)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 5
    style.corner_radius_top_right = 5
    style.corner_radius_bottom_left = 5
    style.corner_radius_bottom_right = 5
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style
