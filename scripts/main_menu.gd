extends Control

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const SAVE_PATH: String = "user://dont_look_back_save_v1.json"
const SETTINGS_PATH: String = "user://dont_look_back_settings.cfg"
const VERSION_TEXT: String = "v0.18.4.4"

@onready var main_panel: PanelContainer = $MenuLayer/Root/Center/MainPanel
@onready var save_summary: Label = $MenuLayer/Root/Center/MainPanel/VBox/SaveSummary
@onready var continue_button: Button = $MenuLayer/Root/Center/MainPanel/VBox/ContinueButton
@onready var new_game_button: Button = $MenuLayer/Root/Center/MainPanel/VBox/NewGameButton
@onready var host_button: Button = $MenuLayer/Root/Center/MainPanel/VBox/HostButton
@onready var join_button: Button = $MenuLayer/Root/Center/MainPanel/VBox/JoinButton
@onready var settings_button: Button = $MenuLayer/Root/Center/MainPanel/VBox/SettingsButton
@onready var quit_button: Button = $MenuLayer/Root/Center/MainPanel/VBox/QuitButton
@onready var status_label: Label = $MenuLayer/Root/Status

@onready var join_panel: PanelContainer = $MenuLayer/Root/Center/JoinPanel
@onready var join_address: LineEdit = $MenuLayer/Root/Center/JoinPanel/VBox/Address
@onready var join_connect_button: Button = $MenuLayer/Root/Center/JoinPanel/VBox/ConnectButton

@onready var settings_panel: PanelContainer = $MenuLayer/Root/Center/SettingsPanel
@onready var volume_slider: HSlider = $MenuLayer/Root/Center/SettingsPanel/VBox/VolumeSlider
@onready var sensitivity_slider: HSlider = $MenuLayer/Root/Center/SettingsPanel/VBox/SensitivitySlider
@onready var fps_option: OptionButton = $MenuLayer/Root/Center/SettingsPanel/VBox/FpsOption
@onready var fullscreen_check: CheckButton = $MenuLayer/Root/Center/SettingsPanel/VBox/FullscreenCheck
@onready var settings_value: Label = $MenuLayer/Root/Center/SettingsPanel/VBox/SettingsValue

@onready var confirm_panel: PanelContainer = $MenuLayer/Root/Center/ConfirmPanel

var master_volume: float = 0.85
var look_multiplier: float = 1.0
var fps_limit: int = 60
var fullscreen_enabled: bool = false
var join_waiting: bool = false
var join_elapsed: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    $MenuLayer/Root/Center/MainPanel/VBox/Version.text = "%s  •  SURVIVAL HORROR" % VERSION_TEXT

    continue_button.pressed.connect(_continue_game)
    new_game_button.pressed.connect(_new_game_pressed)
    host_button.pressed.connect(_host_game)
    join_button.pressed.connect(_show_join)
    settings_button.pressed.connect(_show_settings)
    quit_button.pressed.connect(_quit_game)

    $MenuLayer/Root/Center/JoinPanel/VBox/BackButton.pressed.connect(_show_main)
    join_connect_button.pressed.connect(_connect_join)

    $MenuLayer/Root/Center/SettingsPanel/VBox/BackButton.pressed.connect(_close_settings)
    volume_slider.value_changed.connect(_on_volume_changed)
    sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
    fps_option.item_selected.connect(_on_fps_selected)
    fullscreen_check.toggled.connect(_on_fullscreen_toggled)

    $MenuLayer/Root/Center/ConfirmPanel/VBox/ConfirmButton.pressed.connect(_start_new_game)
    $MenuLayer/Root/Center/ConfirmPanel/VBox/CancelButton.pressed.connect(_show_main)

    _load_settings()
    _apply_runtime_settings()
    _sync_settings_controls()
    _refresh_save_summary()
    _show_main()

func _process(delta: float) -> void:
    if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    if not join_waiting:
        return

    join_elapsed += delta
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        join_waiting = false
        join_connect_button.disabled = false
        _set_status("NetworkManager tidak tersedia.")
        return

    var online: bool = network.has_method("is_online") and bool(network.call("is_online"))
    var connecting: bool = bool(network.get("connecting"))
    if online:
        _set_status("Terhubung. Menyamakan map dengan HOST...")
        if join_elapsed >= 1.5 and get_tree().current_scene == self:
            join_waiting = false
            get_tree().change_scene_to_file(LABYRINTH_SCENE_PATH)
        return

    if not connecting and join_elapsed > 0.35:
        join_waiting = false
        join_connect_button.disabled = false
        _set_status("Gagal terhubung. Periksa IP HOST dan LAN/Wi-Fi.")

func _continue_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        _set_status("Belum ada save. Pilih NEW GAME.")
        return

    _set_menu_buttons_enabled(false)
    _set_status("Memuat save...")
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system == null or not save_system.has_method("load_game"):
        _set_menu_buttons_enabled(true)
        _set_status("SaveSystem tidak tersedia.")
        return

    if not bool(save_system.call("load_game")):
        _set_menu_buttons_enabled(true)
        _set_status("Save tidak dapat dimuat.")

func _new_game_pressed() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        _hide_all_panels()
        confirm_panel.visible = true
        _set_status("NEW GAME akan menghapus world save saat ini.")
        return
    _start_new_game()

func _start_new_game() -> void:
    _set_menu_buttons_enabled(false)
    _set_status("Memulai nightmare baru...")
    _disconnect_network()

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null:
        if save_system.has_method("delete_save") and not bool(save_system.call("delete_save")):
            _set_menu_buttons_enabled(true)
            _show_main()
            _set_status("Save lama gagal dihapus.")
            return
        if save_system.has_method("_prepare_clean_reload"):
            save_system.call("_prepare_clean_reload")

    var movement: Node = get_node_or_null("/root/MovementSystem")
    if movement != null:
        movement.set("tracked_player_id", 0)
        movement.set("coyote_timer", 0.0)
        movement.set("jump_buffer_timer", 0.0)

    var error: Error = get_tree().change_scene_to_file(LABYRINTH_SCENE_PATH)
    if error != OK:
        _set_menu_buttons_enabled(true)
        _show_main()
        _set_status("Labyrinth gagal dibuka.")

func _host_game() -> void:
    _disconnect_network()
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("host_game"):
        _set_status("NetworkManager tidak tersedia.")
        return

    network.call("host_game")
    if not (network.has_method("is_online") and bool(network.call("is_online"))):
        _set_status("HOST gagal dibuat. Periksa status network.")
        return

    _set_menu_buttons_enabled(false)
    _set_status("HOST aktif. Membuka Labyrinth...")
    var error: Error = get_tree().change_scene_to_file(LABYRINTH_SCENE_PATH)
    if error != OK:
        _set_menu_buttons_enabled(true)
        _set_status("Labyrinth gagal dibuka.")

func _show_join() -> void:
    _hide_all_panels()
    join_panel.visible = true
    join_connect_button.disabled = false
    var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
    if polish != null:
        var saved_address: String = str(polish.get("last_host_address"))
        if not saved_address.is_empty():
            join_address.text = saved_address
    _set_status("Masukkan IPv4 HOST pada LAN/Wi-Fi yang sama.")

func _connect_join() -> void:
    var address: String = join_address.text.strip_edges()
    if address.is_empty():
        _set_status("Masukkan IP, contoh 192.168.1.10")
        return

    _disconnect_network()
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("join_game"):
        _set_status("NetworkManager tidak tersedia.")
        return

    join_waiting = true
    join_elapsed = 0.0
    join_connect_button.disabled = true
    network.call("join_game", address)
    _set_status("Menghubungkan ke %s..." % address)

func _show_settings() -> void:
    _hide_all_panels()
    settings_panel.visible = true
    _sync_settings_controls()
    _set_status("Settings disimpan di device ini.")

func _close_settings() -> void:
    _save_settings()
    _apply_runtime_settings()
    _show_main()

func _show_main() -> void:
    _hide_all_panels()
    main_panel.visible = true
    _refresh_save_summary()
    _set_status("Choose how you want to enter the dark.")

func _hide_all_panels() -> void:
    main_panel.visible = false
    join_panel.visible = false
    settings_panel.visible = false
    confirm_panel.visible = false

func _refresh_save_summary() -> void:
    var has_save: bool = FileAccess.file_exists(SAVE_PATH)
    continue_button.disabled = not has_save
    if has_save:
        save_summary.text = "CONTINUE AVAILABLE\nPersistent world save detected."
    else:
        save_summary.text = "NO SAVE DATA\nA new run will create autosaves at major checkpoints."

func _set_menu_buttons_enabled(enabled: bool) -> void:
    new_game_button.disabled = not enabled
    host_button.disabled = not enabled
    join_button.disabled = not enabled
    settings_button.disabled = not enabled
    quit_button.disabled = not enabled
    continue_button.disabled = not enabled or not FileAccess.file_exists(SAVE_PATH)

func _disconnect_network() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("disconnect_game"):
        return
    var online: bool = network.has_method("is_online") and bool(network.call("is_online"))
    var connecting: bool = bool(network.get("connecting"))
    if online or connecting:
        network.call("disconnect_game", false)

func _load_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    var error: Error = config.load(SETTINGS_PATH)
    if error != OK:
        return
    master_volume = clampf(float(config.get_value("audio", "master_volume", 0.85)), 0.0, 1.0)
    look_multiplier = clampf(float(config.get_value("controls", "look_multiplier", 1.0)), 0.5, 2.0)
    fps_limit = int(config.get_value("performance", "fps_limit", 60))
    if fps_limit not in [30, 60, 120]:
        fps_limit = 60
    fullscreen_enabled = bool(config.get_value("display", "fullscreen", false))

func _save_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("audio", "master_volume", master_volume)
    config.set_value("controls", "look_multiplier", look_multiplier)
    config.set_value("performance", "fps_limit", fps_limit)
    config.set_value("display", "fullscreen", fullscreen_enabled)
    config.save(SETTINGS_PATH)

func _apply_runtime_settings() -> void:
    var volume_db: float = -80.0 if master_volume <= 0.001 else linear_to_db(master_volume)
    AudioServer.set_bus_volume_db(0, volume_db)
    Engine.max_fps = fps_limit
    if not _mobile_platform() and not OS.has_feature("web"):
        var desired_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
        if DisplayServer.window_get_mode() != desired_mode:
            DisplayServer.window_set_mode(desired_mode)

func _sync_settings_controls() -> void:
    volume_slider.value = master_volume
    sensitivity_slider.value = look_multiplier
    var selected: int = 1
    if fps_limit == 30:
        selected = 0
    elif fps_limit == 120:
        selected = 2
    fps_option.select(selected)
    fullscreen_check.button_pressed = fullscreen_enabled
    fullscreen_check.visible = not _mobile_platform() and not OS.has_feature("web")
    _update_settings_value()

func _on_volume_changed(value: float) -> void:
    master_volume = clampf(value, 0.0, 1.0)
    _apply_runtime_settings()
    _update_settings_value()

func _on_sensitivity_changed(value: float) -> void:
    look_multiplier = clampf(value, 0.5, 2.0)
    _update_settings_value()

func _on_fps_selected(index: int) -> void:
    match index:
        0:
            fps_limit = 30
        2:
            fps_limit = 120
        _:
            fps_limit = 60
    _apply_runtime_settings()
    _update_settings_value()

func _on_fullscreen_toggled(value: bool) -> void:
    fullscreen_enabled = value
    _apply_runtime_settings()

func _update_settings_value() -> void:
    settings_value.text = "Volume %d%%  •  Look %.2fx  •  %d FPS" % [int(round(master_volume * 100.0)), look_multiplier, fps_limit]

func _quit_game() -> void:
    get_tree().quit()

func _set_status(text: String) -> void:
    status_label.text = text

func _mobile_platform() -> bool:
    return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
