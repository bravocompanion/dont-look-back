extends "res://scripts/front_end_system.gd"

const LABYRINTH_SCENE_PATH_V181: String = "res://scenes/main.tscn"
var menu_cursor_guard_frames: int = 12
var new_game_transition_serial: int = 0

func _ready() -> void:
    super._ready()
    process_mode = Node.PROCESS_MODE_ALWAYS
    if layer != null:
        layer.layer = 200
    if title_box != null and title_box.get_child_count() > 1:
        var subtitle: Label = title_box.get_child(1) as Label
        if subtitle != null:
            subtitle.text = "v0.18.4.3  •  SURVIVAL HORROR"
    _force_menu_input_ready()
    _force_menu_cursor_visible()

func _process(delta: float) -> void:
    super._process(delta)

    # Player._ready() captures the mouse when the gameplay scene is created.
    # The front end owns cursor state while any menu is open, so keep restoring
    # VISIBLE after scene/bootstrap initialization and on every menu frame.
    if menu_cursor_guard_frames > 0:
        menu_cursor_guard_frames -= 1
        if menu_open:
            _force_menu_cursor_visible()
    elif menu_open:
        _force_menu_cursor_visible()

    if menu_open:
        _force_menu_input_ready()
    elif layer != null and layer.layer != 100:
        # Let the map-loading layer (120) sit above normal gameplay UI.
        layer.layer = 100

func _input(event: InputEvent) -> void:
    super._input(event)
    if not menu_open or layer == null:
        return

    var pointer_position: Vector2 = Vector2.ZERO
    var pointer_pressed: bool = false

    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            pointer_position = mouse_event.position
            pointer_pressed = true
    elif event is InputEventScreenTouch:
        var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
        if touch_event.pressed:
            pointer_position = touch_event.position
            pointer_pressed = true

    if not pointer_pressed:
        return

    # Fallback router: _input runs before GUI picking. If another transparent
    # Control ever overlaps the front end, directly dispatch the visible button
    # under the pointer instead of relying exclusively on _gui_input().
    var target: BaseButton = _find_frontend_button(layer, pointer_position)
    if target == null or target.disabled:
        return

    if target is CheckButton:
        var check: CheckButton = target as CheckButton
        check.button_pressed = not check.button_pressed
    target.pressed.emit()
    get_viewport().set_input_as_handled()

func _find_frontend_button(root: Node, point: Vector2) -> BaseButton:
    var children: Array[Node] = root.get_children()
    for index: int in range(children.size() - 1, -1, -1):
        var child: Node = children[index]
        if child is CanvasItem:
            var canvas_item: CanvasItem = child as CanvasItem
            if not canvas_item.is_visible_in_tree():
                continue
        var nested: BaseButton = _find_frontend_button(child, point)
        if nested != null:
            return nested

    if root is BaseButton:
        var button: BaseButton = root as BaseButton
        if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(point):
            return button
    return null

func _force_menu_cursor_visible() -> void:
    if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _force_menu_input_ready() -> void:
    # Keep the front end above every gameplay/loading layer while a menu is open.
    if layer != null:
        layer.layer = 200

    # Decorative fullscreen controls must not consume pointer/touch input.
    if overlay != null:
        overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # Once the short boot window has completed, keep actionable title controls
    # explicitly enabled. This protects against stale disabled state after a
    # scene reload/save autoload while leaving CONTINUE dependent on save data.
    if boot_frames <= 0:
        if new_game_button != null:
            new_game_button.disabled = false
        if host_button != null:
            host_button.disabled = false
        if join_button != null:
            join_button.disabled = false
        if settings_button != null:
            settings_button.disabled = false
        if quit_button != null:
            quit_button.disabled = false
        if continue_button != null:
            continue_button.disabled = not title_resume_available and not _has_valid_save()

func _show_title_menu() -> void:
    super._show_title_menu()
    menu_cursor_guard_frames = 12
    _force_menu_input_ready()
    _force_menu_cursor_visible()

func _open_pause_menu() -> void:
    super._open_pause_menu()
    menu_cursor_guard_frames = 4
    _force_menu_input_ready()
    _force_menu_cursor_visible()

func _open_join_menu() -> void:
    super._open_join_menu()
    menu_cursor_guard_frames = 4
    _force_menu_input_ready()
    _force_menu_cursor_visible()

func _open_settings() -> void:
    super._open_settings()
    menu_cursor_guard_frames = 4
    _force_menu_input_ready()
    _force_menu_cursor_visible()

func _start_new_game_confirmed() -> void:
    get_tree().paused = false
    pending_join = false
    pending_join_seen_connecting = false
    title_resume_available = false
    gameplay_started = false
    menu_open = true
    current_mode = "boot_new"
    _disconnect_network_if_needed()
    _set_mobile_blocked(true)

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null:
        if save_system.has_method("delete_save"):
            var deleted: bool = bool(save_system.call("delete_save"))
            if not deleted:
                _set_status("New Game failed: save file could not be reset.")
                _show_title_menu()
                return
        if save_system.has_method("_prepare_clean_reload"):
            save_system.call("_prepare_clean_reload")

    var movement: Node = get_node_or_null("/root/MovementSystem")
    if movement != null:
        movement.set("tracked_player_id", 0)
        movement.set("coyote_timer", 0.0)
        movement.set("jump_buffer_timer", 0.0)

    _set_all_panels_hidden()
    if overlay != null:
        overlay.visible = true
        overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _set_status("Starting a new nightmare...")
    menu_cursor_guard_frames = 12
    _force_menu_cursor_visible()

    new_game_transition_serial += 1
    var transition_serial: int = new_game_transition_serial
    var change_error: Error = get_tree().change_scene_to_file(LABYRINTH_SCENE_PATH_V181)
    if change_error != OK:
        _set_status("New Game failed: labyrinth map could not load.")
        _show_title_menu()
        return

    call_deferred("_finish_new_game_when_ready", transition_serial)

func _finish_new_game_when_ready(transition_serial: int) -> void:
    var player: CharacterBody3D = null
    var world_ready: bool = false

    # Do not assume a fixed number of frames. Labyrinth geometry is created by
    # an autoload after the scene becomes current, and slower/mobile devices can
    # need more than the old six-frame delay.
    for _frame_index: int in range(180):
        await get_tree().process_frame
        if transition_serial != new_game_transition_serial:
            return

        var scene: Node = get_tree().current_scene
        if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH_V181:
            continue

        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        world_ready = scene.get_node_or_null("LabyrinthExpansion") != null
        if player != null and world_ready:
            break

    if transition_serial != new_game_transition_serial:
        return

    if player == null or not world_ready:
        gameplay_started = false
        current_mode = "title"
        menu_open = true
        _show_title_menu()
        _set_status("New Game failed: Labyrinth did not finish loading. Try again or send the Godot error output.")
        return

    player.velocity = Vector3.ZERO
    player.set("is_dead", false)
    player.set("health", float(player.get("max_health")))
    player.set("hunger", float(player.get("max_hunger")))
    player.set("thirst", float(player.get("max_thirst")))
    player.set("stamina", float(player.get("max_stamina")))
    player.set("darkness_exposure", 0.0)

    gameplay_started = true
    current_mode = "gameplay"
    menu_open = false
    _set_all_panels_hidden()
    if overlay != null:
        overlay.visible = false
    if layer != null:
        layer.layer = 100
    _unlock_local_player_if_safe()

    var movement: Node = get_node_or_null("/root/MovementSystem")
    if movement != null:
        movement.set("tracked_player_id", 0)
        movement.set("coyote_timer", 0.0)
        movement.set("jump_buffer_timer", 0.0)

    if not _mobile_active():
        _set_mouse_visible(false)
    _objective("NEW GAME: Reach the first door. Don't trust the hallway.")
