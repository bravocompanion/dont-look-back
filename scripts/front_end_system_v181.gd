extends "res://scripts/front_end_system.gd"

const LABYRINTH_SCENE_PATH_V181: String = "res://scenes/main.tscn"
var menu_cursor_guard_frames: int = 12

func _ready() -> void:
    super._ready()
    process_mode = Node.PROCESS_MODE_ALWAYS
    if title_box != null and title_box.get_child_count() > 1:
        var subtitle: Label = title_box.get_child(1) as Label
        if subtitle != null:
            subtitle.text = "v0.18.3  •  SURVIVAL HORROR"
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
    title_resume_available = false
    _disconnect_network_if_needed()

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null:
        if save_system.has_method("delete_save"):
            save_system.call("delete_save")
        if save_system.has_method("_prepare_clean_reload"):
            save_system.call("_prepare_clean_reload")

    var change_error: Error = get_tree().change_scene_to_file(LABYRINTH_SCENE_PATH_V181)
    if change_error != OK:
        _set_status("New Game failed: labyrinth map could not load.")
        _show_title_menu()
        return

    current_mode = "boot_new"
    _set_all_panels_hidden()
    overlay.visible = true
    _set_status("Starting a new nightmare...")
    call_deferred("_finish_new_game_after_reload")
