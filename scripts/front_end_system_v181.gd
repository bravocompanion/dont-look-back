extends "res://scripts/front_end_system.gd"

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
var frontend_initialized: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        return

    var on_main_menu: bool = scene.scene_file_path == MAIN_MENU_SCENE_PATH
    if on_main_menu:
        if layer != null:
            layer.visible = false
        gameplay_started = false
        menu_open = false
        current_mode = "title"
        if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        return

    if not frontend_initialized:
        _initialize_gameplay_frontend()
        if not frontend_initialized:
            return
    elif layer != null and not layer.visible:
        layer.visible = true
        gameplay_started = true
        menu_open = false
        current_mode = "gameplay"
        _set_all_panels_hidden()
        if overlay != null:
            overlay.visible = false
        _unlock_local_player_if_safe()
        if not _mobile_active():
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    super._process(delta)
    if menu_open and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
    if not frontend_initialized:
        return
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        return
    super._input(event)

func _initialize_gameplay_frontend() -> void:
    if frontend_initialized:
        return
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        return

    _load_settings()
    _apply_runtime_settings()
    _build_ui()
    frontend_initialized = true
    boot_frames = 0
    gameplay_started = true
    title_resume_available = false
    current_mode = "gameplay"
    menu_open = false

    if layer != null:
        layer.layer = 100
        layer.visible = true
    _set_all_panels_hidden()
    if overlay != null:
        overlay.visible = false
        overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _set_boot_enabled(true)
    _unlock_local_player_if_safe()
    if not _mobile_active():
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _return_to_title() -> void:
    get_tree().paused = false
    _disconnect_network_if_needed()
    gameplay_started = false
    menu_open = false
    current_mode = "title"
    if layer != null:
        layer.visible = false
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    var error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
    if error != OK and layer != null:
        layer.visible = true
        gameplay_started = true
        current_mode = "gameplay"
        menu_open = false

func _quit_game() -> void:
    get_tree().quit()
