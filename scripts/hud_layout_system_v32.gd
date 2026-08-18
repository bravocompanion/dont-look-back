extends Node

const MENU_SCENES: Array[String] = [
    "res://scenes/main_menu.tscn",
    "res://scenes/main_menu_ranger.tscn"
]

const STAT_ORDER: Array[String] = ["health", "hunger", "thirst", "stamina", "battery", "darkness"]
const STAT_LABELS_DESKTOP: Dictionary = {
    "health": "HEALTH",
    "hunger": "HUNGER",
    "thirst": "THIRST",
    "stamina": "STAMINA",
    "battery": "BATTERY",
    "darkness": "DARKNESS"
}
const STAT_LABELS_MOBILE: Dictionary = {
    "health": "HP",
    "hunger": "FOOD",
    "thirst": "H2O",
    "stamina": "STA",
    "battery": "BATT",
    "darkness": "DARK"
}

var tracked_player_id: int = 0
var tracked_scene_id: int = 0
var tracked_player: CharacterBody3D
var tracked_hud: CanvasLayer
var top_bar: PanelContainer
var top_row: HBoxContainer
var stat_labels: Dictionary = {}
var stat_bars: Dictionary = {}
var layout_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Player.gd and the shelter/journal systems still apply their legacy layout
    # during the frame. Run afterwards so v0.32 owns the final HUD positions.
    process_priority = 120

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path in MENU_SCENES:
        _release_player()
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != tracked_scene_id:
        tracked_scene_id = scene_id
        tracked_player_id = 0
        tracked_player = null
        tracked_hud = null
        top_bar = null
        top_row = null
        stat_labels.clear()
        stat_bars.clear()

    _bind_player()
    if tracked_player == null or not is_instance_valid(tracked_player) or tracked_hud == null:
        return

    var journal_open: bool = _is_journal_open()
    tracked_hud.visible = not journal_open
    if journal_open:
        _layout_journal()
        return

    _ensure_top_status_bar()
    _hide_legacy_survival_panel()
    _update_status_values()

    layout_timer -= delta
    if layout_timer <= 0.0:
        layout_timer = 0.12
        _apply_gameplay_layout()
        _layout_journal()

func _bind_player() -> void:
    var player: CharacterBody3D = _find_local_player()
    if player == null:
        return
    var player_id: int = int(player.get_instance_id())
    if player_id == tracked_player_id and player == tracked_player and tracked_hud != null:
        return

    tracked_player = player
    tracked_player_id = player_id
    tracked_hud = player.get_node_or_null("HUD") as CanvasLayer
    top_bar = null
    top_row = null
    stat_labels.clear()
    stat_bars.clear()
    if tracked_hud != null:
        tracked_hud.visible = true
        _ensure_top_status_bar()
        _hide_legacy_survival_panel()
        _apply_gameplay_layout()

func _release_player() -> void:
    if tracked_hud != null and is_instance_valid(tracked_hud):
        tracked_hud.visible = true
    tracked_player = null
    tracked_hud = null
    tracked_player_id = 0
    tracked_scene_id = 0
    top_bar = null
    top_row = null
    stat_labels.clear()
    stat_bars.clear()

func _find_local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D
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

func _ensure_top_status_bar() -> void:
    if tracked_hud == null:
        return
    if top_bar != null and is_instance_valid(top_bar):
        return

    top_bar = tracked_hud.get_node_or_null("TopStatusBarV32") as PanelContainer
    if top_bar == null:
        top_bar = PanelContainer.new()
        top_bar.name = "TopStatusBarV32"
        top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        top_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.030, 0.035, 0.84), 8))
        tracked_hud.add_child(top_bar)

        top_row = HBoxContainer.new()
        top_row.name = "StatusRow"
        top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        top_row.add_theme_constant_override("separation", 4)
        top_bar.add_child(top_row)

        for stat_id: String in STAT_ORDER:
            _add_stat_cell(stat_id)
    else:
        top_row = top_bar.get_node_or_null("StatusRow") as HBoxContainer
        if top_row != null:
            for child: Node in top_row.get_children():
                var cell: VBoxContainer = child as VBoxContainer
                if cell == null:
                    continue
                var stat_id: String = str(cell.get_meta("stat_id", ""))
                if stat_id.is_empty():
                    continue
                var label: Label = cell.get_node_or_null("Value") as Label
                var bar: ProgressBar = cell.get_node_or_null("Bar") as ProgressBar
                if label != null:
                    stat_labels[stat_id] = label
                if bar != null:
                    stat_bars[stat_id] = bar

func _add_stat_cell(stat_id: String) -> void:
    if top_row == null:
        return
    var cell: VBoxContainer = VBoxContainer.new()
    cell.name = StringName("Stat_%s" % stat_id.capitalize())
    cell.set_meta("stat_id", stat_id)
    cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cell.add_theme_constant_override("separation", 1)
    top_row.add_child(cell)

    var label: Label = Label.new()
    label.name = "Value"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    cell.add_child(label)
    stat_labels[stat_id] = label

    var bar: ProgressBar = ProgressBar.new()
    bar.name = "Bar"
    bar.min_value = 0.0
    bar.max_value = 100.0
    bar.value = 100.0
    bar.show_percentage = false
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.custom_minimum_size = Vector2(0.0, 7.0)
    cell.add_child(bar)
    stat_bars[stat_id] = bar

func _hide_legacy_survival_panel() -> void:
    if tracked_hud == null:
        return
    var legacy: Control = tracked_hud.get_node_or_null("SurvivalPanel") as Control
    if legacy != null:
        legacy.visible = false

func _update_status_values() -> void:
    if tracked_player == null:
        return

    var values: Dictionary = {
        "health": float(tracked_player.get("health")),
        "hunger": float(tracked_player.get("hunger")),
        "thirst": float(tracked_player.get("thirst")),
        "stamina": float(tracked_player.get("stamina")),
        "battery": float(tracked_player.get("flashlight_battery")),
        "darkness": float(tracked_player.get("darkness_exposure"))
    }
    var max_health: float = maxf(1.0, float(tracked_player.get("max_health")))
    var mobile: bool = _is_mobile_layout()

    for stat_id: String in STAT_ORDER:
        var label: Label = stat_labels.get(stat_id) as Label
        var bar: ProgressBar = stat_bars.get(stat_id) as ProgressBar
        var value: float = float(values.get(stat_id, 0.0))
        if bar != null:
            bar.max_value = max_health if stat_id == "health" else 100.0
            bar.value = value
        if label != null:
            var title: String = str((STAT_LABELS_MOBILE if mobile else STAT_LABELS_DESKTOP).get(stat_id, stat_id.to_upper()))
            label.text = "%s %d" % [title, int(round(value))]

func _apply_gameplay_layout() -> void:
    if tracked_player == null or tracked_hud == null:
        return
    _ensure_top_status_bar()
    _hide_legacy_survival_panel()

    var size: Vector2 = tracked_player.get_viewport().get_visible_rect().size
    var mobile: bool = _is_mobile_layout()
    var compact: bool = mobile or size.x < 800.0
    var margin: float = 5.0 if compact else 16.0
    var bar_height: float = 46.0 if compact else 52.0

    if top_bar != null:
        top_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
        top_bar.position = Vector2(margin, margin)
        top_bar.size = Vector2(maxf(220.0, size.x - margin * 2.0), bar_height)
        top_bar.visible = not bool(tracked_player.get("is_dead"))
        top_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.030, 0.035, 0.86), 7 if compact else 9))

    if top_row != null:
        top_row.add_theme_constant_override("separation", 2 if compact else 5)

    for stat_id: String in STAT_ORDER:
        var label: Label = stat_labels.get(stat_id) as Label
        var bar: ProgressBar = stat_bars.get(stat_id) as ProgressBar
        if label != null:
            label.add_theme_font_size_override("font_size", 9 if compact else 13)
        if bar != null:
            bar.custom_minimum_size = Vector2(0.0, 6.0 if compact else 8.0)

    var objective: Label = tracked_player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.set_anchors_preset(Control.PRESET_TOP_LEFT)
        objective.position = Vector2(10.0 if compact else 24.0, bar_height + margin + 7.0)
        objective.size = Vector2(size.x - (20.0 if compact else 48.0), 42.0 if compact else 44.0)
        objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        objective.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        objective.add_theme_font_size_override("font_size", 14 if compact else 19)

    var case_file: Label = tracked_player.get_node_or_null("HUD/CaseFile") as Label
    if case_file != null:
        case_file.set_anchors_preset(Control.PRESET_TOP_LEFT)
        case_file.position = Vector2(10.0 if compact else 24.0, bar_height + margin + 50.0)
        case_file.size = Vector2(size.x - (20.0 if compact else 48.0), 24.0)
        case_file.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        case_file.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        case_file.add_theme_font_size_override("font_size", 10 if compact else 13)

    var shelter_status: Label = tracked_player.get_node_or_null("HUD/ShelterStatus") as Label
    if shelter_status != null:
        shelter_status.set_anchors_preset(Control.PRESET_TOP_LEFT)
        shelter_status.position = Vector2(10.0 if compact else size.x * 0.32, bar_height + margin + 76.0)
        shelter_status.size = Vector2(size.x - 20.0 if compact else size.x * 0.36, 24.0)
        shelter_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        shelter_status.add_theme_font_size_override("font_size", 10 if compact else 13)

    var panic: Label = tracked_player.get_node_or_null("HUD/PanicLabel") as Label
    if panic != null:
        panic.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        panic.position = Vector2(-112.0 if compact else -190.0, bar_height + margin + 76.0)
        panic.size = Vector2(102.0 if compact else 166.0, 24.0)
        panic.add_theme_font_size_override("font_size", 12 if compact else 16)
        panic.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    var inventory: Label = tracked_player.get_node_or_null("HUD/InventoryLabel") as Label
    if inventory != null:
        inventory.set_anchors_preset(Control.PRESET_TOP_LEFT)
        inventory.position = Vector2(10.0 if compact else 24.0, bar_height + margin + (105.0 if compact else 110.0))
        inventory.size = Vector2(190.0 if compact else 310.0, 150.0)
        inventory.add_theme_font_size_override("font_size", 11 if compact else 14)

    var interaction: Label = tracked_player.get_node_or_null("HUD/InteractionHint") as Label
    if interaction != null:
        interaction.set_anchors_preset(Control.PRESET_TOP_LEFT)
        var hint_width: float = minf(size.x - 24.0, 520.0 if compact else 620.0)
        var hint_y: float = size.y * 0.50 if compact else size.y - 116.0
        interaction.position = Vector2((size.x - hint_width) * 0.5, hint_y)
        interaction.size = Vector2(hint_width, 44.0)
        interaction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        interaction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        interaction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        interaction.add_theme_font_size_override("font_size", 14 if compact else 18)

    var controls: Label = tracked_player.get_node_or_null("HUD/Controls") as Label
    if controls != null:
        controls.visible = not mobile
        if not mobile:
            controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
            controls.position = Vector2(24.0, -36.0)
            controls.size = Vector2(minf(900.0, size.x - 48.0), 28.0)
            controls.add_theme_font_size_override("font_size", 13)

    _layout_mobile_journal_button(size, compact)

func _layout_mobile_journal_button(viewport_size: Vector2, compact: bool) -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var button: Button = journal.get("journal_button") as Button
    if button == null or not button.visible:
        return
    button.set_anchors_preset(Control.PRESET_TOP_LEFT)
    button.position = Vector2(10.0, 262.0 if compact else 180.0)
    button.size = Vector2(92.0, 38.0)
    button.add_theme_font_size_override("font_size", 12)
    if button.position.y + button.size.y > viewport_size.y * 0.45:
        button.position.y = maxf(190.0, viewport_size.y * 0.36)

func _layout_journal() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var panel: PanelContainer = journal.get("journal_panel") as PanelContainer
    if panel == null:
        return

    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = _is_mobile_layout() or size.x < 800.0
    panel.set_anchors_preset(Control.PRESET_CENTER)
    if compact:
        var width: float = maxf(280.0, size.x - 20.0)
        var height: float = maxf(380.0, size.y - 52.0)
        panel.position = Vector2(-width * 0.5, -height * 0.5)
        panel.size = Vector2(width, height)
    else:
        var width_desktop: float = minf(760.0, size.x - 80.0)
        var height_desktop: float = minf(600.0, size.y - 80.0)
        panel.position = Vector2(-width_desktop * 0.5, -height_desktop * 0.5)
        panel.size = Vector2(width_desktop, height_desktop)

    var mission: Label = journal.get("mission_label") as Label
    if mission != null:
        mission.add_theme_font_size_override("font_size", 12 if compact else 15)
        mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var heading: Label = journal.get("entry_heading") as Label
    if heading != null:
        heading.add_theme_font_size_override("font_size", 14 if compact else 17)
    var body: RichTextLabel = journal.get("entry_body") as RichTextLabel
    if body != null:
        body.custom_minimum_size = Vector2(0.0, 150.0 if compact else 220.0)
        body.add_theme_font_size_override("normal_font_size", 13 if compact else 15)

func _is_journal_open() -> bool:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    return journal != null and journal.has_method("is_open") and bool(journal.call("is_open"))

func _is_mobile_layout() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active")):
        return true
    return get_viewport().get_visible_rect().size.x < 800.0

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = Color(0.75, 0.78, 0.78, 0.16)
    style.content_margin_left = 7.0
    style.content_margin_right = 7.0
    style.content_margin_top = 4.0
    style.content_margin_bottom = 4.0
    return style
