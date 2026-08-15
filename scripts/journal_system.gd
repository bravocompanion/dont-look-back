extends Node

var entries: Dictionary = {}
var entry_order: Array[String] = []
var current_entry_index: int = 0
var configured_scene_id: int = 0
var outside_notes_scene_id: int = 0
var layout_timer: float = 0.0
var mission_timer: float = 0.0
var note_script: Script

var layer: CanvasLayer
var overlay: ColorRect
var journal_panel: PanelContainer
var journal_button: Button
var mission_label: Label
var entry_heading: Label
var entry_body: RichTextLabel
var entry_counter: Label

func _ready() -> void:
    note_script = load("res://scripts/journal_note.gd") as Script
    _add_entry(
        "survival_basics",
        "Light Is a Resource",
        "TIP",
        "A flashlight is not just for seeing. Protective light lowers Darkness Exposure and can force creatures of the dark to retreat. Save battery when the area is already safe."
    )
    _build_ui()

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene != null:
        var scene_id: int = int(scene.get_instance_id())
        if scene_id != configured_scene_id:
            configured_scene_id = scene_id
            outside_notes_scene_id = 0
            call_deferred("_configure_scene", scene)
        _ensure_outside_notes(scene)

    layout_timer -= delta
    if layout_timer <= 0.0:
        layout_timer = 0.35
        _apply_responsive_layout()

    if journal_panel != null and journal_panel.visible:
        mission_timer -= delta
        if mission_timer <= 0.0:
            mission_timer = 0.25
            _update_mission()

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return

    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    var focus: Control = get_viewport().gui_get_focus_owner()
    if focus is LineEdit:
        return

    if key_event.physical_keycode == KEY_J:
        toggle_journal()
        get_viewport().set_input_as_handled()
    elif key_event.physical_keycode == KEY_ESCAPE and journal_panel != null and journal_panel.visible:
        close_journal()
        get_viewport().set_input_as_handled()

func has_entry(entry_id: String) -> bool:
    return entries.has(entry_id)

func discover_entry(entry_id: String, title: String, category: String, body: String, open_after: bool = true) -> void:
    var newly_discovered: bool = not entries.has(entry_id)
    _add_entry(entry_id, title, category, body)

    if newly_discovered:
        current_entry_index = maxi(0, entry_order.find(entry_id))
        _announce_discovery(title)

    if open_after:
        open_journal()

func toggle_journal() -> void:
    if journal_panel == null:
        return
    if journal_panel.visible:
        close_journal()
    else:
        open_journal()

func open_journal() -> void:
    if journal_panel == null or overlay == null:
        return
    journal_panel.visible = true
    overlay.visible = true
    _update_mission()
    _update_entry_display()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_journal() -> void:
    if journal_panel == null or overlay == null:
        return
    journal_panel.visible = false
    overlay.visible = false

    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
    if not mobile_active:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _add_entry(entry_id: String, title: String, category: String, body: String) -> void:
    if entry_id.is_empty():
        return
    if not entries.has(entry_id):
        entry_order.append(entry_id)
    entries[entry_id] = {
        "title": title,
        "category": category,
        "body": body
    }

func _previous_entry() -> void:
    if entry_order.is_empty():
        return
    current_entry_index = posmod(current_entry_index - 1, entry_order.size())
    _update_entry_display()

func _next_entry() -> void:
    if entry_order.is_empty():
        return
    current_entry_index = posmod(current_entry_index + 1, entry_order.size())
    _update_entry_display()

func _update_entry_display() -> void:
    if entry_heading == null or entry_body == null or entry_counter == null:
        return

    if entry_order.is_empty():
        entry_heading.text = "NO ENTRIES"
        entry_body.text = "Explore the world and inspect papers, logs, warnings, and strange objects."
        entry_counter.text = "0 / 0"
        return

    current_entry_index = clampi(current_entry_index, 0, entry_order.size() - 1)
    var entry_id: String = entry_order[current_entry_index]
    var data: Dictionary = Dictionary(entries.get(entry_id, {}))
    var category: String = str(data.get("category", "NOTE"))
    var title: String = str(data.get("title", "Unknown"))
    entry_heading.text = "[%s]  %s" % [category, title]
    entry_body.text = str(data.get("body", ""))
    entry_counter.text = "ENTRY %d / %d" % [current_entry_index + 1, entry_order.size()]

func _update_mission() -> void:
    if mission_label == null:
        return
    mission_label.text = "CURRENT MISSION\n%s" % _get_current_mission()

func _get_current_mission() -> String:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return "Find your bearings."

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var outside_active: bool = outside != null and outside.has_method("is_outside_active") and bool(outside.call("is_outside_active"))
    if outside_active:
        var shelter: Node = get_node_or_null("/root/ShelterSystem")
        if shelter != null:
            var generator_running: bool = bool(shelter.get("generator_running"))
            var generator_fuel: float = float(shelter.get("generator_fuel_seconds"))
            if not generator_running and generator_fuel <= 0.0:
                return "Secure the forest cabin. Find fuel and restore shelter power."

        var night: bool = outside.has_method("is_night") and bool(outside.call("is_night"))
        if night:
            return "Survive the night. Maintain light, treat wounds, and return to shelter when the deep forest becomes too dangerous."
        return "Explore the abandoned region for fuel, food, Cloth, medicine, and water. Prepare the shelter before night."

    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    var relay_count: int = 0
    if labyrinth != null:
        var relays: Dictionary = Dictionary(labyrinth.get("active_relays"))
        for value: Variant in relays.values():
            if bool(value):
                relay_count += 1

    if relay_count >= 3:
        return "All emergency relays are online. Follow the final beacon and get outside."
    if player.global_position.z < -15.0:
        return "Restore the emergency relays: %d / 3 online. Keep a light source ready." % relay_count
    return "Survive the opening labyrinth, search Apartment 03, and find a way deeper."

func _configure_scene(scene: Node) -> void:
    if not is_instance_valid(scene):
        return
    await get_tree().process_frame
    if not is_instance_valid(scene) or get_tree().current_scene != scene:
        return

    _spawn_note(
        scene,
        "JournalApartmentScribble",
        "apartment_scribble",
        "Scribble Behind the Drawer",
        "TIP",
        "It only moves when nobody is looking. I tried mirrors. The mirror did not count. A living pair of eyes did.",
        Vector3(-5.45, 0.06, -5.25)
    )
    _spawn_note(
        scene,
        "JournalRelayMemo",
        "relay_memo",
        "Emergency Relay Memo",
        "MISSION NOTE",
        "Three emergency relays feed the final gate. Maintenance rule: restore them one at a time and never cross the dark service corridor without a working lamp.",
        Vector3(-7.2, 0.06, -34.1)
    )

func _ensure_outside_notes(scene: Node) -> void:
    var outside_root: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if outside_root == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if outside_notes_scene_id == scene_id:
        return
    outside_notes_scene_id = scene_id

    _spawn_note(
        outside_root,
        "JournalCabinLedger",
        "cabin_ledger",
        "Cabin Fuel Ledger",
        "LOG",
        "Fuel inventory ended three winters ago. The final entry says: 'Keep the porch light burning. Things stop at the edge of it, even when the generator sounds like it should be dead.'",
        Vector3(12.0, 0.92, -83.6)
    )
    _spawn_note(
        outside_root,
        "JournalGasTrivia",
        "gas_station_receipt",
        "Receipt #0313",
        "TRIVIA",
        "The old road's mile markers skip 13, but every receipt from this station ends in 13. This one lists batteries, canned food, and one item simply written as 'DO NOT TURN AROUND'.",
        Vector3(25.6, 0.92, -164.2)
    )
    _spawn_note(
        outside_root,
        "JournalWarehouseWarning",
        "warehouse_warning",
        "Warehouse Night Notice",
        "WARNING",
        "Night crew: keep aisle lights overlapping. A dark gap between two lamps is still a dark place. If someone calls your name from an unlit aisle, count the people beside you before answering.",
        Vector3(-8.2, 0.92, -188.2)
    )
    _spawn_note(
        outside_root,
        "JournalPumpCard",
        "pump_card",
        "Hand Pump Service Card",
        "TIP",
        "The groundwater is not safe untreated. Boil it over a sustained fire. Clear water is not the same thing as clean water.",
        Vector3(30.3, 0.62, -188.0)
    )

func _spawn_note(parent: Node, node_name: String, entry_id: String, title: String, category: String, body: String, position: Vector3) -> void:
    if note_script == null or parent.has_node(NodePath(node_name)) or has_entry(entry_id):
        return

    var note: StaticBody3D = StaticBody3D.new()
    note.name = StringName(node_name)
    note.set_script(note_script)
    note.set("entry_id", entry_id)
    note.set("entry_title", title)
    note.set("entry_category", category)
    note.set("entry_body", body)
    note.position = position
    parent.add_child(note)

func _announce_discovery(title: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective == null:
        return

    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
    objective.text = "Journal updated: %s. Tap JOURNAL to read it." % title if mobile_active else "Journal updated: %s. Press J to read it." % title

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "JournalUI"
    layer.layer = 30
    add_child(layer)

    overlay = ColorRect.new()
    overlay.name = "JournalOverlay"
    overlay.color = Color(0.0, 0.0, 0.0, 0.72)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.visible = false

    journal_panel = PanelContainer.new()
    journal_panel.name = "JournalPanel"
    journal_panel.anchor_left = 0.5
    journal_panel.anchor_top = 0.5
    journal_panel.anchor_right = 0.5
    journal_panel.anchor_bottom = 0.5
    journal_panel.visible = false
    layer.add_child(journal_panel)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    journal_panel.add_child(box)

    var title: Label = Label.new()
    title.text = "JOURNAL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    box.add_child(title)

    mission_label = Label.new()
    mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mission_label.add_theme_font_size_override("font_size", 16)
    box.add_child(mission_label)

    entry_heading = Label.new()
    entry_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    entry_heading.add_theme_font_size_override("font_size", 18)
    box.add_child(entry_heading)

    entry_body = RichTextLabel.new()
    entry_body.custom_minimum_size = Vector2(0.0, 210.0)
    entry_body.fit_content = false
    entry_body.scroll_active = true
    entry_body.add_theme_font_size_override("normal_font_size", 16)
    box.add_child(entry_body)

    entry_counter = Label.new()
    entry_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(entry_counter)

    var row: HBoxContainer = HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 10)
    box.add_child(row)

    var previous_button: Button = Button.new()
    previous_button.text = "PREV"
    previous_button.pressed.connect(_previous_entry)
    row.add_child(previous_button)

    var next_button: Button = Button.new()
    next_button.text = "NEXT"
    next_button.pressed.connect(_next_entry)
    row.add_child(next_button)

    var close_button: Button = Button.new()
    close_button.text = "CLOSE"
    close_button.pressed.connect(close_journal)
    row.add_child(close_button)

    journal_button = Button.new()
    journal_button.text = "JOURNAL"
    journal_button.focus_mode = Control.FOCUS_NONE
    journal_button.pressed.connect(toggle_journal)
    layer.add_child(journal_button)

    _update_mission()
    _update_entry_display()
    _apply_responsive_layout()

func _apply_responsive_layout() -> void:
    if journal_panel == null or journal_button == null:
        return

    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = size.x < 800.0
    if compact:
        journal_panel.offset_left = -165.0
        journal_panel.offset_top = -245.0
        journal_panel.offset_right = 165.0
        journal_panel.offset_bottom = 245.0
        entry_body.custom_minimum_size = Vector2(0.0, 180.0)
        journal_button.visible = true
        journal_button.offset_left = 12.0
        journal_button.offset_top = 46.0
        journal_button.offset_right = 112.0
        journal_button.offset_bottom = 88.0
    else:
        journal_panel.offset_left = -330.0
        journal_panel.offset_top = -260.0
        journal_panel.offset_right = 330.0
        journal_panel.offset_bottom = 260.0
        entry_body.custom_minimum_size = Vector2(0.0, 225.0)
        journal_button.visible = false
