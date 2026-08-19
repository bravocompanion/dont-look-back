extends Node

# v0.39 unified field-status menu.
# Secondary live HUD writers are hidden and their data is presented here on demand.

const MENU_SCENES = [
    "res://scenes/main_menu.tscn",
    "res://scenes/main_menu_ranger.tscn"
]

var layer: CanvasLayer = null
var dim: ColorRect = null
var panel: PanelContainer = null
var status_button: Button = null
var case_label: Label = null
var environment_label: Label = null
var shelter_label: Label = null
var condition_label: Label = null
var coop_label: Label = null
var inventory_label: Label = null
var coop_lobby_button: Button = null
var inventory_button: Button = null
var close_button: Button = null
var menu_open: bool = false
var refresh_timer: float = 0.0
var previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 520
    _build_ui()

func _process(delta: float) -> void:
    var player: CharacterBody3D = _local_player()
    var gameplay: bool = _gameplay_active() and player != null

    _suppress_legacy_secondary_hud(player)

    if not gameplay:
        if menu_open:
            _set_menu_open(false)
        if status_button != null:
            status_button.visible = false
        return

    if status_button != null:
        status_button.visible = not _other_menu_open() or menu_open
        status_button.text = "CLOSE" if menu_open else ("STATUS" if _mobile_active() else "STATUS  [TAB]")

    _layout_ui()

    if menu_open:
        refresh_timer -= delta
        if refresh_timer <= 0.0:
            refresh_timer = 0.20
            _refresh_status(player)

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo or key_event.physical_keycode != KEY_TAB:
        return
    if not _gameplay_active() or _local_player() == null:
        return
    if not menu_open and _other_menu_open():
        return
    _set_menu_open(not menu_open)
    get_viewport().set_input_as_handled()

func is_open() -> bool:
    return menu_open

func toggle_menu() -> void:
    if menu_open:
        _set_menu_open(false)
    elif _gameplay_active() and not _other_menu_open():
        _set_menu_open(true)

func _set_menu_open(value: bool) -> void:
    menu_open = value
    if dim != null:
        dim.visible = value
    if panel != null:
        panel.visible = value
    if status_button != null:
        status_button.text = "CLOSE" if value else ("STATUS" if _mobile_active() else "STATUS  [TAB]")

    if value:
        previous_mouse_mode = Input.mouse_mode
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        refresh_timer = 0.0
        var player: CharacterBody3D = _local_player()
        if player != null:
            _refresh_status(player)
    elif not _mobile_active() and not _other_menu_open():
        Input.set_mouse_mode(previous_mouse_mode if previous_mouse_mode != Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_CAPTURED)

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "FieldStatusMenuUI"
    layer.layer = 72
    add_child(layer)

    dim = ColorRect.new()
    dim.name = "Dim"
    dim.color = Color(0.0, 0.0, 0.0, 0.70)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    dim.visible = false
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(dim)

    status_button = Button.new()
    status_button.name = "StatusButton"
    status_button.text = "STATUS  [TAB]"
    status_button.focus_mode = Control.FOCUS_NONE
    status_button.pressed.connect(toggle_menu)
    layer.add_child(status_button)

    panel = PanelContainer.new()
    panel.name = "FieldStatusPanel"
    panel.visible = false
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    panel.add_theme_stylebox_override("panel", _panel_style())
    layer.add_child(panel)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(margin)

    var root_box: VBoxContainer = VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 9)
    margin.add_child(root_box)

    var title: Label = Label.new()
    title.text = "FIELD STATUS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 25)
    root_box.add_child(title)

    var subtitle: Label = Label.new()
    subtitle.text = "Investigation, environment, shelter, condition and co-op data"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_color_override("font_color", Color(0.68, 0.72, 0.76, 1.0))
    root_box.add_child(subtitle)

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root_box.add_child(scroll)

    var content: VBoxContainer = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 12)
    scroll.add_child(content)

    case_label = _make_section_label(content)
    environment_label = _make_section_label(content)
    shelter_label = _make_section_label(content)
    condition_label = _make_section_label(content)
    coop_label = _make_section_label(content)
    inventory_label = _make_section_label(content)

    var actions: HBoxContainer = HBoxContainer.new()
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    actions.add_theme_constant_override("separation", 8)
    root_box.add_child(actions)

    inventory_button = Button.new()
    inventory_button.text = "INVENTORY"
    inventory_button.focus_mode = Control.FOCUS_NONE
    inventory_button.pressed.connect(_open_inventory)
    actions.add_child(inventory_button)

    coop_lobby_button = Button.new()
    coop_lobby_button.text = "CO-OP LOBBY"
    coop_lobby_button.focus_mode = Control.FOCUS_NONE
    coop_lobby_button.pressed.connect(_open_coop_lobby)
    actions.add_child(coop_lobby_button)

    close_button = Button.new()
    close_button.text = "CLOSE"
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.pressed.connect(_close_from_button)
    actions.add_child(close_button)

    var help: Label = Label.new()
    help.text = "TAB Status  •  I Inventory  •  J Journal  •  M Co-op"
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_font_size_override("font_size", 12)
    help.add_theme_color_override("font_color", Color(0.66, 0.69, 0.72, 1.0))
    root_box.add_child(help)

    _layout_ui()

func _make_section_label(parent: VBoxContainer) -> Label:
    var label: Label = Label.new()
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", 15)
    label.add_theme_color_override("font_color", Color(0.90, 0.91, 0.93, 1.0))
    parent.add_child(label)
    return label

func _panel_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.024, 0.032, 0.97)
    style.border_color = Color(0.40, 0.46, 0.53, 0.50)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    return style

func _layout_ui() -> void:
    if panel == null or status_button == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = _mobile_active() or size.x < 800.0

    status_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
    var button_width: float = 92.0 if compact else 116.0
    status_button.position = Vector2(size.x - button_width - (8.0 if compact else 18.0), 58.0 if compact else 76.0)
    status_button.size = Vector2(button_width, 34.0 if compact else 38.0)
    status_button.add_theme_font_size_override("font_size", 11 if compact else 13)

    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    if compact:
        var width: float = maxf(280.0, size.x - 20.0)
        var height: float = maxf(390.0, size.y - 36.0)
        panel.position = Vector2((size.x - width) * 0.5, (size.y - height) * 0.5)
        panel.size = Vector2(width, height)
    else:
        var width_desktop: float = minf(760.0, size.x - 80.0)
        var height_desktop: float = minf(590.0, size.y - 80.0)
        panel.position = Vector2((size.x - width_desktop) * 0.5, (size.y - height_desktop) * 0.5)
        panel.size = Vector2(width_desktop, height_desktop)

func _refresh_status(player: CharacterBody3D) -> void:
    if player == null:
        return

    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    var objective: String = "No active investigation objective."
    if investigation != null and investigation.has_method("get_current_objective"):
        objective = str(investigation.call("get_current_objective"))
    _set_label_text(case_label, "CASE / OBJECTIVE\n%s\nRoute: Ranger Forest → Old Mine → Labyrinth → Research Facility" % objective)

    _set_label_text(environment_label, _environment_text())
    _set_label_text(shelter_label, _shelter_text())

    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    var bleeding: int = 0
    var infection: int = 0
    if depth != null:
        if depth.has_method("get_bleeding"):
            bleeding = int(round(float(depth.call("get_bleeding"))))
        if depth.has_method("get_infection"):
            infection = int(round(float(depth.call("get_infection"))))
    var panic: int = int(round(float(player.get("flashlight_panic"))))
    _set_label_text(condition_label, "CONDITION\nBleeding %d%%  •  Infection %d%%  •  Panic %d%%" % [bleeding, infection, panic])

    _set_label_text(coop_label, _coop_text())
    _set_label_text(inventory_label, _inventory_text(player))

func _environment_text() -> String:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != "res://scenes/forest.tscn":
        return "ENVIRONMENT\nIndoor / underground map — forest clock and weather are not displayed here."

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var day: int = 1
    var hour: int = 0
    var minute: int = 0
    var phase: String = "DAY"
    var cold: int = 0
    if outside != null:
        day = int(outside.get("day_index"))
        var total_minutes: float = float(outside.get("game_minutes"))
        hour = int(floor(total_minutes / 60.0)) % 24
        minute = int(total_minutes) % 60
        cold = int(round(float(outside.get("cold_exposure"))))
        if outside.has_method("is_night") and bool(outside.call("is_night")):
            phase = "NIGHT"
        elif hour >= 17 or hour < 7:
            phase = "DUSK / DAWN"

    var weather: String = "CLEAR"
    var wet: int = 0
    var forest_runtime: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if forest_runtime != null:
        weather = str(forest_runtime.get("current_weather")).to_upper()
        wet = int(round(float(forest_runtime.get("wetness"))))

    return "ENVIRONMENT\nDay %d  •  %02d:%02d  •  %s  •  Cold %d%%\nWeather %s  •  Wet %d%%" % [day, hour, minute, phase, cold, weather, wet]

func _shelter_text() -> String:
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        return "SHELTER\nUnavailable on this map."

    var generator_percent: int = 0
    var campfire_percent: int = 0
    if shelter.has_method("get_generator_percent"):
        generator_percent = int(shelter.call("get_generator_percent"))
    if shelter.has_method("get_campfire_percent"):
        campfire_percent = int(shelter.call("get_campfire_percent"))

    var stored: int = 0
    var counts_value: Variant = shelter.get("storage_counts")
    if counts_value is Dictionary:
        var counts: Dictionary = counts_value
        for value: Variant in counts.values():
            stored += int(value)

    var generator_state: String = "OFF"
    if shelter.has_method("is_generator_running") and bool(shelter.call("is_generator_running")):
        generator_state = "ON"

    return "SHELTER\nGenerator %d%% (%s)  •  Campfire %d%%  •  Storage %d items" % [generator_percent, generator_state, campfire_percent, stored]

func _coop_text() -> String:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        return "CO-OP\nOffline / solo"
    if bool(network.get("connecting")):
        return "CO-OP\nConnecting..."
    if not network.has_method("is_online") or not bool(network.call("is_online")):
        return "CO-OP\nOffline / solo  •  Open CO-OP LOBBY to host or join."

    var remote_targets: Dictionary = Dictionary(network.get("remote_targets"))
    var survivors: int = remote_targets.size() + 1
    var role: String = "HOST" if network.has_method("is_server") and bool(network.call("is_server")) else "CLIENT"
    return "CO-OP\n%s  •  %d survivor(s) connected" % [role, survivors]

func _inventory_text(player: CharacterBody3D) -> String:
    var names: Dictionary = Dictionary(player.get("inventory_names"))
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    if names.is_empty():
        return "INVENTORY SUMMARY\n(empty)"

    var parts = []
    for key_variant: Variant in names.keys():
        var item_id: String = str(key_variant)
        parts.append("%s x%d" % [str(names.get(item_id, item_id.capitalize())), int(counts.get(item_id, 1))])
    return "INVENTORY SUMMARY\n%s" % "  •  ".join(parts)

func _set_label_text(label: Label, value: String) -> void:
    if label != null and label.text != value:
        label.text = value

func _suppress_legacy_secondary_hud(player: CharacterBody3D) -> void:
    if player != null:
        var hud: CanvasLayer = player.get_node_or_null("HUD") as CanvasLayer
        if hud != null:
            for node_name in ["CaseFile", "ShelterStatus", "OutsideStatus", "ConditionStatus", "PanicLabel", "IconSurvivalHUD", "SurvivalPanel"]:
                var control: Control = hud.get_node_or_null(NodePath(str(node_name))) as Control
                if control != null:
                    control.visible = false

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        var network_status: Label = network.get("status_label") as Label
        if network_status != null:
            network_status.visible = false
        var old_coop_button: Button = network.get("coop_button") as Button
        if old_coop_button != null:
            old_coop_button.visible = false

    var forest_runtime: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if forest_runtime != null:
        var weather: Label = forest_runtime.get("weather_label") as Label
        if weather != null:
            weather.visible = false

func _open_inventory() -> void:
    _set_menu_open(false)
    var inventory: Node = get_node_or_null("/root/SurvivalSystem/InventoryMenuRuntime")
    if inventory != null and inventory.has_method("_set_inventory_open"):
        inventory.call_deferred("_set_inventory_open", true)

func _open_coop_lobby() -> void:
    _set_menu_open(false)
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("toggle_lobby"):
        network.call_deferred("toggle_lobby")

func _close_from_button() -> void:
    _set_menu_open(false)

func _gameplay_active() -> bool:
    var scene: Node = get_tree().current_scene
    return scene != null and scene.scene_file_path not in MENU_SCENES

func _other_menu_open() -> bool:
    if menu_open:
        return false
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return true
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return true
    var inventory: Node = get_node_or_null("/root/SurvivalSystem/InventoryMenuRuntime")
    if inventory != null and inventory.has_method("is_open") and bool(inventory.call("is_open")):
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        var lobby: PanelContainer = network.get("lobby_panel") as PanelContainer
        if lobby != null and lobby.visible:
            return true
    return false

func _local_player() -> CharacterBody3D:
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

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
