extends Node

signal language_changed(language_code: String)

const LANGUAGE_PATH: String = "user://dont_look_back_language.cfg"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const SUPPORTED_LANGUAGES: Array[String] = ["en", "id"]

const UI_EN_TO_ID: Dictionary = {
    "CONTINUE": "LANJUTKAN",
    "RESUME CURRENT RUN": "LANJUTKAN SESI",
    "NEW GAME": "GAME BARU",
    "HOST CO-OP": "BUAT CO-OP",
    "JOIN CO-OP": "GABUNG CO-OP",
    "SETTINGS": "PENGATURAN",
    "QUIT": "KELUAR",
    "RESUME": "LANJUTKAN GAME",
    "SAVE WORLD": "SIMPAN DUNIA",
    "RETURN TO TITLE": "KEMBALI KE MENU UTAMA",
    "MENU": "MENU",
    "CONNECT": "HUBUNGKAN",
    "BACK": "KEMBALI",
    "MASTER VOLUME": "VOLUME UTAMA",
    "LOOK SENSITIVITY": "SENSITIVITAS PANDANGAN",
    "PERFORMANCE / FPS LIMIT": "PERFORMA / BATAS FPS",
    "FULLSCREEN": "LAYAR PENUH",
    "BATTERY SAVER • 30 FPS": "HEMAT BATERAI • 30 FPS",
    "BALANCED • 60 FPS": "SEIMBANG • 60 FPS",
    "HIGH • 120 FPS": "TINGGI • 120 FPS",
    "START A NEW GAME?": "MULAI GAME BARU?",
    "DELETE SAVE & START": "HAPUS SAVE & MULAI",
    "CANCEL": "BATAL",
    "JOURNAL": "JURNAL",
    "CURRENT MISSION": "MISI SAAT INI",
    "PREV": "SEBELUMNYA",
    "NEXT": "BERIKUTNYA",
    "CLOSE": "TUTUP",
    "NO ENTRIES": "BELUM ADA CATATAN",
    "NOTE": "CATATAN",
    "TIP": "TIPS",
    "WARNING": "PERINGATAN",
    "MISSION NOTE": "CATATAN MISI",
    "LOG": "LOG",
    "TRIVIA": "TRIVIA",
    "Same Wi-Fi/LAN • host port 24877": "Wi-Fi/LAN yang sama • port host 24877",
    "Host IPv4 • 192.168.x.x": "IPv4 Host • 192.168.x.x",
    "PAUSED": "DIJEDA",
    "WORLD SAVED": "DUNIA TERSIMPAN",
    "YOU DIED": "KAMU MATI",
    "Tap RESTART": "Ketuk RESTART",
    "Press R to restart": "Tekan R untuk mengulang",
    "Explore the world and inspect papers, logs, warnings, and strange objects.": "Jelajahi dunia dan periksa kertas, log, peringatan, serta benda-benda aneh.",
    "Flashlight Battery": "Baterai Senter",
    "Canned Food": "Makanan Kaleng",
    "Bottled Water": "Air Botol",
    "Bandage": "Perban",
    "Medkit": "Medkit",
    "Cloth": "Kain"
}

const STATUS_EN_TO_ID: Dictionary = {
    "Choose how you want to enter the dark.": "Pilih bagaimana kamu ingin memasuki kegelapan.",
    "Settings are saved on this device.": "Pengaturan disimpan di perangkat ini.",
    "No valid save found. Start a NEW GAME.": "Belum ada save yang valid. Mulai GAME BARU.",
    "Continue restored. Check the Journal for your current mission.": "Continue dipulihkan. Periksa Jurnal untuk misi saat ini.",
    "Starting over will delete the current persistent world save.": "Memulai ulang akan menghapus save dunia persistent saat ini.",
    "New Game failed: scene reload error.": "GAME BARU gagal: error saat memuat ulang scene.",
    "Starting a new nightmare...": "Memulai mimpi buruk baru...",
    "NEW GAME: Reach the first door. Don't trust the hallway.": "GAME BARU: Capai pintu pertama. Jangan percaya lorong ini.",
    "NetworkManager is not available.": "NetworkManager tidak tersedia.",
    "Host failed. Check the co-op status message.": "HOST gagal dibuat. Periksa pesan status co-op.",
    "Host created. Set name, READY, then START.": "HOST dibuat. Atur nama, READY, lalu START.",
    "Enter the host LAN IPv4 address.": "Masukkan alamat IPv4 HOST pada LAN yang sama.",
    "Enter a host IPv4 address, for example 192.168.1.10": "Masukkan IPv4 HOST, contoh 192.168.1.10",
    "Connection failed: NetworkManager missing.": "Koneksi gagal: NetworkManager tidak tersedia.",
    "Could not connect. Check the host IP, Wi-Fi/LAN, and port 24877.": "Gagal terhubung. Periksa IP HOST, Wi-Fi/LAN, dan port 24877.",
    "CO-OP: the world continues while this menu is open.": "CO-OP: dunia tetap berjalan saat menu ini terbuka.",
    "SaveSystem is not available.": "SaveSystem tidak tersedia.",
    "Save failed or client is not host-authoritative.": "Save gagal atau client bukan host-authoritative.",
    "The current persistent world save will be deleted.\nJournal discoveries, finite loot state, and world progress will reset.": "Save dunia persistent saat ini akan dihapus.\nPenemuan Jurnal, status loot terbatas, dan progres dunia akan direset.",
    "CONTINUE AVAILABLE\nPersistent world save detected.": "LANJUTKAN TERSEDIA\nSave dunia persistent terdeteksi.",
    "NO SAVE DATA\nA new run will create autosaves at major checkpoints.": "BELUM ADA SAVE\nRun baru akan membuat autosave di checkpoint utama.",
    "CURRENT RUN IN MEMORY\nResume without reloading the disk save.": "SESI SAAT INI MASIH AKTIF\nLanjutkan tanpa memuat ulang save dari disk.",
    "SAVE DATA UNREADABLE": "SAVE TIDAK DAPAT DIBACA",
    "SAVE DATA INVALID\nUse NEW GAME to reset the persistent world.": "SAVE TIDAK VALID\nGunakan GAME BARU untuk mereset dunia persistent.",
    "Belum ada save. Pilih NEW GAME.": "Belum ada save. Pilih GAME BARU.",
    "Memuat save...": "Memuat save...",
    "SaveSystem tidak tersedia.": "SaveSystem tidak tersedia.",
    "Save tidak dapat dimuat.": "Save tidak dapat dimuat.",
    "NEW GAME akan menghapus world save saat ini.": "GAME BARU akan menghapus save dunia saat ini.",
    "Memverifikasi Labyrinth...": "Memverifikasi Labyrinth...",
    "Save lama gagal dihapus.": "Save lama gagal dihapus.",
    "NetworkManager tidak tersedia.": "NetworkManager tidak tersedia.",
    "HOST gagal dibuat.": "HOST gagal dibuat.",
    "Masukkan IPv4 HOST pada LAN/Wi-Fi yang sama.": "Masukkan IPv4 HOST pada LAN/Wi-Fi yang sama.",
    "Masukkan IP, contoh 192.168.1.10": "Masukkan IP, contoh 192.168.1.10",
    "Terhubung. Memverifikasi Labyrinth...": "Terhubung. Memverifikasi Labyrinth...",
    "Gagal terhubung. Periksa IP HOST.": "Gagal terhubung. Periksa IP HOST.",
    "SAFE SCENE BOOT ONLINE — click NEW GAME or press N.": "SAFE SCENE BOOT ONLINE — klik GAME BARU atau tekan N."
}

var language_code: String = "en"
var reverse_ui: Dictionary = {}
var reverse_status: Dictionary = {}
var localization_timer: float = 0.0
var control_timer: float = 0.0
var tracked_scene_id: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_reverse_maps()
    _load_language()

func _process(delta: float) -> void:
    control_timer -= delta
    if control_timer <= 0.0:
        control_timer = 0.35
        _ensure_language_controls()

    localization_timer -= delta
    if localization_timer <= 0.0:
        localization_timer = 0.12
        _apply_localization()

func _input(event: InputEvent) -> void:
    var pressed_point: Vector2 = Vector2(-10000.0, -10000.0)
    var has_point: bool = false
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            pressed_point = mouse_event.position
            has_point = true
    elif event is InputEventScreenTouch:
        var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
        if touch_event.pressed:
            pressed_point = touch_event.position
            has_point = true
    elif event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_L and _language_setting_visible():
            _toggle_language()
            get_viewport().set_input_as_handled()
            return

    if not has_point:
        return
    for button: Button in _visible_language_buttons():
        if button.get_global_rect().has_point(pressed_point):
            _toggle_language()
            get_viewport().set_input_as_handled()
            return

func get_language() -> String:
    return language_code

func is_indonesian() -> bool:
    return language_code == "id"

func set_language(next_language: String) -> void:
    var normalized: String = next_language.to_lower()
    if not SUPPORTED_LANGUAGES.has(normalized):
        return
    if normalized == language_code:
        _apply_localization()
        return
    language_code = normalized
    _save_language()
    _update_language_button_labels()
    _apply_localization()
    language_changed.emit(language_code)

func tr_ui(english_text: String) -> String:
    if language_code == "id":
        return str(UI_EN_TO_ID.get(english_text, english_text))
    return english_text

func localize_gameplay_text(source_text: String) -> String:
    var english_text: String = _canonicalize_text(source_text)
    if language_code == "en":
        return english_text
    return _translate_gameplay_to_indonesian(english_text)

func _toggle_language() -> void:
    set_language("en" if language_code == "id" else "id")

func _build_reverse_maps() -> void:
    reverse_ui.clear()
    reverse_status.clear()
    for english_variant: Variant in UI_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        reverse_ui[str(UI_EN_TO_ID[english_variant])] = english_text
    for english_variant: Variant in STATUS_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        reverse_status[str(STATUS_EN_TO_ID[english_variant])] = english_text

func _load_language() -> void:
    var default_language: String = "id" if OS.get_locale_language().to_lower() == "id" else "en"
    language_code = default_language
    var config: ConfigFile = ConfigFile.new()
    var error: Error = config.load(LANGUAGE_PATH)
    if error == OK:
        var saved: String = str(config.get_value("localization", "language", default_language)).to_lower()
        if SUPPORTED_LANGUAGES.has(saved):
            language_code = saved

func _save_language() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("localization", "language", language_code)
    config.save(LANGUAGE_PATH)

func _ensure_language_controls() -> void:
    var scene: Node = get_tree().current_scene
    if scene != null:
        var scene_id: int = int(scene.get_instance_id())
        if tracked_scene_id != scene_id:
            tracked_scene_id = scene_id
        if scene.scene_file_path == MAIN_MENU_SCENE_PATH:
            var main_box: VBoxContainer = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel/VBox") as VBoxContainer
            var main_panel: PanelContainer = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel") as PanelContainer
            _ensure_button_in_box(main_box, main_panel)

    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end == null:
        return
    var panel_value: Variant = front_end.get("settings_panel")
    if panel_value is PanelContainer:
        var gameplay_panel: PanelContainer = panel_value as PanelContainer
        var gameplay_box: VBoxContainer = gameplay_panel.get_child(0) as VBoxContainer if gameplay_panel.get_child_count() > 0 else null
        _ensure_button_in_box(gameplay_box, gameplay_panel)

func _ensure_button_in_box(box: VBoxContainer, panel: PanelContainer) -> void:
    if box == null:
        return
    var existing: Button = box.get_node_or_null("LanguageToggle") as Button
    if existing == null:
        var button: Button = Button.new()
        button.name = "LanguageToggle"
        button.custom_minimum_size = Vector2(260.0, 36.0)
        button.focus_mode = Control.FOCUS_NONE
        button.mouse_filter = Control.MOUSE_FILTER_STOP
        button.pressed.connect(_toggle_language)
        box.add_child(button)
        var back_button: Button = box.get_node_or_null("BackButton") as Button
        if back_button != null:
            box.move_child(button, back_button.get_index())
        else:
            var settings_value: Label = box.get_node_or_null("SettingsValue") as Label
            if settings_value != null:
                box.move_child(button, settings_value.get_index())
        existing = button
    if panel != null:
        panel.custom_minimum_size.y = maxf(panel.custom_minimum_size.y, 490.0)
    _set_language_button_text(existing)

func _set_language_button_text(button: Button) -> void:
    if button == null:
        return
    button.text = "BAHASA: INDONESIA" if language_code == "id" else "LANGUAGE: ENGLISH"
    button.tooltip_text = "Tekan untuk ganti ke English • shortcut L" if language_code == "id" else "Press to switch to Bahasa Indonesia • shortcut L"

func _update_language_button_labels() -> void:
    for button: Button in _visible_language_buttons(true):
        _set_language_button_text(button)

func _visible_language_buttons(include_hidden: bool = false) -> Array[Button]:
    var result: Array[Button] = []
    var root: Window = get_tree().root
    if root == null:
        return result
    var found: Array[Node] = root.find_children("LanguageToggle", "Button", true, false)
    for node: Node in found:
        var button: Button = node as Button
        if button == null:
            continue
        if include_hidden or button.is_visible_in_tree():
            result.append(button)
    return result

func _language_setting_visible() -> bool:
    return not _visible_language_buttons().is_empty()

func _apply_localization() -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    if scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        _localize_main_menu(scene)

    _localize_frontend_ui()
    _localize_player_hud()
    _localize_journal_ui()
    _localize_evacuation_labels(scene)
    _update_language_button_labels()

func _localize_main_menu(scene: Node) -> void:
    var main_paths: Array[NodePath] = [
        NodePath("MenuLayer/Root/Center/MainPanel/VBox/ContinueButton"),
        NodePath("MenuLayer/Root/Center/MainPanel/VBox/NewGameButton"),
        NodePath("MenuLayer/Root/Center/MainPanel/VBox/HostButton"),
        NodePath("MenuLayer/Root/Center/MainPanel/VBox/JoinButton"),
        NodePath("MenuLayer/Root/Center/MainPanel/VBox/SettingsButton"),
        NodePath("MenuLayer/Root/Center/MainPanel/VBox/QuitButton"),
        NodePath("MenuLayer/Root/Center/JoinPanel/VBox/Title"),
        NodePath("MenuLayer/Root/Center/JoinPanel/VBox/Help"),
        NodePath("MenuLayer/Root/Center/JoinPanel/VBox/ConnectButton"),
        NodePath("MenuLayer/Root/Center/JoinPanel/VBox/BackButton"),
        NodePath("MenuLayer/Root/Center/SettingsPanel/VBox/Title"),
        NodePath("MenuLayer/Root/Center/SettingsPanel/VBox/VolumeLabel"),
        NodePath("MenuLayer/Root/Center/SettingsPanel/VBox/SensitivityLabel"),
        NodePath("MenuLayer/Root/Center/SettingsPanel/VBox/FpsLabel"),
        NodePath("MenuLayer/Root/Center/SettingsPanel/VBox/FullscreenCheck"),
        NodePath("MenuLayer/Root/Center/SettingsPanel/VBox/BackButton"),
        NodePath("MenuLayer/Root/Center/ConfirmPanel/VBox/Title"),
        NodePath("MenuLayer/Root/Center/ConfirmPanel/VBox/Text"),
        NodePath("MenuLayer/Root/Center/ConfirmPanel/VBox/ConfirmButton"),
        NodePath("MenuLayer/Root/Center/ConfirmPanel/VBox/CancelButton")
    ]
    for path: NodePath in main_paths:
        var node: Node = scene.get_node_or_null(path)
        _localize_control(node)

    var address: LineEdit = scene.get_node_or_null("MenuLayer/Root/Center/JoinPanel/VBox/Address") as LineEdit
    if address != null:
        address.placeholder_text = _localize_ui_exact(address.placeholder_text)

    var save_summary: Label = scene.get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/SaveSummary") as Label
    if save_summary != null:
        save_summary.text = _localize_status(save_summary.text)

    var status: Label = scene.get_node_or_null("MenuLayer/Root/Status") as Label
    if status != null:
        status.text = _localize_status(status.text)

    var settings_value: Label = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel/VBox/SettingsValue") as Label
    if settings_value != null:
        settings_value.text = _localize_settings_value(settings_value.text)

    var fps: OptionButton = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel/VBox/FpsOption") as OptionButton
    _localize_fps_option(fps)

func _localize_frontend_ui() -> void:
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end == null:
        return
    var layer_value: Variant = front_end.get("layer")
    if layer_value is CanvasLayer:
        _localize_control_tree(layer_value as CanvasLayer)
    var status_value: Variant = front_end.get("status_label")
    if status_value is Label:
        var status: Label = status_value as Label
        status.text = _localize_status(status.text)
    var settings_value_variant: Variant = front_end.get("settings_value_label")
    if settings_value_variant is Label:
        var settings_value: Label = settings_value_variant as Label
        settings_value.text = _localize_settings_value(settings_value.text)

func _localize_player_hud() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = localize_gameplay_text(objective.text)

    var inventory: Label = player.get_node_or_null("HUD/InventoryLabel") as Label
    if inventory != null:
        inventory.text = _localize_inventory(inventory.text)

    var panic_label: Label = player.get_node_or_null("HUD/PanicLabel") as Label
    if panic_label != null:
        panic_label.text = _localize_stat_line(panic_label.text)

    var controls: Label = player.get_node_or_null("HUD/Controls") as Label
    if controls != null:
        controls.text = _localize_controls_text(controls.text)

    var interaction: Label = player.get_node_or_null("HUD/InteractionHint") as Label
    if interaction != null:
        interaction.text = localize_gameplay_text(interaction.text)

    var death_title: Label = player.get_node_or_null("HUD/CaughtPanel/Title") as Label
    var death_rule: Label = player.get_node_or_null("HUD/CaughtPanel/Rule") as Label
    var death_restart: Label = player.get_node_or_null("HUD/CaughtPanel/Restart") as Label
    if death_title != null:
        death_title.text = _localize_ui_exact(death_title.text)
    if death_rule != null:
        death_rule.text = _localize_death_rule(death_rule.text)
    if death_restart != null:
        death_restart.text = _localize_ui_exact(death_restart.text)

    var survival_panel: PanelContainer = player.get_node_or_null("HUD/SurvivalPanel") as PanelContainer
    if survival_panel != null:
        for child: Node in survival_panel.find_children("*", "Label", true, false):
            var stat: Label = child as Label
            if stat != null:
                stat.text = _localize_stat_line(stat.text)

func _localize_journal_ui() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var layer_value: Variant = journal.get("layer")
    if layer_value is CanvasLayer:
        _localize_control_tree(layer_value as CanvasLayer)
    var mission_value: Variant = journal.get("mission_label")
    if mission_value is Label:
        var mission: Label = mission_value as Label
        mission.text = localize_gameplay_text(mission.text)
    var heading_value: Variant = journal.get("entry_heading")
    if heading_value is Label:
        var heading: Label = heading_value as Label
        heading.text = _localize_journal_heading(heading.text)
    var counter_value: Variant = journal.get("entry_counter")
    if counter_value is Label:
        var counter: Label = counter_value as Label
        counter.text = _localize_entry_counter(counter.text)

func _localize_evacuation_labels(scene: Node) -> void:
    var arc_root: Node = scene.get_node_or_null("Arc1Expansion/EvacuationExpansion")
    if arc_root == null:
        return
    for child: Node in arc_root.get_children():
        if child is Label3D:
            var label: Label3D = child as Label3D
            if language_code == "id":
                label.text = label.text.replace("EXTRACTION", "EKSTRAKSI")
            else:
                label.text = label.text.replace("EKSTRAKSI", "EXTRACTION")

func _localize_control_tree(root_node: Node) -> void:
    if root_node == null:
        return
    _localize_control(root_node)
    for child: Node in root_node.get_children():
        _localize_control_tree(child)

func _localize_control(node: Node) -> void:
    if node == null or node.name == "LanguageToggle":
        return
    if node is OptionButton:
        _localize_fps_option(node as OptionButton)
        return
    if node is Button:
        var button: Button = node as Button
        button.text = _localize_ui_exact(button.text)
        return
    if node is Label:
        var label: Label = node as Label
        label.text = _localize_ui_exact(label.text)
        return
    if node is RichTextLabel:
        var rich: RichTextLabel = node as RichTextLabel
        rich.text = _localize_ui_exact(rich.text)
        return
    if node is LineEdit:
        var line_edit: LineEdit = node as LineEdit
        line_edit.placeholder_text = _localize_ui_exact(line_edit.placeholder_text)

func _localize_ui_exact(text: String) -> String:
    var english_text: String = str(reverse_ui.get(text, text))
    if language_code == "id":
        return str(UI_EN_TO_ID.get(english_text, english_text))
    return english_text

func _localize_status(text: String) -> String:
    var english_text: String = str(reverse_status.get(text, text))

    if english_text.begins_with("Menghubungkan ke "):
        english_text = "Connecting to %s" % english_text.trim_prefix("Menghubungkan ke ")
    elif english_text.begins_with("Connecting to "):
        pass
    elif english_text.begins_with("BOOT FAILED: PackedScene tidak ditemukan: "):
        english_text = "BOOT FAILED: PackedScene not found: %s" % english_text.trim_prefix("BOOT FAILED: PackedScene tidak ditemukan: ")
    elif english_text == "BOOT FAILED: resource bukan PackedScene.":
        english_text = "BOOT FAILED: resource is not a PackedScene."
    elif english_text == "BOOT FAILED: PackedScene.instantiate() menghasilkan null.":
        english_text = "BOOT FAILED: PackedScene.instantiate() returned null."
    elif english_text == "BOOT FAILED: main.tscn missing Player, Camera3D, atau HUD.":
        english_text = "BOOT FAILED: main.tscn missing Player, Camera3D, or HUD."

    if language_code == "en":
        if english_text == "Belum ada save. Pilih GAME BARU.":
            return "No save found. Choose NEW GAME."
        if english_text == "Memuat save...":
            return "Loading save..."
        if english_text == "SaveSystem tidak tersedia.":
            return "SaveSystem is unavailable."
        if english_text == "Save tidak dapat dimuat.":
            return "Save could not be loaded."
        if english_text == "GAME BARU akan menghapus save dunia saat ini.":
            return "NEW GAME will delete the current world save."
        if english_text == "Memverifikasi Labyrinth...":
            return "Verifying Labyrinth..."
        if english_text == "Save lama gagal dihapus.":
            return "Old save could not be deleted."
        if english_text == "NetworkManager tidak tersedia.":
            return "NetworkManager is unavailable."
        if english_text == "HOST gagal dibuat.":
            return "HOST could not be created."
        if english_text == "Masukkan IPv4 HOST pada LAN/Wi-Fi yang sama.":
            return "Enter the HOST IPv4 on the same LAN/Wi-Fi."
        if english_text == "Masukkan IP, contoh 192.168.1.10":
            return "Enter an IP, for example 192.168.1.10"
        if english_text == "Terhubung. Memverifikasi Labyrinth...":
            return "Connected. Verifying Labyrinth..."
        if english_text == "Gagal terhubung. Periksa IP HOST.":
            return "Could not connect. Check the HOST IP."
        return english_text

    if STATUS_EN_TO_ID.has(english_text):
        return str(STATUS_EN_TO_ID[english_text])
    if english_text.begins_with("Connecting to "):
        return "Menghubungkan ke %s" % english_text.trim_prefix("Connecting to ")
    if english_text.begins_with("BOOT FAILED: PackedScene not found: "):
        return "BOOT FAILED: PackedScene tidak ditemukan: %s" % english_text.trim_prefix("BOOT FAILED: PackedScene not found: ")
    if english_text == "BOOT FAILED: resource is not a PackedScene.":
        return "BOOT FAILED: resource bukan PackedScene."
    if english_text == "BOOT FAILED: PackedScene.instantiate() returned null.":
        return "BOOT FAILED: PackedScene.instantiate() menghasilkan null."
    if english_text == "BOOT FAILED: main.tscn missing Player, Camera3D, or HUD.":
        return "BOOT FAILED: main.tscn missing Player, Camera3D, atau HUD."
    return english_text

func _localize_settings_value(text: String) -> String:
    if language_code == "id":
        return text.replace("Look", "Pandangan")
    return text.replace("Pandangan", "Look")

func _localize_fps_option(option: OptionButton) -> void:
    if option == null:
        return
    for index: int in range(option.item_count):
        var current: String = option.get_item_text(index)
        var english_text: String = str(reverse_ui.get(current, current))
        var target: String = str(UI_EN_TO_ID.get(english_text, english_text)) if language_code == "id" else english_text
        if current != target:
            option.set_item_text(index, target)

func _localize_inventory(text: String) -> String:
    var result: String = text
    if language_code == "id":
        result = result.replace("INVENTORY", "INVENTARIS")
        result = result.replace("(empty)", "(kosong)")
        for english_variant: Variant in ["Flashlight Battery", "Canned Food", "Bottled Water", "Bandage", "Medkit", "Cloth"]:
            var english_name: String = str(english_variant)
            result = result.replace(english_name, str(UI_EN_TO_ID.get(english_name, english_name)))
        return result
    result = result.replace("INVENTARIS", "INVENTORY")
    result = result.replace("(kosong)", "(empty)")
    for indonesian_variant: Variant in ["Baterai Senter", "Makanan Kaleng", "Air Botol", "Perban", "Kain"]:
        var indonesian_name: String = str(indonesian_variant)
        result = result.replace(indonesian_name, str(reverse_ui.get(indonesian_name, indonesian_name)))
    return result

func _localize_stat_line(text: String) -> String:
    var result: String = text
    var id_to_en: Dictionary = {
        "NYAWA": "HEALTH",
        "LAPAR": "HUNGER",
        "HAUS": "THIRST",
        "STAMINA": "STAMINA",
        "BATERAI": "BATTERY",
        "KEGELAPAN": "DARKNESS",
        "PANIK": "PANIC"
    }
    for id_variant: Variant in id_to_en.keys():
        var id_word: String = str(id_variant)
        if result.begins_with(id_word):
            result = str(id_to_en[id_word]) + result.substr(id_word.length())
            break
    if language_code == "en":
        return result
    var en_to_id: Dictionary = {
        "HEALTH": "NYAWA",
        "HUNGER": "LAPAR",
        "THIRST": "HAUS",
        "STAMINA": "STAMINA",
        "BATTERY": "BATERAI",
        "DARKNESS": "KEGELAPAN",
        "PANIC": "PANIK"
    }
    for en_variant: Variant in en_to_id.keys():
        var en_word: String = str(en_variant)
        if result.begins_with(en_word):
            return str(en_to_id[en_word]) + result.substr(en_word.length())
    return result

func _localize_controls_text(text: String) -> String:
    if language_code == "id":
        var result: String = text
        result = result.replace("WASD Move", "WASD Gerak")
        result = result.replace("Shift Sprint", "Shift Lari")
        result = result.replace("E Interact", "E Interaksi")
        result = result.replace("F Flashlight", "F Senter")
        result = result.replace("B Battery", "B Baterai")
        result = result.replace("1 Food", "1 Makanan")
        result = result.replace("2 Water", "2 Air")
        result = result.replace("3 Medkit", "3 Medkit")
        result = result.replace("Mouse Look", "Mouse Lihat")
        result = result.replace("Esc Menu", "Esc Menu")
        result = result.replace("Esc Release mouse", "Esc Lepas mouse")
        return result
    var result: String = text
    result = result.replace("WASD Gerak", "WASD Move")
    result = result.replace("Shift Lari", "Shift Sprint")
    result = result.replace("E Interaksi", "E Interact")
    result = result.replace("F Senter", "F Flashlight")
    result = result.replace("B Baterai", "B Battery")
    result = result.replace("1 Makanan", "1 Food")
    result = result.replace("2 Air", "2 Water")
    result = result.replace("Mouse Lihat", "Mouse Look")
    result = result.replace("Esc Lepas mouse", "Esc Release mouse")
    return result

func _localize_death_rule(text: String) -> String:
    if text.begins_with("Cause: ") and language_code == "id":
        return "Penyebab: %s" % text.trim_prefix("Cause: ")
    if text.begins_with("Penyebab: ") and language_code == "en":
        return "Cause: %s" % text.trim_prefix("Penyebab: ")
    return text

func _localize_journal_heading(text: String) -> String:
    var result: String = text
    if language_code == "id":
        result = result.replace("[MISSION NOTE]", "[CATATAN MISI]")
        result = result.replace("[WARNING]", "[PERINGATAN]")
        result = result.replace("[TIP]", "[TIPS]")
        result = result.replace("[NOTE]", "[CATATAN]")
        return result
    result = result.replace("[CATATAN MISI]", "[MISSION NOTE]")
    result = result.replace("[PERINGATAN]", "[WARNING]")
    result = result.replace("[TIPS]", "[TIP]")
    result = result.replace("[CATATAN]", "[NOTE]")
    return result

func _localize_entry_counter(text: String) -> String:
    if language_code == "id" and text.begins_with("ENTRY "):
        return "CATATAN %s" % text.trim_prefix("ENTRY ")
    if language_code == "en" and text.begins_with("CATATAN "):
        return "ENTRY %s" % text.trim_prefix("CATATAN ")
    return text

func _canonicalize_text(text: String) -> String:
    var result: String = text
    var id_to_en: Array[PackedStringArray] = [
        PackedStringArray(["MISI SAAT INI", "CURRENT MISSION"]),
        PackedStringArray(["EVAKUASI KRITIS", "EVACUATION CRITICAL"]),
        PackedStringArray(["EKSTRAKSI SIAP", "EXTRACTION ARMED"]),
        PackedStringArray(["THE WARDEN SEDANG MEMBURU", "THE WARDEN IS HUNTING"]),
        PackedStringArray(["SAYAP MAINTENANCE", "MAINTENANCE WING"]),
        PackedStringArray(["LAYANAN TERGENANG", "FLOODED SERVICE"]),
        PackedStringArray(["ARSIP", "ARCHIVE"]),
        PackedStringArray(["ARC 1 SELESAI", "ARC 1 COMPLETE"]),
        PackedStringArray(["Urutan breaker", "Breaker sequence"]),
        PackedStringArray(["Progres", "Progress"]),
        PackedStringArray(["Pulihkan kotak fuse", "Restore fuse boxes"]),
        PackedStringArray(["Putar katup tekanan", "Turn pressure valves"]),
        PackedStringArray(["Cari jalur samping untuk persediaan.", "Search side passages for supplies."]),
        PackedStringArray(["Capai konsol terakhir.", "Reach the final console."]),
        PackedStringArray(["Siapkan cahaya, healing, dan stamina terlebih dahulu.", "Prepare light, healing and stamina first."]),
        PackedStringArray(["stabilkan daya", "stabilize power"]),
        PackedStringArray(["bertahan hidup dan terus bergerak.", "survive and keep moving."]),
        PackedStringArray(["Kembali ke M-01.", "Return to M-01."]),
        PackedStringArray(["pulihkan override", "restore overrides"]),
        PackedStringArray(["Kembali melalui rute ke pintu masuk M-01.", "Reverse route to M-01 entrance."]),
        PackedStringArray(["Kembali melalui Arsip → Flooded → Maintenance.", "Reverse through Archive → Flooded → Maintenance."]),
        PackedStringArray(["Pintu keluar terakhir terbuka. Ikuti beacon menuju THE OUTSIDE.", "Final exit unlocked. Follow the beacon to THE OUTSIDE."]),
        PackedStringArray(["Baterai Senter", "Flashlight Battery"]),
        PackedStringArray(["Makanan Kaleng", "Canned Food"]),
        PackedStringArray(["Air Botol", "Bottled Water"]),
        PackedStringArray(["Perban", "Bandage"]),
        PackedStringArray(["Kain", "Cloth"])
    ]
    for pair: PackedStringArray in id_to_en:
        result = result.replace(pair[0], pair[1])
    return result

func _translate_gameplay_to_indonesian(text: String) -> String:
    var exact: Dictionary = {
        "You have no food.": "Kamu tidak punya makanan.",
        "You eat the canned food.": "Kamu memakan makanan kaleng.",
        "You have no water.": "Kamu tidak punya air.",
        "You drink the water.": "Kamu meminum air.",
        "You do not need the medkit yet.": "Kamu belum membutuhkan medkit.",
        "You have no medkit.": "Kamu tidak punya medkit.",
        "You patch your wounds.": "Kamu merawat lukamu.",
        "The flashlight battery is dead. Replace it with BATT.": "Baterai senter habis. Ganti dengan BATT.",
        "The flashlight battery is already full.": "Baterai senter sudah penuh.",
        "You have no replacement battery.": "Kamu tidak punya baterai pengganti.",
        "You replace the flashlight battery.": "Kamu mengganti baterai senter.",
        "Your flashlight died. Darkness is not safe. Find a battery.": "Sentermu mati. Kegelapan tidak aman. Cari baterai.",
        "ARC 1: Restore all 3 emergency relays to open the lower labyrinth.": "ARC 1: Pulihkan semua 3 relay darurat untuk membuka Labyrinth bawah.",
        "ARC 1 — LOCKDOWN: Reach the final console. Prepare light, healing and stamina first.": "ARC 1 — LOCKDOWN: Capai konsol terakhir. Siapkan cahaya, healing, dan stamina terlebih dahulu.",
        "ARC 1 COMPLETE: Final exit unlocked. Follow the beacon to THE OUTSIDE.": "ARC 1 SELESAI: Pintu keluar terakhir terbuka. Ikuti beacon menuju THE OUTSIDE.",
        "Find your bearings.": "Kenali posisi dan keadaan sekitarmu.",
        "All emergency relays are online. Follow the final beacon and get outside.": "Semua relay darurat aktif. Ikuti beacon terakhir dan keluar.",
        "Survive the opening labyrinth, search Apartment 03, and find a way deeper.": "Bertahan di Labyrinth awal, cari Apartment 03, lalu temukan jalan lebih dalam."
    }
    if exact.has(text):
        return str(exact[text])

    var result: String = text
    var replacements: Array[PackedStringArray] = [
        PackedStringArray(["CURRENT MISSION", "MISI SAAT INI"]),
        PackedStringArray(["MAINTENANCE WING", "SAYAP MAINTENANCE"]),
        PackedStringArray(["FLOODED SERVICE", "LAYANAN TERGENANG"]),
        PackedStringArray(["ARCHIVE", "ARSIP"]),
        PackedStringArray(["ARC 1 COMPLETE", "ARC 1 SELESAI"]),
        PackedStringArray(["Restore fuse boxes", "Pulihkan kotak fuse"]),
        PackedStringArray(["Turn pressure valves", "Putar katup tekanan"]),
        PackedStringArray(["Search side passages for supplies.", "Cari jalur samping untuk persediaan."]),
        PackedStringArray(["Breaker sequence", "Urutan breaker"]),
        PackedStringArray(["Progress", "Progres"]),
        PackedStringArray(["Reach the final console.", "Capai konsol terakhir."]),
        PackedStringArray(["Prepare light, healing and stamina first.", "Siapkan cahaya, healing, dan stamina terlebih dahulu."]),
        PackedStringArray(["stabilize power", "stabilkan daya"]),
        PackedStringArray(["survive and keep moving.", "bertahan hidup dan terus bergerak."]),
        PackedStringArray(["EVACUATION CRITICAL", "EVAKUASI KRITIS"]),
        PackedStringArray(["EXTRACTION ARMED", "EKSTRAKSI SIAP"]),
        PackedStringArray(["Return to M-01.", "Kembali ke M-01."]),
        PackedStringArray(["THE WARDEN IS HUNTING", "THE WARDEN SEDANG MEMBURU"]),
        PackedStringArray(["restore overrides", "pulihkan override"]),
        PackedStringArray(["Reverse route to M-01 entrance.", "Kembali melalui rute ke pintu masuk M-01."]),
        PackedStringArray(["Reverse through Archive → Flooded → Maintenance.", "Kembali melalui Arsip → Flooded → Maintenance."]),
        PackedStringArray(["Final exit unlocked. Follow the beacon to THE OUTSIDE.", "Pintu keluar terakhir terbuka. Ikuti beacon menuju THE OUTSIDE."]),
        PackedStringArray(["Restore the emergency relays", "Pulihkan relay darurat"]),
        PackedStringArray(["Keep a light source ready.", "Pastikan sumber cahaya siap."]),
        PackedStringArray(["Journal updated:", "Jurnal diperbarui:"]),
        PackedStringArray(["Press J to read it.", "Tekan J untuk membacanya."]),
        PackedStringArray(["Tap JOURNAL to read it.", "Ketuk JURNAL untuk membacanya."]),
        PackedStringArray(["complete", "selesai"]),
        PackedStringArray(["no power", "tidak ada daya"]),
        PackedStringArray(["Restore Fuse Box", "Pulihkan Kotak Fuse"]),
        PackedStringArray(["Turn Pressure Valve", "Putar Katup Tekanan"]),
        PackedStringArray(["Toggle Archive Breaker", "Aktifkan Breaker Arsip"]),
        PackedStringArray(["Use Lockdown Console", "Gunakan Konsol Lockdown"]),
        PackedStringArray(["Isolation Node", "Node Isolasi"]),
        PackedStringArray(["Emergency Override", "Override Darurat"]),
        PackedStringArray(["Extraction Override", "Override Ekstraksi"]),
        PackedStringArray(["Flashlight Battery", "Baterai Senter"]),
        PackedStringArray(["Canned Food", "Makanan Kaleng"]),
        PackedStringArray(["Bottled Water", "Air Botol"]),
        PackedStringArray(["Bandage", "Perban"]),
        PackedStringArray(["Cloth", "Kain"])
    ]
    for pair: PackedStringArray in replacements:
        result = result.replace(pair[0], pair[1])
    return result
