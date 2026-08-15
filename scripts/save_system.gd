extends Node

const SAVE_PATH: String = "user://dont_look_back_save_v1.json"
const SAVE_FORMAT_VERSION: int = 1

var persistent_claimed_pickups: Dictionary = {}
var save_exists: bool = false
var load_started: bool = false
var status_timer: float = 0.0

var layer: CanvasLayer
var status_label: Label
var save_button: Button
var load_button: Button

func _ready() -> void:
    save_exists = FileAccess.file_exists(SAVE_PATH)
    _build_ui()
    if save_exists:
        call_deferred("_autoload_existing_save")

func _process(delta: float) -> void:
    if status_timer > 0.0:
        status_timer = maxf(0.0, status_timer - delta)
        if status_timer <= 0.0 and status_label != null:
            status_label.text = _idle_status_text()
    _layout_ui()

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return

    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    var focus: Control = get_viewport().gui_get_focus_owner()
    if focus is LineEdit:
        return

    if key_event.physical_keycode == KEY_K:
        save_game(false)
        get_viewport().set_input_as_handled()
    elif key_event.physical_keycode == KEY_L:
        load_game()
        get_viewport().set_input_as_handled()

func register_claimed_pickup(node_path: String) -> void:
    if node_path.is_empty():
        return
    persistent_claimed_pickups[node_path] = true

func is_pickup_claimed(node_path: String) -> bool:
    return bool(persistent_claimed_pickups.get(node_path, false))

func request_autosave(reason: String = "Checkpoint") -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("is_client") and bool(network.call("is_client")):
        return
    call_deferred("_deferred_autosave", reason)

func save_game(automatic: bool = false) -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("is_client") and bool(network.call("is_client")):
        _show_status("CLIENT: host owns the world save.")
        return false

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        _show_status("Save failed: player not ready.")
        return false
    if bool(player.get("is_dead")) or _is_local_player_downed():
        _show_status("Cannot save while incapacitated.")
        return false

    _merge_network_claims()
    var state: Dictionary = _collect_state(player)
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        _show_status("Save failed: cannot open save file.")
        return false

    file.store_string(JSON.stringify(state, "  "))
    file.close()
    save_exists = true

    if automatic:
        _show_status("AUTOSAVED")
    else:
        _show_status("WORLD SAVED")
        _set_objective(player, "World saved. Your survival progress is now persistent.")
    return true

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        _show_status("No save file yet.")
        return false

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("is_online") and bool(network.call("is_online")):
        _show_status("Leave CO-OP before loading a world save.")
        return false

    return _load_from_disk(false)

func delete_save() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        save_exists = false
        return true
    var absolute_path: String = ProjectSettings.globalize_path(SAVE_PATH)
    var error: Error = DirAccess.remove_absolute(absolute_path)
    if error != OK:
        _show_status("Could not delete save.")
        return false
    save_exists = false
    persistent_claimed_pickups.clear()
    _show_status("Save deleted.")
    return true

func _autoload_existing_save() -> void:
    if load_started:
        return
    load_started = true
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    _load_from_disk(true)

func _deferred_autosave(reason: String) -> void:
    await get_tree().process_frame
    var saved: bool = save_game(true)
    if saved:
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if player != null:
            _set_objective(player, "%s — progress autosaved." % reason)

func _load_from_disk(automatic: bool) -> bool:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        _show_status("Load failed: cannot open save file.")
        return false

    var raw_text: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(raw_text)
    if not (parsed is Dictionary):
        _show_status("Load failed: save data is invalid.")
        return false

    var state: Dictionary = Dictionary(parsed)
    var format_version: int = int(state.get("format_version", 0))
    if format_version <= 0 or format_version > SAVE_FORMAT_VERSION:
        _show_status("Load failed: unsupported save version.")
        return false

    save_exists = true
    if automatic:
        _restore_state(state)
        _show_status("SAVE RESTORED")
    else:
        persistent_claimed_pickups.clear()
        _clear_network_claims()
        call_deferred("_reload_and_restore", state)
        _show_status("LOADING WORLD...")
    return true

func _reload_and_restore(state: Dictionary) -> void:
    var reload_error: Error = get_tree().reload_current_scene()
    if reload_error != OK:
        _show_status("Load failed: scene could not reload.")
        return

    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    _restore_state(state)
    _show_status("WORLD LOADED")

func _collect_state(player: CharacterBody3D) -> Dictionary:
    return {
        "format_version": SAVE_FORMAT_VERSION,
        "saved_unix_time": int(Time.get_unix_time_from_system()),
        "player": _collect_player_state(player),
        "world": _collect_world_state(),
        "conditions": _collect_condition_state(),
        "checkpoint": _collect_checkpoint_state(),
        "journal": _collect_journal_state(),
        "claimed_pickups": persistent_claimed_pickups.keys()
    }

func _collect_player_state(player: CharacterBody3D) -> Dictionary:
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    return {
        "position": _vector3_to_array(player.global_position),
        "rotation_y": player.rotation.y,
        "health": float(player.get("health")),
        "hunger": float(player.get("hunger")),
        "thirst": float(player.get("thirst")),
        "stamina": float(player.get("stamina")),
        "flashlight_battery": float(player.get("flashlight_battery")),
        "darkness_exposure": float(player.get("darkness_exposure")),
        "inventory_names": Dictionary(player.get("inventory_names")).duplicate(true),
        "inventory_counts": Dictionary(player.get("inventory_counts")).duplicate(true),
        "flashlight_on": flashlight != null and flashlight.visible
    }

func _collect_world_state() -> Dictionary:
    var state: Dictionary = {}

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        state["game_minutes"] = float(outside.get("game_minutes"))
        state["day_index"] = int(outside.get("day_index"))
        state["cold_exposure"] = float(outside.get("cold_exposure"))

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter != null:
        state["generator_running"] = bool(shelter.get("generator_running"))
        state["generator_fuel_seconds"] = float(shelter.get("generator_fuel_seconds"))
        state["campfire_burn_seconds"] = float(shelter.get("campfire_burn_seconds"))
        state["storage_names"] = Dictionary(shelter.get("storage_names")).duplicate(true)
        state["storage_counts"] = Dictionary(shelter.get("storage_counts")).duplicate(true)

    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth != null:
        var relays: Dictionary = Dictionary(labyrinth.get("active_relays"))
        state["relays"] = [
            bool(relays.get(0, false)),
            bool(relays.get(1, false)),
            bool(relays.get(2, false))
        ]

    var scene: Node = get_tree().current_scene
    if scene != null:
        var first_door: Node = scene.get_node_or_null("Door")
        if first_door != null:
            state["first_door_open"] = bool(first_door.get("is_open"))
        var exit_door: Node = scene.get_node_or_null("ExitDoor")
        if exit_door != null:
            state["exit_door_open"] = bool(exit_door.get("is_open"))
            state["exit_door_unlocked"] = bool(exit_door.get("unlocked"))

    return state

func _collect_condition_state() -> Dictionary:
    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth == null:
        return {}
    return {
        "bleeding": float(depth.get("bleeding")),
        "infection": float(depth.get("infection"))
    }

func _collect_checkpoint_state() -> Dictionary:
    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint == null:
        return {}
    var checkpoint_position: Vector3 = checkpoint.get("checkpoint_position")
    return {
        "active": bool(checkpoint.get("checkpoint_active")),
        "position": _vector3_to_array(checkpoint_position),
        "rotation_y": float(checkpoint.get("checkpoint_rotation_y")),
        "state": Dictionary(checkpoint.get("checkpoint_state")).duplicate(true),
        "name": str(checkpoint.get("checkpoint_name"))
    }

func _collect_journal_state() -> Dictionary:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return {}
    var order_variant: Variant = journal.get("entry_order")
    var order: Array = []
    if order_variant is Array:
        order = Array(order_variant).duplicate(true)
    return {
        "entries": Dictionary(journal.get("entries")).duplicate(true),
        "order": order,
        "index": int(journal.get("current_entry_index"))
    }

func _restore_state(state: Dictionary) -> void:
    var world_state: Dictionary = Dictionary(state.get("world", {}))
    _restore_world_state(world_state)

    persistent_claimed_pickups.clear()
    var claimed_variant: Variant = state.get("claimed_pickups", [])
    if claimed_variant is Array:
        for path_variant: Variant in Array(claimed_variant):
            var pickup_path: String = str(path_variant)
            if not pickup_path.is_empty():
                persistent_claimed_pickups[pickup_path] = true
    _apply_claims_to_network()
    _remove_current_claimed_nodes()

    _restore_checkpoint_state(Dictionary(state.get("checkpoint", {})))
    _restore_journal_state(Dictionary(state.get("journal", {})))

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        _restore_player_state(player, Dictionary(state.get("player", {})))
        _restore_condition_state(player, Dictionary(state.get("conditions", {})))
        _set_objective(player, "Persistent world restored. Continue where you left off.")

    call_deferred("_finalize_restore")

func _finalize_restore() -> void:
    await get_tree().process_frame
    await get_tree().process_frame

    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth != null:
        if labyrinth.has_method("_restore_relay_visuals"):
            labyrinth.call("_restore_relay_visuals")
        if labyrinth.has_method("_update_gate_state"):
            labyrinth.call("_update_gate_state")

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter != null:
        if shelter.has_method("_sync_generator_state"):
            shelter.call("_sync_generator_state")
        if shelter.has_method("_apply_campfire_state"):
            shelter.call("_apply_campfire_state")

    _remove_current_claimed_nodes()

func _restore_world_state(state: Dictionary) -> void:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        if state.has("game_minutes"):
            outside.set("game_minutes", float(state["game_minutes"]))
        if state.has("day_index"):
            outside.set("day_index", int(state["day_index"]))
        if state.has("cold_exposure"):
            outside.set("cold_exposure", clampf(float(state["cold_exposure"]), 0.0, 100.0))

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter != null:
        if state.has("generator_running"):
            shelter.set("generator_running", bool(state["generator_running"]))
        if state.has("generator_fuel_seconds"):
            shelter.set("generator_fuel_seconds", maxf(0.0, float(state["generator_fuel_seconds"])))
        if state.has("campfire_burn_seconds"):
            shelter.set("campfire_burn_seconds", maxf(0.0, float(state["campfire_burn_seconds"])))
        if state.has("storage_names"):
            shelter.set("storage_names", Dictionary(state["storage_names"]).duplicate(true))
        if state.has("storage_counts"):
            shelter.set("storage_counts", Dictionary(state["storage_counts"]).duplicate(true))
        if shelter.has_method("_sync_generator_state"):
            shelter.call("_sync_generator_state")
        if shelter.has_method("_apply_campfire_state"):
            shelter.call("_apply_campfire_state")

    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth != null and state.has("relays"):
        var relay_values: Array = Array(state["relays"])
        var restored_relays: Dictionary = {}
        for relay_id: int in range(3):
            var active: bool = relay_id < relay_values.size() and bool(relay_values[relay_id])
            if active:
                restored_relays[relay_id] = true
        labyrinth.set("active_relays", restored_relays)
        if labyrinth.has_method("_restore_relay_visuals"):
            labyrinth.call("_restore_relay_visuals")
        if labyrinth.has_method("_update_gate_state"):
            labyrinth.call("_update_gate_state")

    var scene: Node = get_tree().current_scene
    if scene != null:
        _restore_door(scene.get_node_or_null("Door"), bool(state.get("first_door_open", false)), false, false)
        _restore_door(
            scene.get_node_or_null("ExitDoor"),
            bool(state.get("exit_door_open", false)),
            true,
            bool(state.get("exit_door_unlocked", false))
        )

func _restore_player_state(player: CharacterBody3D, state: Dictionary) -> void:
    if state.is_empty():
        return

    player.global_position = _array_to_vector3(state.get("position", []), player.global_position)
    player.rotation.y = float(state.get("rotation_y", player.rotation.y))
    player.velocity = Vector3.ZERO
    player.set("health", clampf(float(state.get("health", 100.0)), 1.0, float(player.get("max_health"))))
    player.set("hunger", clampf(float(state.get("hunger", 100.0)), 0.0, float(player.get("max_hunger"))))
    player.set("thirst", clampf(float(state.get("thirst", 100.0)), 0.0, float(player.get("max_thirst"))))
    player.set("stamina", clampf(float(state.get("stamina", 100.0)), 0.0, float(player.get("max_stamina"))))
    player.set("flashlight_battery", clampf(float(state.get("flashlight_battery", 100.0)), 0.0, float(player.get("max_flashlight_battery"))))
    player.set("darkness_exposure", clampf(float(state.get("darkness_exposure", 0.0)), 0.0, 100.0))
    player.set("inventory_names", Dictionary(state.get("inventory_names", {})).duplicate(true))
    player.set("inventory_counts", Dictionary(state.get("inventory_counts", {})).duplicate(true))
    player.set("is_dead", false)

    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if flashlight != null:
        flashlight.visible = bool(state.get("flashlight_on", true)) and float(player.get("flashlight_battery")) > 0.0

    var death_panel: Control = player.get_node_or_null("HUD/CaughtPanel") as Control
    if death_panel != null:
        death_panel.visible = false
    if player.has_method("_update_inventory_hud"):
        player.call("_update_inventory_hud")
    if player.has_method("_update_survival_hud"):
        player.call("_update_survival_hud")

func _restore_condition_state(player: CharacterBody3D, state: Dictionary) -> void:
    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth == null:
        return
    depth.set("bleeding", clampf(float(state.get("bleeding", 0.0)), 0.0, 100.0))
    depth.set("infection", clampf(float(state.get("infection", 0.0)), 0.0, 100.0))
    depth.set("last_health", float(player.get("health")))
    depth.set("tracked_player_id", int(player.get_instance_id()))

func _restore_checkpoint_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint == null:
        return
    checkpoint.set("checkpoint_active", bool(state.get("active", false)))
    checkpoint.set("checkpoint_position", _array_to_vector3(state.get("position", []), Vector3.ZERO))
    checkpoint.set("checkpoint_rotation_y", float(state.get("rotation_y", 0.0)))
    checkpoint.set("checkpoint_state", Dictionary(state.get("state", {})).duplicate(true))
    checkpoint.set("checkpoint_name", str(state.get("name", "")))
    checkpoint.set("restore_pending", false)

func _restore_journal_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return

    journal.set("entries", Dictionary(state.get("entries", {})).duplicate(true))
    var restored_order: Array[String] = []
    var order_variant: Variant = state.get("order", [])
    if order_variant is Array:
        for entry_variant: Variant in Array(order_variant):
            restored_order.append(str(entry_variant))
    journal.set("entry_order", restored_order)
    journal.set("current_entry_index", clampi(int(state.get("index", 0)), 0, maxi(0, restored_order.size() - 1)))
    if journal.has_method("_update_entry_display"):
        journal.call("_update_entry_display")
    if journal.has_method("_update_mission"):
        journal.call("_update_mission")

func _restore_door(door: Node, open_state: bool, locked_door: bool, unlocked_state: bool) -> void:
    if door == null:
        return
    var door_3d: Node3D = door as Node3D
    if door_3d == null:
        return

    door.set("is_moving", false)
    door.set("pending_collision_restore", false)
    door.set("is_open", open_state)
    if locked_door:
        door.set("unlocked", unlocked_state)

    var closed_y: float = float(door.get("closed_rotation_y"))
    var open_angle: float = float(door.get("open_angle_degrees"))
    door_3d.rotation.y = closed_y + deg_to_rad(open_angle if open_state else 0.0)
    if door.has_method("_set_collision_enabled"):
        door.call("_set_collision_enabled", true)

func _merge_network_claims() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        return
    var claimed: Dictionary = Dictionary(network.get("claimed_pickups"))
    for path_variant: Variant in claimed.keys():
        var pickup_path: String = str(path_variant)
        if bool(claimed.get(path_variant, false)):
            persistent_claimed_pickups[pickup_path] = true

func _apply_claims_to_network() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        return
    network.set("claimed_pickups", persistent_claimed_pickups.duplicate(true))

func _clear_network_claims() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        network.set("claimed_pickups", {})
        network.set("pending_pickups", {})

func _remove_current_claimed_nodes() -> void:
    for path_variant: Variant in persistent_claimed_pickups.keys():
        var pickup_path: String = str(path_variant)
        var pickup: Node = get_node_or_null(NodePath(pickup_path))
        if pickup != null:
            pickup.queue_free()

func _vector3_to_array(value: Vector3) -> Array[float]:
    return [value.x, value.y, value.z]

func _array_to_vector3(value: Variant, fallback: Vector3) -> Vector3:
    if not (value is Array):
        return fallback
    var values: Array = Array(value)
    if values.size() < 3:
        return fallback
    return Vector3(float(values[0]), float(values[1]), float(values[2]))

func _is_local_player_downed() -> bool:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return false
    return bool(coop.get("local_downed"))

func _set_objective(player: CharacterBody3D, text: String) -> void:
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _show_status(text: String) -> void:
    if status_label != null:
        status_label.text = text
        status_timer = 2.6

func _idle_status_text() -> String:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
    return "" if mobile_active else "K SAVE  |  L LOAD"

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "SaveUI"
    layer.layer = 29
    add_child(layer)

    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(status_label)

    save_button = Button.new()
    save_button.text = "SAVE"
    save_button.focus_mode = Control.FOCUS_NONE
    save_button.pressed.connect(_mobile_save)
    layer.add_child(save_button)

    load_button = Button.new()
    load_button.text = "LOAD"
    load_button.focus_mode = Control.FOCUS_NONE
    load_button.pressed.connect(_mobile_load)
    layer.add_child(load_button)
    status_label.text = _idle_status_text()
    _layout_ui()

func _layout_ui() -> void:
    if status_label == null or save_button == null or load_button == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

    status_label.offset_left = size.x - 330.0
    status_label.offset_right = size.x - 16.0
    status_label.offset_top = size.y - 42.0
    status_label.offset_bottom = size.y - 16.0
    status_label.add_theme_font_size_override("font_size", 13)

    save_button.visible = mobile_active
    load_button.visible = mobile_active
    if mobile_active:
        save_button.offset_left = 120.0
        save_button.offset_top = 46.0
        save_button.offset_right = 184.0
        save_button.offset_bottom = 88.0
        load_button.offset_left = 190.0
        load_button.offset_top = 46.0
        load_button.offset_right = 254.0
        load_button.offset_bottom = 88.0

func _mobile_save() -> void:
    save_game(false)

func _mobile_load() -> void:
    load_game()
