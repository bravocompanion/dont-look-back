extends Node

const RECIPE_IDS: Array[String] = [
    "firewood_bundle",
    "flashlight_battery",
    "bandage",
    "raincoat",
    "radiation_suit",
    "hunting_bow",
    "arrow_pack",
    "hunting_knife",
    "anti_radiation_tower"
]

var layer: CanvasLayer = null
var overlay: ColorRect = null
var panel: PanelContainer = null
var recipe_list: VBoxContainer = null
var title_label: Label = null
var material_label: Label = null
var close_button: Button = null
var recipe_buttons: Dictionary = {}
var menu_open: bool = false
var active_player: CharacterBody3D = null
var active_workbench: Node3D = null
var refresh_timer: float = 0.0
var previous_mouse_mode: int = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 540
    _build_ui()

func _process(delta: float) -> void:
    var player: CharacterBody3D = _local_player()
    if player != null:
        player.set("inventory_capacity", maxi(16, int(player.get("inventory_capacity"))))
    if not menu_open:
        return
    if player == null or bool(player.get("is_dead")):
        close_workbench()
        return
    active_player = player
    refresh_timer -= delta
    if refresh_timer <= 0.0:
        refresh_timer = 0.25
        _refresh_recipe_buttons()
        _refresh_material_summary()
    _layout_ui()

func _unhandled_key_input(event: InputEvent) -> void:
    if not menu_open or not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_ESCAPE:
        close_workbench()
        get_viewport().set_input_as_handled()

func is_open() -> bool:
    return menu_open

func open_workbench(workbench: Node3D = null) -> void:
    if menu_open:
        return
    if _other_menu_open():
        return
    active_player = _local_player()
    if active_player == null or bool(active_player.get("is_dead")):
        return
    active_workbench = workbench
    menu_open = true
    overlay.visible = true
    panel.visible = true
    previous_mouse_mode = int(Input.mouse_mode)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    _set_mobile_blocked(true)
    refresh_timer = 0.0
    _refresh_recipe_buttons()
    _refresh_material_summary()
    _layout_ui()

func close_workbench() -> void:
    if not menu_open:
        return
    menu_open = false
    active_workbench = null
    if overlay != null:
        overlay.visible = false
    if panel != null:
        panel.visible = false
    _set_mobile_blocked(false)
    if not _mobile_active() and not _other_menu_open():
        var restore_mode: int = previous_mouse_mode
        if restore_mode == Input.MOUSE_MODE_VISIBLE:
            restore_mode = Input.MOUSE_MODE_CAPTURED
        Input.set_mouse_mode(restore_mode)

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "ExpandedCraftingUIV41"
    layer.layer = 86
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

    var root_box: VBoxContainer = VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 9)
    margin.add_child(root_box)

    var header: HBoxContainer = HBoxContainer.new()
    header.add_theme_constant_override("separation", 12)
    root_box.add_child(header)

    title_label = Label.new()
    title_label.text = "RANGER WORKBENCH"
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_font_size_override("font_size", 25)
    header.add_child(title_label)

    close_button = Button.new()
    close_button.text = "CLOSE"
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.custom_minimum_size = Vector2(92.0, 38.0)
    close_button.pressed.connect(close_workbench)
    header.add_child(close_button)

    var help: Label = Label.new()
    help.text = "Survival • Protection • Weapons • Infrastructure"
    help.add_theme_color_override("font_color", Color(0.68, 0.72, 0.76, 1.0))
    root_box.add_child(help)

    material_label = Label.new()
    material_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    material_label.add_theme_font_size_override("font_size", 12)
    material_label.add_theme_color_override("font_color", Color(0.76, 0.79, 0.82, 1.0))
    root_box.add_child(material_label)

    var separator: HSeparator = HSeparator.new()
    root_box.add_child(separator)

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root_box.add_child(scroll)

    recipe_list = VBoxContainer.new()
    recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    recipe_list.add_theme_constant_override("separation", 7)
    scroll.add_child(recipe_list)

    for recipe_id: String in RECIPE_IDS:
        var button: Button = Button.new()
        button.name = StringName("Recipe_%s" % recipe_id)
        button.focus_mode = Control.FOCUS_NONE
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        button.custom_minimum_size = Vector2(0.0, 58.0)
        button.pressed.connect(_craft_recipe.bind(recipe_id))
        recipe_list.add_child(button)
        recipe_buttons[recipe_id] = button

    var footer: Label = Label.new()
    footer.text = "Protection gear is considered equipped while carried. The anti-radiation tower is powered by the shelter generator."
    footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    footer.add_theme_font_size_override("font_size", 12)
    footer.add_theme_color_override("font_color", Color(0.62, 0.66, 0.70, 1.0))
    root_box.add_child(footer)

    _layout_ui()

func _refresh_recipe_buttons() -> void:
    if active_player == null:
        return
    for recipe_id: String in RECIPE_IDS:
        var button: Button = recipe_buttons.get(recipe_id) as Button
        if button == null:
            continue
        var available: bool = _can_craft(recipe_id, active_player)
        var status: String = "READY" if available else "MISSING MATERIALS"
        if _is_unique_owned(recipe_id, active_player):
            status = "OWNED"
        if recipe_id == "anti_radiation_tower":
            var radiation: Node = get_node_or_null("/root/RadiationSystem")
            if radiation != null and radiation.has_method("is_tower_built") and bool(radiation.call("is_tower_built")):
                status = "BUILT"
            elif _network_online() and not _is_authoritative():
                status = "HOST ONLY"
        button.disabled = not available
        button.text = "[%s] %s  —  %s\n%s" % [_recipe_category(recipe_id), _recipe_name(recipe_id), status, _recipe_cost_text(recipe_id)]

func _refresh_material_summary() -> void:
    if material_label == null or active_player == null:
        return
    var counts: Dictionary = Dictionary(active_player.get("inventory_counts"))
    var ids: Array[String] = ["wood", "cloth", "scrap", "plastic_sheet", "rubber", "electronics", "lead_plate", "copper_wire", "filter"]
    var parts: PackedStringArray = PackedStringArray()
    for item_id: String in ids:
        var count: int = int(counts.get(item_id, 0))
        if count > 0:
            parts.append("%s %d" % [_display_name(item_id), count])
    material_label.text = "MATERIALS: %s" % (" • ".join(parts) if not parts.is_empty() else "none")

func _craft_recipe(recipe_id: String) -> void:
    if active_player == null or not _can_craft(recipe_id, active_player):
        return

    var costs: Dictionary = _recipe_costs(recipe_id)
    if not _consume_costs(active_player, costs):
        _feedback("Craft failed: required materials changed before completion.")
        return

    if recipe_id == "anti_radiation_tower":
        var radiation: Node = get_node_or_null("/root/RadiationSystem")
        var built: bool = radiation != null and radiation.has_method("build_tower") and bool(radiation.call("build_tower", active_player))
        if not built:
            _refund_costs(active_player, costs)
            _feedback("Tower construction failed. In co-op, only the host can build shared infrastructure.")
            return
        _feedback("ANTI-RADIATION TOWER BUILT. Start the generator to energize its protective field.")
    else:
        var output: Dictionary = _recipe_output(recipe_id)
        var granted: bool = _grant_output(active_player, output)
        if not granted:
            _refund_costs(active_player, costs)
            _feedback("Craft failed: inventory is full.")
            return
        _feedback("Crafted %s." % _recipe_name(recipe_id))

    _report_ai_noise(0.62, "expanded workbench crafting")
    refresh_timer = 0.0

func _can_craft(recipe_id: String, player: CharacterBody3D) -> bool:
    if player == null:
        return false
    if _is_unique_owned(recipe_id, player):
        return false
    if recipe_id == "anti_radiation_tower":
        var radiation: Node = get_node_or_null("/root/RadiationSystem")
        if radiation == null or not radiation.has_method("can_build_tower") or not bool(radiation.call("can_build_tower")):
            return false
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    var costs: Dictionary = _recipe_costs(recipe_id)
    for key_variant: Variant in costs.keys():
        var item_id: String = str(key_variant)
        if int(counts.get(item_id, 0)) < int(costs.get(item_id, 0)):
            return false
    var output: Dictionary = _recipe_output(recipe_id)
    if output.is_empty():
        return true
    var output_id: String = str(output.get("id", ""))
    if output_id.is_empty():
        return true
    var names: Dictionary = Dictionary(player.get("inventory_names"))
    var capacity: int = int(player.get("inventory_capacity"))
    return names.has(output_id) or names.size() < capacity

func _is_unique_owned(recipe_id: String, player: CharacterBody3D) -> bool:
    var unique_id: String = ""
    match recipe_id:
        "raincoat": unique_id = "raincoat"
        "radiation_suit": unique_id = "radiation_suit"
        "hunting_bow": unique_id = "hunting_bow"
        "hunting_knife": unique_id = "hunting_knife"
    return not unique_id.is_empty() and player.has_method("has_item") and bool(player.call("has_item", unique_id))

func _consume_costs(player: CharacterBody3D, costs: Dictionary) -> bool:
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    for key_variant: Variant in costs.keys():
        var item_id: String = str(key_variant)
        if int(counts.get(item_id, 0)) < int(costs.get(item_id, 0)):
            return false
    for key_variant: Variant in costs.keys():
        var item_id: String = str(key_variant)
        var amount: int = int(costs.get(item_id, 0))
        for _index: int in range(amount):
            if not bool(player.call("remove_item", item_id)):
                return false
    return true

func _refund_costs(player: CharacterBody3D, costs: Dictionary) -> void:
    if player == null or not player.has_method("add_item"):
        return
    for key_variant: Variant in costs.keys():
        var item_id: String = str(key_variant)
        for _index: int in range(int(costs.get(item_id, 0))):
            player.call("add_item", item_id, _display_name(item_id))

func _grant_output(player: CharacterBody3D, output: Dictionary) -> bool:
    if output.is_empty():
        return true
    var item_id: String = str(output.get("id", ""))
    var display_name: String = str(output.get("name", _display_name(item_id)))
    var amount: int = int(output.get("count", 1))
    var granted: int = 0
    for _index: int in range(amount):
        if not bool(player.call("add_item", item_id, display_name)):
            for _refund_index: int in range(granted):
                player.call("remove_item", item_id)
            return false
        granted += 1
    return true

func _recipe_costs(recipe_id: String) -> Dictionary:
    match recipe_id:
        "firewood_bundle": return {"wood": 2}
        "flashlight_battery": return {"scrap": 2, "electronics": 1}
        "bandage": return {"cloth": 2}
        "raincoat": return {"cloth": 3, "plastic_sheet": 2, "rubber": 1}
        "radiation_suit": return {"cloth": 4, "lead_plate": 4, "filter": 2, "rubber": 2, "electronics": 1}
        "hunting_bow": return {"wood": 3, "cloth": 2, "scrap": 1}
        "arrow_pack": return {"wood": 2, "scrap": 1}
        "hunting_knife": return {"scrap": 3, "cloth": 1}
        "anti_radiation_tower": return {"scrap": 8, "electronics": 4, "lead_plate": 4, "copper_wire": 3, "filter": 2}
    return {}

func _recipe_output(recipe_id: String) -> Dictionary:
    match recipe_id:
        "firewood_bundle": return {"id": "firewood_bundle", "name": "Firewood Bundle", "count": 1}
        "flashlight_battery": return {"id": "flashlight_battery", "name": "Flashlight Battery", "count": 1}
        "bandage": return {"id": "bandage", "name": "Bandage", "count": 1}
        "raincoat": return {"id": "raincoat", "name": "Raincoat", "count": 1}
        "radiation_suit": return {"id": "radiation_suit", "name": "Radiation Suit", "count": 1}
        "hunting_bow": return {"id": "hunting_bow", "name": "Hunting Bow", "count": 1}
        "arrow_pack": return {"id": "arrow", "name": "Arrow", "count": 5}
        "hunting_knife": return {"id": "hunting_knife", "name": "Hunting Knife", "count": 1}
    return {}

func _recipe_name(recipe_id: String) -> String:
    match recipe_id:
        "firewood_bundle": return "Firewood Bundle"
        "flashlight_battery": return "Improvised Battery"
        "bandage": return "Bandage"
        "raincoat": return "Raincoat"
        "radiation_suit": return "Radiation Suit"
        "hunting_bow": return "Hunting Bow"
        "arrow_pack": return "Arrow Pack x5"
        "hunting_knife": return "Hunting Knife"
        "anti_radiation_tower": return "Anti-Radiation Tower"
    return recipe_id.capitalize()

func _recipe_category(recipe_id: String) -> String:
    if recipe_id in ["firewood_bundle", "flashlight_battery", "bandage"]:
        return "SURVIVAL"
    if recipe_id in ["raincoat", "radiation_suit"]:
        return "PROTECTION"
    if recipe_id in ["hunting_bow", "arrow_pack", "hunting_knife"]:
        return "WEAPONS"
    return "INFRASTRUCTURE"

func _recipe_cost_text(recipe_id: String) -> String:
    var costs: Dictionary = _recipe_costs(recipe_id)
    var parts: PackedStringArray = PackedStringArray()
    for key_variant: Variant in costs.keys():
        var item_id: String = str(key_variant)
        parts.append("%s x%d" % [_display_name(item_id), int(costs.get(item_id, 0))])
    return "Requires: %s" % ", ".join(parts)

func _display_name(item_id: String) -> String:
    match item_id:
        "wood": return "Wood"
        "cloth": return "Cloth"
        "scrap": return "Scrap"
        "plastic_sheet": return "Plastic Sheet"
        "rubber": return "Rubber"
        "electronics": return "Electronics"
        "lead_plate": return "Lead Plate"
        "copper_wire": return "Copper Wire"
        "filter": return "Filter"
    return item_id.replace("_", " ").capitalize()

func _feedback(text: String) -> void:
    if active_player == null:
        return
    var objective: Label = active_player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _report_ai_noise(strength: float, label: String) -> void:
    if active_workbench == null:
        return
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise != null and noise.has_method("report_noise"):
        noise.call("report_noise", active_workbench.global_position, strength, label)

func _layout_ui() -> void:
    if panel == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = _mobile_active() or size.x < 800.0
    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    if compact:
        var width: float = maxf(290.0, size.x - 18.0)
        var height: float = maxf(430.0, size.y - 26.0)
        panel.position = Vector2((size.x - width) * 0.5, (size.y - height) * 0.5)
        panel.size = Vector2(width, height)
        if title_label != null:
            title_label.add_theme_font_size_override("font_size", 19)
    else:
        var width_desktop: float = minf(820.0, size.x - 90.0)
        var height_desktop: float = minf(620.0, size.y - 80.0)
        panel.position = Vector2((size.x - width_desktop) * 0.5, (size.y - height_desktop) * 0.5)
        panel.size = Vector2(width_desktop, height_desktop)
        if title_label != null:
            title_label.add_theme_font_size_override("font_size", 25)

func _panel_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.025, 0.032, 0.98)
    style.border_color = Color(0.35, 0.48, 0.44, 0.58)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    return style

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
    return false

func _set_mobile_blocked(value: bool) -> void:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile != null and mobile.has_method("set_external_blocked"):
        mobile.call("set_external_blocked", value)

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))
