extends Node

const UI_ROOT_NAME: String = "InventoryMenuRuntime"
const USE_METHODS: Dictionary = {
    "canned_food": "_consume_food",
    "bottled_water": "_consume_water",
    "medkit": "_consume_medkit",
    "flashlight_battery": "_replace_flashlight_battery"
}

var active_player: CharacterBody3D
var ui_root: Control
var overlay: ColorRect
var panel: PanelContainer
var bag_button: Button
var close_button: Button
var summary_label: Label
var item_list: VBoxContainer
var help_label: Label
var inventory_open: bool = false
var player_probe_timer: float = 0.0
var refresh_timer: float = 0.0
var layout_timer: float = 0.0
var last_signature: String = ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind_local_player")

func _process(delta: float) -> void:
    player_probe_timer -= delta
    if player_probe_timer <= 0.0:
        player_probe_timer = 0.35
        _bind_local_player()

    if not is_instance_valid(active_player) or not is_instance_valid(ui_root):
        return

    _hide_legacy_inventory_label()

    if inventory_open and not _can_open_inventory():
        _set_inventory_open(false)

    if bag_button != null:
        bag_button.visible = not inventory_open and _can_open_inventory()

    refresh_timer -= delta
    if refresh_timer <= 0.0:
        refresh_timer = 0.15
        if inventory_open:
            _refresh_inventory(false)

    layout_timer -= delta
    if layout_timer <= 0.0:
        layout_timer = 0.4
        _apply_responsive_layout()

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo or key_event.physical_keycode != KEY_I:
        return
    if inventory_open:
        _set_inventory_open(false)
        get_viewport().set_input_as_handled()
        return
    if _can_open_inventory():
        _set_inventory_open(true)
        get_viewport().set_input_as_handled()

func is_open() -> bool:
    return inventory_open

func _bind_local_player() -> void:
    var candidate: CharacterBody3D = _find_local_player()
    if candidate == active_player and is_instance_valid(ui_root):
        return

    if inventory_open:
        _set_inventory_open(false)

    if is_instance_valid(ui_root):
        ui_root.queue_free()

    active_player = candidate
    ui_root = null
    overlay = null
    panel = null
    bag_button = null
    close_button = null
    summary_label = null
    item_list = null
    help_label = null
    last_signature = ""

    if active_player == null:
        return

    var hud: CanvasLayer = active_player.get_node_or_null("HUD") as CanvasLayer
    if hud == null:
        return

    var stale: Node = hud.get_node_or_null(UI_ROOT_NAME)
    if stale != null:
        stale.queue_free()

    _build_ui(hud)
    _hide_legacy_inventory_label()
    _apply_responsive_layout()

func _find_local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D
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

func _build_ui(hud: CanvasLayer) -> void:
    ui_root = Control.new()
    ui_root.name = UI_ROOT_NAME
    ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.z_index = 300
    hud.add_child(ui_root)
    ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)

    overlay = ColorRect.new()
    overlay.name = "Overlay"
    overlay.color = Color(0.0, 0.0, 0.0, 0.64)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.visible = false
    ui_root.add_child(overlay)
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

    bag_button = Button.new()
    bag_button.name = "BagButton"
    bag_button.text = "BAG" if _mobile_active() else "I"
    bag_button.focus_mode = Control.FOCUS_NONE
    bag_button.add_theme_font_size_override("font_size", 16)
    bag_button.add_theme_stylebox_override("normal", _button_style(Color(0.055, 0.065, 0.08, 0.90)))
    bag_button.add_theme_stylebox_override("hover", _button_style(Color(0.10, 0.12, 0.15, 0.96)))
    bag_button.add_theme_stylebox_override("pressed", _button_style(Color(0.16, 0.18, 0.22, 0.98)))
    bag_button.pressed.connect(_on_bag_pressed)
    ui_root.add_child(bag_button)

    panel = PanelContainer.new()
    panel.name = "InventoryPanel"
    panel.visible = false
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    panel.add_theme_stylebox_override("panel", _panel_style())
    ui_root.add_child(panel)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(margin)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)

    var header: HBoxContainer = HBoxContainer.new()
    header.add_theme_constant_override("separation", 12)
    box.add_child(header)

    var title: Label = Label.new()
    title.text = "INVENTORY"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", Color(0.92, 0.93, 0.95, 1.0))
    header.add_child(title)

    close_button = Button.new()
    close_button.text = "CLOSE"
    close_button.custom_minimum_size = Vector2(92, 38)
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.pressed.connect(_on_close_pressed)
    header.add_child(close_button)

    summary_label = Label.new()
    summary_label.text = "SLOTS 0 / 0"
    summary_label.add_theme_font_size_override("font_size", 14)
    summary_label.add_theme_color_override("font_color", Color(0.70, 0.73, 0.78, 1.0))
    box.add_child(summary_label)

    var separator: HSeparator = HSeparator.new()
    box.add_child(separator)

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.name = "Scroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    box.add_child(scroll)

    item_list = VBoxContainer.new()
    item_list.name = "Items"
    item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    item_list.add_theme_constant_override("separation", 7)
    scroll.add_child(item_list)

    help_label = Label.new()
    help_label.text = "I: close inventory" if not _mobile_active() else "Tap USE to consume an item"
    help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help_label.add_theme_font_size_override("font_size", 13)
    help_label.add_theme_color_override("font_color", Color(0.58, 0.61, 0.66, 1.0))
    box.add_child(help_label)

func _refresh_inventory(force: bool) -> void:
    if active_player == null or item_list == null:
        return

    var signature: String = _inventory_signature()
    if not force and signature == last_signature:
        return
    last_signature = signature

    for child: Node in item_list.get_children():
        child.queue_free()

    var names_value: Variant = active_player.get("inventory_names")
    var counts_value: Variant = active_player.get("inventory_counts")
    if not (names_value is Dictionary) or not (counts_value is Dictionary):
        _add_empty_inventory_row("Inventory data unavailable")
        return

    var names: Dictionary = names_value
    var counts: Dictionary = counts_value
    var capacity: int = int(active_player.get("inventory_capacity"))
    summary_label.text = "SLOTS %d / %d" % [names.size(), capacity]

    if names.is_empty():
        _add_empty_inventory_row("No items carried")
        return

    var keys: Array = names.keys()
    keys.sort()
    for key_value: Variant in keys:
        var item_id: String = str(key_value)
        var display_name: String = str(names.get(key_value, item_id))
        var count: int = int(counts.get(key_value, 0))
        if count <= 0:
            continue
        _add_item_row(item_id, display_name, count)

func _add_empty_inventory_row(text: String) -> void:
    var label: Label = Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 16)
    label.add_theme_color_override("font_color", Color(0.58, 0.61, 0.66, 1.0))
    item_list.add_child(label)

func _add_item_row(item_id: String, display_name: String, count: int) -> void:
    var row_panel: PanelContainer = PanelContainer.new()
    row_panel.add_theme_stylebox_override("panel", _item_style())
    item_list.add_child(row_panel)

    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    row_panel.add_child(row)

    var name_label: Label = Label.new()
    name_label.text = "%s   x%d" % [display_name, count]
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 16)
    row.add_child(name_label)

    var action: Button = Button.new()
    action.custom_minimum_size = Vector2(92, 40)
    action.focus_mode = Control.FOCUS_NONE
    if USE_METHODS.has(item_id):
        action.text = "USE"
        action.pressed.connect(_use_item.bind(item_id))
    else:
        action.text = "KEY ITEM"
        action.disabled = true
    row.add_child(action)

func _inventory_signature() -> String:
    if active_player == null:
        return ""
    var names_value: Variant = active_player.get("inventory_names")
    var counts_value: Variant = active_player.get("inventory_counts")
    if not (names_value is Dictionary) or not (counts_value is Dictionary):
        return "invalid"

    var names: Dictionary = names_value
    var counts: Dictionary = counts_value
    var keys: Array = names.keys()
    keys.sort()
    var parts: PackedStringArray = PackedStringArray()
    for key_value: Variant in keys:
        parts.append("%s:%s:%d" % [str(key_value), str(names.get(key_value, "")), int(counts.get(key_value, 0))])
    return "|".join(parts)

func _use_item(item_id: String) -> void:
    if active_player == null or not USE_METHODS.has(item_id):
        return
    var method_name: String = str(USE_METHODS[item_id])
    if active_player.has_method(method_name):
        active_player.call(method_name)
    last_signature = ""
    call_deferred("_refresh_inventory", true)

func _on_bag_pressed() -> void:
    if _can_open_inventory():
        _set_inventory_open(true)

func _on_close_pressed() -> void:
    _set_inventory_open(false)

func _set_inventory_open(value: bool) -> void:
    if value and not _can_open_inventory():
        return
    if inventory_open == value:
        return

    inventory_open = value
    if overlay != null:
        overlay.visible = value
    if panel != null:
        panel.visible = value
    if bag_button != null:
        bag_button.visible = not value and _can_open_inventory()

    if active_player == null:
        return

    if value:
        active_player.velocity = Vector3.ZERO
        active_player.set_physics_process(false)
        active_player.set_process_unhandled_input(false)
        _set_mobile_blocked(true)
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        last_signature = ""
        _refresh_inventory(true)
    else:
        if not _blocked_elsewhere():
            active_player.set_physics_process(true)
            active_player.set_process_unhandled_input(true)
            _set_mobile_blocked(false)
            if not _mobile_active():
                Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _can_open_inventory() -> bool:
    if active_player == null or bool(active_player.get("is_dead")):
        return false
    return not _blocked_elsewhere()

func _blocked_elsewhere() -> bool:
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return true

    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return true

    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition != null and bool(transition.get("transitioning")):
        return true

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null and bool(coop.get("local_downed")):
        return true

    return false

func _hide_legacy_inventory_label() -> void:
    if active_player == null:
        return
    var legacy: Label = active_player.get_node_or_null("HUD/InventoryLabel") as Label
    if legacy != null:
        legacy.visible = false

func _apply_responsive_layout() -> void:
    if ui_root == null or panel == null or bag_button == null:
        return

    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = viewport_size.x < 800.0 or _mobile_active()
    bag_button.text = "BAG" if _mobile_active() else "I"

    if compact:
        bag_button.size = Vector2(62, 46)
        bag_button.position = Vector2(16, 76)
        panel.size = Vector2(minf(viewport_size.x - 24.0, 520.0), minf(viewport_size.y - 28.0, 520.0))
        help_label.text = "Tap USE to consume an item" if _mobile_active() else "I: close inventory"
    else:
        bag_button.size = Vector2(48, 42)
        bag_button.position = Vector2(28, 174)
        panel.size = Vector2(560, minf(viewport_size.y - 80.0, 540.0))
        help_label.text = "I: close inventory"

    panel.position = (viewport_size - panel.size) * 0.5

func _set_mobile_blocked(blocked: bool) -> void:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile == null:
        return
    if mobile.has_method("set_external_blocked"):
        mobile.call("set_external_blocked", blocked)
    elif mobile.has_method("set_dead_mode"):
        mobile.call("set_dead_mode", blocked)

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

func _panel_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.022, 0.030, 0.97)
    style.border_color = Color(0.52, 0.56, 0.64, 0.40)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
    style.shadow_size = 12
    return style

func _item_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.045, 0.052, 0.064, 0.94)
    style.border_color = Color(0.40, 0.44, 0.50, 0.24)
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    style.content_margin_left = 12.0
    style.content_margin_right = 8.0
    style.content_margin_top = 7.0
    style.content_margin_bottom = 7.0
    return style

func _button_style(color: Color) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color(0.58, 0.62, 0.70, 0.38)
    style.set_border_width_all(1)
    style.set_corner_radius_all(7)
    return style
