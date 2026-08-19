extends Node

var layer: CanvasLayer = null
var overlay: ColorRect = null
var panel: PanelContainer = null
var content_box: VBoxContainer = null
var carried_list: VBoxContainer = null
var stash_list: VBoxContainer = null
var carried_summary: Label = null
var stash_summary: Label = null
var close_button: Button = null
var menu_open: bool = false
var active_player: CharacterBody3D = null
var refresh_timer: float = 0.0
var previous_mouse_mode: int = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 545
    _build_ui()

func _process(delta: float) -> void:
    if not menu_open:
        return
    if active_player == null or not is_instance_valid(active_player) or bool(active_player.get("is_dead")):
        close_stash()
        return

    refresh_timer -= delta
    if refresh_timer <= 0.0:
        refresh_timer = 0.20
        _refresh_lists()
    _layout_ui()

func _input(event: InputEvent) -> void:
    if not menu_open or not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_ESCAPE:
        close_stash()
        get_viewport().set_input_as_handled()

func is_open() -> bool:
    return menu_open

func open_stash(_chest: Node3D = null) -> void:
    if menu_open or _other_menu_open():
        return
    active_player = _local_player()
    if active_player == null or bool(active_player.get("is_dead")):
        return

    menu_open = true
    overlay.visible = true
    panel.visible = true
    previous_mouse_mode = int(Input.mouse_mode)
    active_player.velocity = Vector3.ZERO
    active_player.set_physics_process(false)
    active_player.set_process_unhandled_input(false)
    _set_mobile_blocked(true)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    refresh_timer = 0.0
    _refresh_lists()
    _layout_ui()

func close_stash() -> void:
    if not menu_open:
        return
    menu_open = false
    if overlay != null:
        overlay.visible = false
    if panel != null:
        panel.visible = false

    if active_player != null and is_instance_valid(active_player):
        active_player.set_physics_process(true)
        active_player.set_process_unhandled_input(true)
    _set_mobile_blocked(false)
    if not _mobile_active() and not _other_menu_open():
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "SharedStashUIV42"
    layer.layer = 87
    add_child(layer)

    overlay = ColorRect.new()
    overlay.color = Color(0.0, 0.0, 0.0, 0.72)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.visible = false
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(overlay)

    panel = PanelContainer.new()
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

    content_box = VBoxContainer.new()
    content_box.add_theme_constant_override("separation", 9)
    margin.add_child(content_box)

    var header: HBoxContainer = HBoxContainer.new()
    header.add_theme_constant_override("separation", 10)
    content_box.add_child(header)

    var registry: Node = get_node_or_null("/root/ItemIconRegistry")
    var stash_icon: Texture2D = null
    if registry != null and registry.has_method("get_icon"):
        stash_icon = registry.call("get_icon", "stash") as Texture2D
    if stash_icon != null:
        var header_icon: TextureRect = _make_icon(stash_icon, Vector2(48.0, 42.0))
        header.add_child(header_icon)

    var title: Label = Label.new()
    title.text = "SHARED STASH"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 25)
    header.add_child(title)

    close_button = Button.new()
    close_button.text = "CLOSE"
    close_button.custom_minimum_size = Vector2(92.0, 38.0)
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.pressed.connect(close_stash)
    header.add_child(close_button)

    var help: Label = Label.new()
    help.text = "Store supplies before expeditions. Shared stash transfers are host-controlled in co-op."
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.add_theme_font_size_override("font_size", 13)
    help.add_theme_color_override("font_color", Color(0.68, 0.72, 0.77, 1.0))
    content_box.add_child(help)

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    content_box.add_child(scroll)

    var sections: VBoxContainer = VBoxContainer.new()
    sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sections.add_theme_constant_override("separation", 16)
    scroll.add_child(sections)

    carried_summary = Label.new()
    carried_summary.add_theme_font_size_override("font_size", 18)
    sections.add_child(carried_summary)

    carried_list = VBoxContainer.new()
    carried_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    carried_list.add_theme_constant_override("separation", 6)
    sections.add_child(carried_list)

    var separator: HSeparator = HSeparator.new()
    sections.add_child(separator)

    stash_summary = Label.new()
    stash_summary.add_theme_font_size_override("font_size", 18)
    sections.add_child(stash_summary)

    stash_list = VBoxContainer.new()
    stash_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stash_list.add_theme_constant_override("separation", 6)
    sections.add_child(stash_list)

    _layout_ui()

func _refresh_lists() -> void:
    if active_player == null or carried_list == null or stash_list == null:
        return

    _clear_rows(carried_list)
    _clear_rows(stash_list)

    var names: Dictionary = Dictionary(active_player.get("inventory_names"))
    var counts: Dictionary = Dictionary(active_player.get("inventory_counts"))
    var capacity: int = int(active_player.get("inventory_capacity"))
    var carried_keys: Array = names.keys()
    carried_keys.sort()

    carried_summary.text = "CARRIED  •  %d / %d SLOTS" % [names.size(), capacity]
    if carried_keys.is_empty():
        _add_empty_row(carried_list, "No items carried")
    else:
        for key_variant: Variant in carried_keys:
            var item_id: String = str(key_variant)
            var count: int = int(counts.get(item_id, 0))
            if count <= 0:
                continue
            _add_transfer_row(
                carried_list,
                item_id,
                str(names.get(item_id, _display_name(item_id))),
                count,
                true
            )

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        stash_summary.text = "STASH  •  UNAVAILABLE"
        _add_empty_row(stash_list, "Shelter system unavailable")
        return

    var storage_names: Dictionary = Dictionary(shelter.get("storage_names"))
    var storage_counts: Dictionary = Dictionary(shelter.get("storage_counts"))
    var stash_keys: Array = storage_names.keys()
    stash_keys.sort()
    stash_summary.text = "STASH  •  %d ITEMS" % _storage_total(storage_counts)

    if stash_keys.is_empty():
        _add_empty_row(stash_list, "Shared stash is empty")
    else:
        for key_variant: Variant in stash_keys:
            var item_id: String = str(key_variant)
            var count: int = int(storage_counts.get(item_id, 0))
            if count <= 0:
                continue
            _add_transfer_row(
                stash_list,
                item_id,
                str(storage_names.get(item_id, _display_name(item_id))),
                count,
                false
            )

func _add_transfer_row(parent: VBoxContainer, item_id: String, display_name: String, count: int, storing: bool) -> void:
    var row_panel: PanelContainer = PanelContainer.new()
    row_panel.add_theme_stylebox_override("panel", _row_style())
    parent.add_child(row_panel)

    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    row_panel.add_child(row)

    var registry: Node = get_node_or_null("/root/ItemIconRegistry")
    if registry != null and registry.has_method("get_icon"):
        var texture: Texture2D = registry.call("get_icon", item_id) as Texture2D
        if texture != null:
            row.add_child(_make_icon(texture, Vector2(50.0, 44.0)))

    var label: Label = Label.new()
    label.text = "%s   x%d" % [display_name, count]
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 16)
    row.add_child(label)

    var action: Button = Button.new()
    action.custom_minimum_size = Vector2(105.0, 42.0)
    action.focus_mode = Control.FOCUS_NONE
    var can_transfer: bool = _can_control_stash()
    action.text = ("STORE 1" if storing else "TAKE 1") if can_transfer else "HOST"
    action.disabled = not can_transfer
    if can_transfer:
        if storing:
            action.pressed.connect(_store_one.bind(item_id))
        else:
            action.pressed.connect(_take_one.bind(item_id))
    row.add_child(action)

func _store_one(item_id: String) -> void:
    if not _can_control_stash() or active_player == null or not active_player.has_method("remove_item"):
        return
    var counts: Dictionary = Dictionary(active_player.get("inventory_counts"))
    if int(counts.get(item_id, 0)) <= 0:
        return

    var names: Dictionary = Dictionary(active_player.get("inventory_names"))
    var display_name: String = str(names.get(item_id, _display_name(item_id)))
    if not bool(active_player.call("remove_item", item_id)):
        return

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        active_player.call("add_item", item_id, display_name)
        return

    var storage_names: Dictionary = Dictionary(shelter.get("storage_names"))
    var storage_counts: Dictionary = Dictionary(shelter.get("storage_counts"))
    storage_names[item_id] = display_name
    storage_counts[item_id] = int(storage_counts.get(item_id, 0)) + 1
    shelter.set("storage_names", storage_names)
    shelter.set("storage_counts", storage_counts)
    _after_transfer()

func _take_one(item_id: String) -> void:
    if not _can_control_stash() or active_player == null or not active_player.has_method("add_item"):
        return
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        return

    var storage_names: Dictionary = Dictionary(shelter.get("storage_names"))
    var storage_counts: Dictionary = Dictionary(shelter.get("storage_counts"))
    var count: int = int(storage_counts.get(item_id, 0))
    if count <= 0:
        return

    var display_name: String = str(storage_names.get(item_id, _display_name(item_id)))
    if not bool(active_player.call("add_item", item_id, display_name)):
        _feedback("Inventory full. Cannot take %s." % display_name)
        return

    count -= 1
    if count <= 0:
        storage_counts.erase(item_id)
        storage_names.erase(item_id)
    else:
        storage_counts[item_id] = count
    shelter.set("storage_names", storage_names)
    shelter.set("storage_counts", storage_counts)
    _after_transfer()

func _after_transfer() -> void:
    refresh_timer = 0.0
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("_broadcast_world_state") and _network_online() and _is_host():
        network.call_deferred("_broadcast_world_state")
    var save: Node = get_node_or_null("/root/SaveSystem")
    if save != null and save.has_method("request_autosave"):
        save.call("request_autosave", "Shared stash updated")

func _feedback(text: String) -> void:
    if active_player == null:
        return
    var objective: Label = active_player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _clear_rows(parent: VBoxContainer) -> void:
    for child: Node in parent.get_children():
        child.queue_free()

func _add_empty_row(parent: VBoxContainer, text: String) -> void:
    var label: Label = Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 14)
    label.add_theme_color_override("font_color", Color(0.58, 0.62, 0.66, 1.0))
    parent.add_child(label)

func _make_icon(texture: Texture2D, size: Vector2) -> TextureRect:
    var icon: TextureRect = TextureRect.new()
    icon.texture = texture
    icon.custom_minimum_size = size
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return icon

func _layout_ui() -> void:
    if panel == null:
        return
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = _mobile_active() or viewport_size.x < 800.0
    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    if compact:
        var width: float = maxf(290.0, viewport_size.x - 18.0)
        var height: float = maxf(430.0, viewport_size.y - 26.0)
        panel.position = Vector2((viewport_size.x - width) * 0.5, (viewport_size.y - height) * 0.5)
        panel.size = Vector2(width, height)
    else:
        var width_desktop: float = minf(860.0, viewport_size.x - 90.0)
        var height_desktop: float = minf(640.0, viewport_size.y - 70.0)
        panel.position = Vector2((viewport_size.x - width_desktop) * 0.5, (viewport_size.y - height_desktop) * 0.5)
        panel.size = Vector2(width_desktop, height_desktop)

func _can_control_stash() -> bool:
    return not _network_online() or _is_host()

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _other_menu_open() -> bool:
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return true
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return true
    var inventory: Node = get_node_or_null("/root/SurvivalSystem/InventoryMenuRuntime")
    if inventory != null and inventory.has_method("is_open") and bool(inventory.call("is_open")):
        return true
    var status_menu: Node = get_node_or_null("/root/FieldStatusMenuSystem")
    if status_menu != null and status_menu.has_method("is_open") and bool(status_menu.call("is_open")):
        return true
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and bool(network.get("lobby_open")):
        return true
    return false

func _set_mobile_blocked(value: bool) -> void:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile != null and mobile.has_method("set_external_blocked"):
        mobile.call("set_external_blocked", value)

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

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

func _storage_total(counts: Dictionary) -> int:
    var total: int = 0
    for value: Variant in counts.values():
        total += int(value)
    return total

func _display_name(item_id: String) -> String:
    match item_id:
        "bottled_water": return "Bottled Water"
        "dirty_water": return "Dirty Water"
        "canned_food": return "Canned Food"
        "medkit": return "Medkit"
        "bandage": return "Bandage"
        "flashlight_battery": return "Flashlight Battery"
        "generator_fuel": return "Fuel Can"
        "firewood_bundle": return "Firewood Bundle"
        "plastic_sheet": return "Plastic Sheet"
        "electronics": return "Electronics"
        "lead_plate": return "Lead Plate"
        "copper_wire": return "Copper Wire"
        "filter": return "Industrial Filter"
        "raw_meat": return "Raw Meat"
        "cooked_meat": return "Cooked Meat"
        "raw_fish": return "Raw Fish"
        "cooked_fish": return "Cooked Fish"
        "hide": return "Animal Hide"
        "animal_fat": return "Animal Fat"
        "hunting_bow": return "Hunting Bow"
        "hunting_knife": return "Hunting Knife"
        "fishing_rod": return "Fishing Rod"
        "raincoat": return "Raincoat"
        "radiation_suit": return "Radiation Suit"
    return item_id.replace("_", " ").capitalize()

func _panel_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.025, 0.032, 0.985)
    style.border_color = Color(0.38, 0.48, 0.42, 0.62)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    return style

func _row_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.045, 0.052, 0.062, 0.94)
    style.border_color = Color(0.34, 0.39, 0.43, 0.30)
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    style.content_margin_left = 10.0
    style.content_margin_right = 8.0
    style.content_margin_top = 6.0
    style.content_margin_bottom = 6.0
    return style
