extends Node

const SETTINGS_PATH: String = "user://dont_look_back_settings.cfg"
const SAVE_PATH: String = "user://dont_look_back_save_v1.json"
const VERSION_TEXT: String = "v0.17"

var menu_open: bool = true
var gameplay_started: bool = false
var title_resume_available: bool = false
var current_mode: String = "title"
var settings_return_mode: String = "title"
var boot_frames: int = 10
var pending_join: bool = false
var pending_join_seen_connecting: bool = false
var local_player_id: int = 0

var master_volume: float = 0.85
var look_multiplier: float = 1.0
var fps_limit: int = 60
var fullscreen_enabled: bool = false

var layer: CanvasLayer
var overlay: ColorRect
var title_panel: PanelContainer
var title_box: VBoxContainer
var pause_panel: PanelContainer
var pause_box: VBoxContainer
var join_panel: PanelContainer
var settings_panel: PanelContainer
var confirm_panel: PanelContainer
var menu_button: Button
var status_label: Label
var save_summary_label: Label
var continue_button: Button
var new_game_button: Button
var host_button: Button
var join_button: Button
var settings_button: Button
var quit_button: Button
var join_address: LineEdit
var join_submit_button: Button
var volume_slider: HSlider
var sensitivity_slider: HSlider
var fps_option: OptionButton
var fullscreen_check: CheckButton
var settings_value_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _load_settings()
    _apply_runtime_settings()
    _build_ui()
    _show_title_menu()

func _process(_delta: float) -> void:
    if boot_frames > 0:
        boot_frames -= 1
        if boot_frames == 0:
            _refresh_save_summary()
            _set_boot_enabled(true)

    _apply_player_settings()
    if menu_open:
        _lock_local_player()

    if pending_join:
        _poll_join_result()

    _layout_ui()
    _update_menu_button_visibility()

func _input(event: InputEvent) -> void:
    if not gameplay_started:
        return
    if not (event is InputEventKey):
        return

    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo or key_event.physical_keycode != KEY_ESCAPE:
        return

    var focus: Control = get_viewport().gui_get_focus_owner()
    if focus is LineEdit:
        return

    if menu_open:
        if current_mode == "pause" or current_mode == "settings":
            _resume_game()
    else:
        _open_pause_menu()
    get_viewport().set_input_as_handled()

func is_menu_open() -> bool:
    return menu_open

func _show_title_menu() -> void:
    current_mode = "title"
    menu_open = true
    _set_all_panels_hidden()
    if overlay != null:
        overlay.visible = true
    if title_panel != null:
        title_panel.visible = true
    if title_resume_available:
        continue_button.text = "RESUME CURRENT RUN"
        continue_button.disabled = false
    else:
        continue_button.text = "CONTINUE"
        continue_button.disabled = not _has_valid_save()
    _refresh_save_summary()
    _set_status("Choose how you want to enter the dark.")
    _set_mouse_visible(true)

func _open_pause_menu() -> void:
    if menu_open:
        return
    current_mode = "pause"
    menu_open = true
    _set_all_panels_hidden()
    overlay.visible = true
    pause_panel.visible = true

    if _network_online():
        _set_status("CO-OP: the world continues while this menu is open.")
    else:
        get_tree().paused = true
        _set_status("PAUSED")
    _set_mouse_visible(true)

func _resume_game() -> void:
    if not gameplay_started:
        return
    get_tree().paused = false
    current_mode = "gameplay"
    menu_open = false
    _set_all_panels_hidden()
    overlay.visible = false
    _unlock_local_player_if_safe()
    if not _mobile_active():
        _set_mouse_visible(false)

func _continue_game() -> void:
    if boot_frames > 0:
        return
    if title_resume_available:
        title_resume_available = false
        gameplay_started = true
        _resume_game()
        return
    if not _has_valid_save():
        _set_status("No valid save found. Start a NEW GAME.")
        return

    gameplay_started = true
    _resume_game()
    _objective("Continue restored. Check the Journal for your current mission.")

func _new_game_pressed() -> void:
    if boot_frames > 0:
        return
    if FileAccess.file_exists(SAVE_PATH) or title_resume_available:
        current_mode = "confirm_new"
        _set_all_panels_hidden()
        overlay.visible = true
        confirm_panel.visible = true
        _set_status("Starting over will delete the current persistent world save.")
    else:
        _start_new_game_confirmed()

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

    var reload_error: Error = get_tree().reload_current_scene()
    if reload_error != OK:
        _set_status("New Game failed: scene reload error.")
        _show_title_menu()
        return

    current_mode = "boot_new"
    _set_all_panels_hidden()
    overlay.visible = true
    _set_status("Starting a new nightmare...")
    call_deferred("_finish_new_game_after_reload")

func _finish_new_game_after_reload() -> void:
    for _index: int in range(6):
        await get_tree().process_frame
    gameplay_started = true
    current_mode = "gameplay"
    menu_open = false
    overlay.visible = false
    _set_all_panels_hidden()
    _unlock_local_player_if_safe()
    if not _mobile_active():
        _set_mouse_visible(false)
    _objective("NEW GAME: Reach the first door. Don't trust the hallway.")

func _host_coop() -> void:
    if boot_frames > 0:
        return
    _disconnect_network_if_needed()
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("host_game"):
        _set_status("NetworkManager is not available.")
        return

    network.call("host_game")
    if not _network_online():
        _set_status("Host failed. Check the co-op status message.")
        return

    gameplay_started = true
    title_resume_available = false
    current_mode = "gameplay"
    menu_open = false
    _set_all_panels_hidden()
    overlay.visible = false
    _hide_legacy_network_lobby()
    _set_mouse_visible(true)
    _set_status("Host created. Set name, READY, then START.")

func _open_join_menu() -> void:
    current_mode = "join"
    menu_open = true
    _set_all_panels_hidden()
    overlay.visible = true
    join_panel.visible = true
    pending_join = false
    pending_join_seen_connecting = false
    join_submit_button.disabled = false

    var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
    if polish != null:
        var saved_address: String = str(polish.get("last_host_address"))
        if not saved_address.is_empty():
            join_address.text = saved_address
    _set_status("Enter the host LAN IPv4 address.")
    _set_mouse_visible(true)

func _join_coop_submit() -> void:
    if pending_join:
        return
    var address: String = join_address.text.strip_edges()
    if address.is_empty():
        _set_status("Enter a host IPv4 address, for example 192.168.1.10")
        return

    _disconnect_network_if_needed()
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("join_game"):
        _set_status("NetworkManager is not available.")
        return

    pending_join = true
    pending_join_seen_connecting = false
    join_submit_button.disabled = true
    network.call("join_game", address)
    _set_status("Connecting to %s..." % address)

func _poll_join_result() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        pending_join = false
        join_submit_button.disabled = false
        _set_status("Connection failed: NetworkManager missing.")
        return

    var connecting: bool = bool(network.get("connecting"))
    if connecting:
        pending_join_seen_connecting = true

    if _network_online():
        pending_join = false
        join_submit_button.disabled = false
        gameplay_started = true
        title_resume_available = false
        current_mode = "gameplay"
        menu_open = false
        _set_all_panels_hidden()
        overlay.visible = false
        _hide_legacy_network_lobby()
        _set_mouse_visible(true)
        return

    if pending_join_seen_connecting and not connecting:
        pending_join = false
        join_submit_button.disabled = false
        _set_status("Could not connect. Check the host IP, Wi-Fi/LAN, and port 24877.")

func _open_settings() -> void:
    settings_return_mode = "pause" if gameplay_started and current_mode == "pause" else "title"
    current_mode = "settings"
    menu_open = true
    _set_all_panels_hidden()
    overlay.visible = true
    settings_panel.visible = true
    _sync_settings_controls()
    _set_status("Settings are saved on this device.")

func _close_settings() -> void:
    _save_settings()
    _apply_runtime_settings()
    if settings_return_mode == "pause" and gameplay_started:
        current_mode = "pause"
        _set_all_panels_hidden()
        overlay.visible = true
        pause_panel.visible = true
    else:
        _show_title_menu()

func _save_world_from_pause() -> void:
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system == null or not save_system.has_method("save_game"):
        _set_status("SaveSystem is not available.")
        return
    var success: bool = bool(save_system.call("save_game", false))
    _set_status("WORLD SAVED" if success else "Save failed or client is not host-authoritative.")
    _refresh_save_summary()

func _return_to_title() -> void:
    var was_client: bool = false
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("is_client"):
        was_client = bool(network.call("is_client"))

    get_tree().paused = false
    _disconnect_network_if_needed()
    title_resume_available = not was_client
    gameplay_started = false
    _show_title_menu()

func _quit_game() -> void:
    get_tree().quit()

func _cancel_confirmation() -> void:
    _show_title_menu()

func _on_volume_changed(value: float) -> void:
    master_volume = clampf(value, 0.0, 1.0)
    _apply_runtime_settings()
    _update_settings_value_label()

func _on_sensitivity_changed(value: float) -> void:
    look_multiplier = clampf(value, 0.5, 2.0)
    _apply_player_settings()
    _update_settings_value_label()

func _on_fps_selected(index: int) -> void:
    match index:
        0:
            fps_limit = 30
        1:
            fps_limit = 60
        2:
            fps_limit = 120
        _:
            fps_limit = 60
    _apply_runtime_settings()
    _update_settings_value_label()

func _on_fullscreen_toggled(value: bool) -> void:
    fullscreen_enabled = value
    _apply_runtime_settings()

func _load_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    var error: Error = config.load(SETTINGS_PATH)
    if error != OK:
        fps_limit = 60
        fullscreen_enabled = false
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

    if not _mobile_active() and not OS.has_feature("web"):
        var desired_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
        if DisplayServer.window_get_mode() != desired_mode:
            DisplayServer.window_set_mode(desired_mode)

func _apply_player_settings() -> void:
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    player.set("mouse_sensitivity", 0.0022 * look_multiplier)
    player.set("touch_look_sensitivity", 0.0032 * look_multiplier)

func _lock_local_player() -> void:
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    player.velocity = Vector3.ZERO
    player.set_process(false)
    player.set_physics_process(false)
    player.set_process_unhandled_input(false)
    _set_mobile_blocked(true)

func _unlock_local_player_if_safe() -> void:
    _set_mobile_blocked(false)
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return

    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null and bool(coop.get("local_downed")):
        return

    if _network_online():
        var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
        if polish != null and not bool(polish.get("session_started")):
            return

    player.set_process(true)
    player.set_physics_process(true)
    player.set_process_unhandled_input(true)

func _set_mobile_blocked(blocked: bool) -> void:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile != null and mobile.has_method("set_dead_mode"):
        if blocked:
            mobile.call("set_dead_mode", true)
        else:
            var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
            var downed: bool = coop != null and bool(coop.get("local_downed"))
            var player: CharacterBody3D = _get_local_player()
            var dead: bool = player != null and bool(player.get("is_dead"))
            mobile.call("set_dead_mode", downed or dead)

func _disconnect_network_if_needed() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("disconnect_game"):
        var online: bool = false
        if network.has_method("is_online"):
            online = bool(network.call("is_online"))
        var connecting: bool = bool(network.get("connecting"))
        if online or connecting:
            network.call("disconnect_game", false)

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

func _hide_legacy_network_lobby() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        return
    var lobby_value: Variant = network.get("lobby_panel")
    if lobby_value is PanelContainer:
        var lobby: PanelContainer = lobby_value
        lobby.visible = false

func _get_local_player() -> CharacterBody3D:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return null
    local_player_id = int(player.get_instance_id())
    return player

func _objective(text: String) -> void:
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _has_valid_save() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not (parsed is Dictionary):
        return false
    var state: Dictionary = parsed
    return int(state.get("format_version", 0)) > 0

func _refresh_save_summary() -> void:
    if save_summary_label == null or continue_button == null:
        return
    if title_resume_available:
        save_summary_label.text = "CURRENT RUN IN MEMORY\nResume without reloading the disk save."
        continue_button.disabled = false
        return
    if not FileAccess.file_exists(SAVE_PATH):
        save_summary_label.text = "NO SAVE DATA\nA new run will create autosaves at major checkpoints."
        continue_button.disabled = true
        return

    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        save_summary_label.text = "SAVE DATA UNREADABLE"
        continue_button.disabled = true
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not (parsed is Dictionary):
        save_summary_label.text = "SAVE DATA INVALID\nUse NEW GAME to reset the persistent world."
        continue_button.disabled = true
        return

    var state: Dictionary = parsed
    var world: Dictionary = Dictionary(state.get("world", {}))
    var checkpoint: Dictionary = Dictionary(state.get("checkpoint", {}))
    var day_index: int = int(world.get("day_index", 1))
    var minutes: int = int(round(float(world.get("game_minutes", 990.0)))) % 1440
    var hour: int = minutes / 60
    var minute: int = minutes % 60
    var checkpoint_name: String = str(checkpoint.get("name", "No checkpoint"))
    if checkpoint_name.is_empty():
        checkpoint_name = "No checkpoint"
    save_summary_label.text = "CONTINUE AVAILABLE\nDay %d • %02d:%02d • %s" % [day_index, hour, minute, checkpoint_name]
    continue_button.disabled = false

func _set_boot_enabled(enabled: bool) -> void:
    if new_game_button != null:
        new_game_button.disabled = not enabled
    if host_button != null:
        host_button.disabled = not enabled
    if join_button != null:
        join_button.disabled = not enabled
    if continue_button != null:
        continue_button.disabled = not enabled or (not title_resume_available and not _has_valid_save())

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "FrontEndUI"
    layer.layer = 100
    add_child(layer)

    overlay = ColorRect.new()
    overlay.name = "FrontEndOverlay"
    overlay.color = Color(0.004, 0.006, 0.009, 0.965)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 14)
    layer.add_child(status_label)

    title_panel = _make_panel()
    layer.add_child(title_panel)
    title_box = VBoxContainer.new()
    title_box.add_theme_constant_override("separation", 9)
    title_panel.add_child(title_box)

    var title: Label = Label.new()
    title.text = "DON'T LOOK BACK"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title_box.add_child(title)

    var subtitle: Label = Label.new()
    subtitle.text = "%s  •  SURVIVAL HORROR" % VERSION_TEXT
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 14)
    title_box.add_child(subtitle)

    save_summary_label = Label.new()
    save_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    save_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    save_summary_label.add_theme_font_size_override("font_size", 14)
    title_box.add_child(save_summary_label)

    continue_button = _menu_button("CONTINUE", _continue_game)
    new_game_button = _menu_button("NEW GAME", _new_game_pressed)
    host_button = _menu_button("HOST CO-OP", _host_coop)
    join_button = _menu_button("JOIN CO-OP", _open_join_menu)
    settings_button = _menu_button("SETTINGS", _open_settings)
    quit_button = _menu_button("QUIT", _quit_game)
    title_box.add_child(continue_button)
    title_box.add_child(new_game_button)
    title_box.add_child(host_button)
    title_box.add_child(join_button)
    title_box.add_child(settings_button)
    title_box.add_child(quit_button)

    pause_panel = _make_panel()
    layer.add_child(pause_panel)
    pause_box = VBoxContainer.new()
    pause_box.add_theme_constant_override("separation", 10)
    pause_panel.add_child(pause_box)

    var pause_title: Label = Label.new()
    pause_title.text = "MENU"
    pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_title.add_theme_font_size_override("font_size", 30)
    pause_box.add_child(pause_title)
    pause_box.add_child(_menu_button("RESUME", _resume_game))
    pause_box.add_child(_menu_button("SAVE WORLD", _save_world_from_pause))
    pause_box.add_child(_menu_button("SETTINGS", _open_settings))
    pause_box.add_child(_menu_button("RETURN TO TITLE", _return_to_title))
    var pause_quit: Button = _menu_button("QUIT", _quit_game)
    pause_quit.visible = not _mobile_platform()
    pause_box.add_child(pause_quit)

    join_panel = _make_panel()
    layer.add_child(join_panel)
    var join_box: VBoxContainer = VBoxContainer.new()
    join_box.add_theme_constant_override("separation", 10)
    join_panel.add_child(join_box)
    var join_title: Label = Label.new()
    join_title.text = "JOIN CO-OP"
    join_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    join_title.add_theme_font_size_override("font_size", 28)
    join_box.add_child(join_title)
    var join_help: Label = Label.new()
    join_help.text = "Same Wi-Fi/LAN • host port 24877"
    join_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    join_box.add_child(join_help)
    join_address = LineEdit.new()
    join_address.placeholder_text = "Host IPv4 • 192.168.x.x"
    join_address.text = "127.0.0.1"
    join_box.add_child(join_address)
    join_submit_button = _menu_button("CONNECT", _join_coop_submit)
    join_box.add_child(join_submit_button)
    join_box.add_child(_menu_button("BACK", _show_title_menu))

    settings_panel = _make_panel()
    layer.add_child(settings_panel)
    var settings_box: VBoxContainer = VBoxContainer.new()
    settings_box.add_theme_constant_override("separation", 8)
    settings_panel.add_child(settings_box)
    var settings_title: Label = Label.new()
    settings_title.text = "SETTINGS"
    settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    settings_title.add_theme_font_size_override("font_size", 28)
    settings_box.add_child(settings_title)

    var volume_label: Label = Label.new()
    volume_label.text = "MASTER VOLUME"
    settings_box.add_child(volume_label)
    volume_slider = HSlider.new()
    volume_slider.min_value = 0.0
    volume_slider.max_value = 1.0
    volume_slider.step = 0.05
    volume_slider.value_changed.connect(_on_volume_changed)
    settings_box.add_child(volume_slider)

    var sensitivity_label: Label = Label.new()
    sensitivity_label.text = "LOOK SENSITIVITY"
    settings_box.add_child(sensitivity_label)
    sensitivity_slider = HSlider.new()
    sensitivity_slider.min_value = 0.5
    sensitivity_slider.max_value = 2.0
    sensitivity_slider.step = 0.05
    sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
    settings_box.add_child(sensitivity_slider)

    var fps_label: Label = Label.new()
    fps_label.text = "PERFORMANCE / FPS LIMIT"
    settings_box.add_child(fps_label)
    fps_option = OptionButton.new()
    fps_option.add_item("BATTERY SAVER • 30 FPS")
    fps_option.add_item("BALANCED • 60 FPS")
    fps_option.add_item("HIGH • 120 FPS")
    fps_option.item_selected.connect(_on_fps_selected)
    settings_box.add_child(fps_option)

    fullscreen_check = CheckButton.new()
    fullscreen_check.text = "FULLSCREEN"
    fullscreen_check.toggled.connect(_on_fullscreen_toggled)
    fullscreen_check.visible = not _mobile_platform() and not OS.has_feature("web")
    settings_box.add_child(fullscreen_check)

    settings_value_label = Label.new()
    settings_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    settings_box.add_child(settings_value_label)
    settings_box.add_child(_menu_button("BACK", _close_settings))

    confirm_panel = _make_panel()
    layer.add_child(confirm_panel)
    var confirm_box: VBoxContainer = VBoxContainer.new()
    confirm_box.add_theme_constant_override("separation", 12)
    confirm_panel.add_child(confirm_box)
    var confirm_title: Label = Label.new()
    confirm_title.text = "START A NEW GAME?"
    confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    confirm_title.add_theme_font_size_override("font_size", 26)
    confirm_box.add_child(confirm_title)
    var confirm_text: Label = Label.new()
    confirm_text.text = "The current persistent world save will be deleted.\nJournal discoveries, finite loot state, and world progress will reset."
    confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    confirm_box.add_child(confirm_text)
    confirm_box.add_child(_menu_button("DELETE SAVE & START", _start_new_game_confirmed))
    confirm_box.add_child(_menu_button("CANCEL", _cancel_confirmation))

    menu_button = Button.new()
    menu_button.text = "MENU"
    menu_button.focus_mode = Control.FOCUS_NONE
    menu_button.pressed.connect(_open_pause_menu)
    layer.add_child(menu_button)

    _sync_settings_controls()
    _set_boot_enabled(false)
    _set_all_panels_hidden()

func _make_panel() -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.041, 0.048, 0.98)
    style.border_color = Color(0.42, 0.46, 0.48, 0.32)
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    style.content_margin_left = 22.0
    style.content_margin_right = 22.0
    style.content_margin_top = 20.0
    style.content_margin_bottom = 20.0
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _menu_button(text: String, callback: Callable) -> Button:
    var button: Button = Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(260.0, 44.0)
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(callback)
    return button

func _set_all_panels_hidden() -> void:
    if title_panel != null:
        title_panel.visible = false
    if pause_panel != null:
        pause_panel.visible = false
    if join_panel != null:
        join_panel.visible = false
    if settings_panel != null:
        settings_panel.visible = false
    if confirm_panel != null:
        confirm_panel.visible = false

func _sync_settings_controls() -> void:
    if volume_slider != null:
        volume_slider.value = master_volume
    if sensitivity_slider != null:
        sensitivity_slider.value = look_multiplier
    if fps_option != null:
        var index: int = 1
        if fps_limit == 30:
            index = 0
        elif fps_limit == 120:
            index = 2
        fps_option.select(index)
    if fullscreen_check != null:
        fullscreen_check.button_pressed = fullscreen_enabled
    _update_settings_value_label()

func _update_settings_value_label() -> void:
    if settings_value_label != null:
        settings_value_label.text = "Volume %d%%  •  Look %.2fx  •  %d FPS" % [int(round(master_volume * 100.0)), look_multiplier, fps_limit]

func _set_status(text: String) -> void:
    if status_label != null:
        status_label.text = text

func _set_mouse_visible(visible: bool) -> void:
    if _mobile_active():
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        return
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED)

func _mobile_platform() -> bool:
    return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

func _update_menu_button_visibility() -> void:
    if menu_button == null:
        return
    menu_button.visible = gameplay_started and not menu_open and _mobile_active()

func _layout_ui() -> void:
    if title_panel == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = size.x < 800.0 or size.y < 620.0

    if compact:
        _set_panel_rect(title_panel, Vector2(340.0, 500.0))
        _set_panel_rect(pause_panel, Vector2(330.0, 360.0))
        _set_panel_rect(join_panel, Vector2(340.0, 270.0))
        _set_panel_rect(settings_panel, Vector2(350.0, 430.0))
        _set_panel_rect(confirm_panel, Vector2(350.0, 300.0))
    else:
        _set_panel_rect(title_panel, Vector2(440.0, 530.0))
        _set_panel_rect(pause_panel, Vector2(390.0, 390.0))
        _set_panel_rect(join_panel, Vector2(420.0, 280.0))
        _set_panel_rect(settings_panel, Vector2(440.0, 450.0))
        _set_panel_rect(confirm_panel, Vector2(440.0, 310.0))

    status_label.offset_left = maxf(12.0, size.x * 0.5 - 320.0)
    status_label.offset_right = minf(size.x - 12.0, size.x * 0.5 + 320.0)
    status_label.offset_top = size.y - 52.0
    status_label.offset_bottom = size.y - 16.0

    menu_button.size = Vector2(90.0, 42.0)
    menu_button.position = Vector2(size.x - 102.0, 12.0)
    quit_button.visible = not _mobile_platform()

func _set_panel_rect(panel: PanelContainer, panel_size: Vector2) -> void:
    panel.offset_left = -panel_size.x * 0.5
    panel.offset_top = -panel_size.y * 0.5
    panel.offset_right = panel_size.x * 0.5
    panel.offset_bottom = panel_size.y * 0.5
