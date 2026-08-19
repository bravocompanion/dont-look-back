extends "res://scripts/front_end_system.gd"

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu_ranger.tscn"
const LEGACY_MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const FLASHLIGHT_MOTION_SYSTEM_SCRIPT: String = "res://scripts/flashlight_motion_system_v40.gd"
const DYNAMIC_AUDIO_SYSTEM_SCRIPT: String = "res://scripts/dynamic_audio_system.gd"
const PANIC_TENANT_SYSTEM_SCRIPT: String = "res://scripts/panic_tenant_system.gd"
const PANIC_INPUT_SYSTEM_SCRIPT: String = "res://scripts/panic_input_system.gd"
const TENANT_PANIC_NETWORK_BRIDGE_SCRIPT: String = "res://scripts/tenant_panic_network_bridge.gd"
const TENANT_FLASHLIGHT_FX_SYSTEM_SCRIPT: String = "res://scripts/tenant_flashlight_fx_system.gd"
const TENANT_DEATH_FEEDBACK_SYSTEM_SCRIPT: String = "res://scripts/tenant_death_feedback_system.gd"
const VERSION_BADGE_TEXT: String = "v0.43  •  STABLE ITEM ICONS  •  RADIATION SURVIVAL"
var frontend_initialized: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_runtime_support_systems()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    if not OS.has_feature("mobile") and not OS.has_feature("web_android") and not OS.has_feature("web_ios"):
        Input.emulate_touch_from_mouse = false
    Input.emulate_mouse_from_touch = true

func _process(delta: float) -> void:
    _ensure_runtime_support_systems()
    var scene: Node = get_tree().current_scene
    if scene == null:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        return

    var on_main_menu: bool = _is_main_menu_scene(scene)
    if on_main_menu:
        if layer != null:
            layer.visible = false
        gameplay_started = false
        menu_open = false
        current_mode = "title"

        var version_label: Label = scene.get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/Version") as Label
        if version_label != null and version_label.text != VERSION_BADGE_TEXT:
            version_label.text = VERSION_BADGE_TEXT

        var mobile: Node = get_node_or_null("/root/MobileControls")
        if mobile != null and mobile.has_method("set_external_blocked") and mobile.has_method("is_external_blocked"):
            if not bool(mobile.call("is_external_blocked")):
                mobile.call("set_external_blocked", true)

        if not OS.has_feature("mobile") and not OS.has_feature("web_android") and not OS.has_feature("web_ios"):
            Input.emulate_touch_from_mouse = false
        Input.emulate_mouse_from_touch = true
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
    if scene == null or _is_main_menu_scene(scene):
        return
    super._input(event)

func _initialize_gameplay_frontend() -> void:
    if frontend_initialized:
        return
    var scene: Node = get_tree().current_scene
    if scene == null or _is_main_menu_scene(scene):
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

func _ensure_runtime_support_systems() -> void:
    _ensure_root_system("PanicTenantSystem", PANIC_TENANT_SYSTEM_SCRIPT)
    _ensure_root_system("PanicInputSystem", PANIC_INPUT_SYSTEM_SCRIPT)
    _ensure_root_system("FlashlightMotionSystem", FLASHLIGHT_MOTION_SYSTEM_SCRIPT)
    _ensure_root_system("TenantFlashlightFXSystem", TENANT_FLASHLIGHT_FX_SYSTEM_SCRIPT)
    _ensure_root_system("DynamicAudioSystem", DYNAMIC_AUDIO_SYSTEM_SCRIPT)
    _ensure_root_system("TenantPanicNetworkBridge", TENANT_PANIC_NETWORK_BRIDGE_SCRIPT)
    _ensure_root_system("TenantDeathFeedbackSystem", TENANT_DEATH_FEEDBACK_SYSTEM_SCRIPT)

func _ensure_root_system(node_name: String, script_path: String) -> void:
    if get_node_or_null("/root/%s" % node_name) != null:
        return
    var runtime_script: Script = load(script_path) as Script
    if runtime_script == null:
        return
    var runtime_node: Node = Node.new()
    runtime_node.name = node_name
    runtime_node.set_script(runtime_script)
    get_tree().root.add_child(runtime_node)

func _is_main_menu_scene(scene: Node) -> bool:
    if scene == null:
        return false
    return scene.scene_file_path == MAIN_MENU_SCENE_PATH or scene.scene_file_path == LEGACY_MAIN_MENU_SCENE_PATH

func _return_to_title() -> void:
    get_tree().paused = false
    _disconnect_network_if_needed()
    gameplay_started = false
    menu_open = false
    current_mode = "title"
    if layer != null:
        layer.visible = false
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    var change_error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
    if change_error != OK and layer != null:
        layer.visible = true
        gameplay_started = true
        current_mode = "gameplay"
        menu_open = false

func _quit_game() -> void:
    get_tree().quit()
