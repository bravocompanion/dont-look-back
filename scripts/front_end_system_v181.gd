extends "res://scripts/front_end_system.gd"

const LABYRINTH_SCENE_PATH_V181: String = "res://scenes/main.tscn"
var menu_cursor_guard_frames: int = 12
var new_game_transition_serial: int = 0

func _ready() -> void:
    super._ready()
    process_mode = Node.PROCESS_MODE_ALWAYS
    if title_box != null and title_box.get_child_count() > 1:
        var subtitle: Label = title_box.get_child(1) as Label
        if subtitle != null:
            subtitle.text = "v0.18.4.1  •  SURVIVAL HORROR"
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

func _force_menu_cursor_visible() -> void:
    if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _show_title_menu() -> void:
    super._show_title_menu()
    menu_cursor_guard_frames = 12
    _force_menu_cursor_visible()

func _open_pause_menu() -> void:
    super._open_pause_menu()
    menu_cursor_guard_frames = 4
    _force_menu_cursor_visible()

func _open_join_menu() -> void:
    super._open_join_menu()
    menu_cursor_guard_frames = 4
    _force_menu_cursor_visible()

func _open_settings() -> void:
    super._open_settings()
    menu_cursor_guard_frames = 4
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
    _unlock_local_player_if_safe()

    var movement: Node = get_node_or_null("/root/MovementSystem")
    if movement != null:
        movement.set("tracked_player_id", 0)
        movement.set("coyote_timer", 0.0)
        movement.set("jump_buffer_timer", 0.0)

    if not _mobile_active():
        _set_mouse_visible(false)
    _objective("NEW GAME: Reach the first door. Don't trust the hallway.")
