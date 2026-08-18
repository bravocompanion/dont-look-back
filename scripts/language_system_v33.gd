extends Node

signal language_changed(locale: String)

const SETTINGS_PATH: String = "user://dont_look_back_language.cfg"
const DEFAULT_LOCALE: String = "id"
const MENU_SCENES: Array[String] = [
    "res://scenes/main_menu.tscn",
    "res://scenes/main_menu_ranger.tscn"
]

const TEXT_PAIRS: Dictionary = {
    "continue": ["LANJUTKAN", "CONTINUE"],
    "new_game": ["GAME BARU", "NEW GAME"],
    "host_coop": ["HOST CO-OP", "HOST CO-OP"],
    "join_coop": ["GABUNG CO-OP", "JOIN CO-OP"],
    "settings": ["PENGATURAN", "SETTINGS"],
    "quit": ["KELUAR", "QUIT"],
    "connect": ["HUBUNGKAN", "CONNECT"],
    "back": ["KEMBALI", "BACK"],
    "cancel": ["BATAL", "CANCEL"],
    "master_volume": ["VOLUME UTAMA", "MASTER VOLUME"],
    "look_sensitivity": ["SENSITIVITAS PANDANGAN", "LOOK SENSITIVITY"],
    "performance": ["PERFORMA / BATAS FPS", "PERFORMANCE / FPS LIMIT"],
    "battery_saver": ["HEMAT BATERAI • 30 FPS", "BATTERY SAVER • 30 FPS"],
    "balanced": ["SEIMBANG • 60 FPS", "BALANCED • 60 FPS"],
    "high": ["TINGGI • 120 FPS", "HIGH • 120 FPS"],
    "fullscreen": ["LAYAR PENUH", "FULLSCREEN"],
    "start_new": ["MULAI GAME BARU?", "START A NEW GAME?"],
    "delete_start": ["HAPUS SAVE & MULAI", "DELETE SAVE & START"],
    "join_help": ["Wi-Fi/LAN yang sama • port host 24877", "Same Wi-Fi/LAN • host port 24877"],
    "host_ipv4": ["IPv4 Host • 192.168.x.x", "Host IPv4 • 192.168.x.x"],
    "no_save": ["TIDAK ADA DATA SAVE", "NO SAVE DATA"],
    "continue_available": ["LANJUTKAN TERSEDIA", "CONTINUE AVAILABLE"],
    "no_save_desc": ["Run baru akan membuat autosave pada checkpoint utama.", "A new run will create autosaves at major checkpoints."],
    "save_desc": ["Save dunia persisten ditemukan.", "Persistent world save detected."],
    "confirm_desc": ["Save dunia persisten saat ini akan dihapus.\nPenemuan Journal, loot terbatas, dan progress dunia akan direset.", "The current persistent world save will be deleted.\nJournal discoveries, finite loot state, and world progress will reset."],
    "journal": ["JURNAL", "JOURNAL"],
    "current_mission": ["MISI SAAT INI", "CURRENT MISSION"],
    "no_entries": ["BELUM ADA CATATAN", "NO ENTRIES"],
    "no_entries_desc": ["Jelajahi dunia dan periksa kertas, log, peringatan, serta objek aneh.", "Explore the world and inspect papers, logs, warnings, and strange objects."],
    "prev": ["SEBELUMNYA", "PREV"],
    "next": ["BERIKUTNYA", "NEXT"],
    "close": ["TUTUP", "CLOSE"],
    "inventory": ["INVENTARIS", "INVENTORY"],
    "empty": ["(kosong)", "(empty)"],
    "health": ["NYAWA", "HEALTH"],
    "hunger": ["LAPAR", "HUNGER"],
    "thirst": ["HAUS", "THIRST"],
    "stamina": ["STAMINA", "STAMINA"],
    "battery": ["BATERAI", "BATTERY"],
    "darkness": ["KEGELAPAN", "DARKNESS"],
    "panic": ["PANIK", "PANIC"],
    "shelter": ["BASE", "SHELTER"],
    "generator": ["GENERATOR", "GENERATOR"],
    "campfire": ["API UNGGUN", "CAMPFIRE"],
    "storage": ["PENYIMPANAN", "STORAGE"],
    "case_board": ["Periksa Papan Kasus Ranger", "Review Ranger Case Board"],
    "sleep": ["Tidur sampai pagi", "Sleep until morning"],
    "sleep_host": ["Tidur sampai pagi (hanya host)", "Sleep until morning (host only)"],
    "enter_mine": ["Masuk ke Tambang Tua", "Enter Old Mine"],
    "mine_sealed": ["Tambang Tua terkunci — cari maintenance map", "Old Mine sealed — find the maintenance map"],
    "return_forest": ["Kembali ke Hutan Ranger", "Return to Ranger Forest"],
    "enter_lab": ["Masuk Labyrinth / Facility Level 03", "Enter Labyrinth / Facility Level 03"],
    "gate_locked": ["Gate fasilitas terkunci — cari access badge", "Facility gate locked — find an access badge"],
    "future_locked": ["Jalur lebih dalam terkunci — butuh evidence tambahan", "Deeper route locked — more evidence required"],
    "objective_forest": ["KASUS 01: Amankan cabin, lalu selidiki tim survey yang hilang.", "CASE 01: Secure the cabin, then investigate the missing survey team."],
    "case_route": ["KASUS RANGER 07 • Hutan → Tambang Tua → Labyrinth → Fasilitas Riset", "RANGER CASE 07 • Forest → Old Mine → Labyrinth → Research Facility"],
    "mine_objective": ["INVESTIGASI TAMBANG: Temukan evidence dan akses fasilitas yang disegel.", "MINE INVESTIGATION: Find evidence and the sealed facility access."],
    "facility_objective": ["FASILITAS TERBATAS: Periksa routing terminal.", "RESTRICTED FACILITY: Inspect the routing terminal."],
    "ranger_status": ["GAME BARU: Hutan Ranger → evidence → Tambang Tua → Labyrinth → Fasilitas Riset.", "NEW GAME: Ranger Forest → evidence → Old Mine → Labyrinth → Research Facility."],
    "ranger_case_status": ["KASUS RANGER 07 — Bertahan di hutan, selidiki tim survey yang hilang, lalu ikuti evidence ke bawah tanah.", "RANGER CASE 07 — Survive the forest, investigate the missing survey team, then follow the evidence underground."],
    "deployment": ["DEPLOYMENT RANGER: Cabin ada di belakangmu. Hadapi hutan, amankan shelter, lalu mulai investigasi.", "RANGER DEPLOYMENT: Cabin behind you. Face the forest, secure the shelter, then begin the investigation."],
    "wood": ["Kayu", "Wood"],
    "scrap": ["Besi Bekas", "Scrap"],
    "fuel_can": ["Jeriken Bahan Bakar", "Fuel Can"],
    "water": ["Air Botol", "Bottled Water"],
    "food": ["Makanan Kaleng", "Canned Food"],
    "medkit": ["Kotak P3K", "Medkit"],
    "flashlight_battery": ["Baterai Senter", "Flashlight Battery"],
    "firewood": ["Bundel Kayu Bakar", "Firewood Bundle"],
    "bandage": ["Perban", "Bandage"],
    "raw_meat": ["Daging Mentah", "Raw Meat"],
    "cooked_meat": ["Daging Matang", "Cooked Meat"],
    "raw_fish": ["Ikan Mentah", "Raw Fish"],
    "cooked_fish": ["Ikan Matang", "Cooked Fish"],
    "hunting_bow": ["Busur Berburu", "Hunting Bow"],
    "hunting_knife": ["Pisau Berburu", "Hunting Knife"],
    "fishing_rod": ["Pancing", "Fishing Rod"],
    "language_label": ["BAHASA", "LANGUAGE"]
}

var current_locale: String = DEFAULT_LOCALE
var alias_to_key: Dictionary = {}
var refresh_timer: float = 0.0
var tracked_scene_id: int = 0
var menu_switch: Button
var journal_switch: Button

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 220
    _build_aliases()
    _load_locale()

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != tracked_scene_id:
        tracked_scene_id = scene_id
        menu_switch = null
        journal_switch = null

    _ensure_switch_controls(scene)

    refresh_timer -= delta
    if refresh_timer <= 0.0:
        refresh_timer = 0.12
        _translate_tree(scene)
        _translate_journal_runtime()
        _refresh_switch_labels()

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_L:
        toggle_language()
        get_viewport().set_input_as_handled()

func get_locale() -> String:
    return current_locale

func is_indonesian() -> bool:
    return current_locale == "id"

func toggle_language() -> void:
    set_language("en" if current_locale == "id" else "id")

func set_language(locale: String) -> void:
    var normalized: String = "id" if locale.to_lower().begins_with("id") else "en"
    if current_locale == normalized:
        return
    current_locale = normalized
    _save_locale()
    refresh_timer = 0.0
    language_changed.emit(current_locale)

func text(key: String) -> String:
    if not TEXT_PAIRS.has(key):
        return key
    var pair: Array = Array(TEXT_PAIRS[key])
    return str(pair[0] if current_locale == "id" else pair[1])

func localize(source: String) -> String:
    if source.is_empty():
        return source
    if alias_to_key.has(source):
        return text(str(alias_to_key[source]))
    return _localize_dynamic(source)

func _build_aliases() -> void:
    alias_to_key.clear()
    for key_variant: Variant in TEXT_PAIRS.keys():
        var key: String = str(key_variant)
        var pair: Array = Array(TEXT_PAIRS[key])
        if pair.size() < 2:
            continue
        alias_to_key[str(pair[0])] = key
        alias_to_key[str(pair[1])] = key

func _load_locale() -> void:
    current_locale = DEFAULT_LOCALE
    var config: ConfigFile = ConfigFile.new()
    if config.load(SETTINGS_PATH) == OK:
        var saved: String = str(config.get_value("language", "locale", DEFAULT_LOCALE))
        if saved == "id" or saved == "en":
            current_locale = saved

func _save_locale() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("language", "locale", current_locale)
    config.save(SETTINGS_PATH)

func _ensure_switch_controls(scene: Node) -> void:
    if scene.scene_file_path in MENU_SCENES:
        _ensure_menu_switch(scene)
        if journal_switch != null and is_instance_valid(journal_switch):
            journal_switch.visible = false
        return

    if menu_switch != null and is_instance_valid(menu_switch):
        menu_switch.visible = false
    _ensure_journal_switch()

func _ensure_menu_switch(scene: Node) -> void:
    var root: Control = scene.get_node_or_null("MenuLayer/Root") as Control
    if root == null:
        return
    menu_switch = root.get_node_or_null("LanguageSwitchV33") as Button
    if menu_switch == null:
        menu_switch = Button.new()
        menu_switch.name = "LanguageSwitchV33"
        menu_switch.focus_mode = Control.FOCUS_NONE
        menu_switch.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        menu_switch.offset_left = -142.0
        menu_switch.offset_top = 12.0
        menu_switch.offset_right = -12.0
        menu_switch.offset_bottom = 50.0
        menu_switch.add_theme_font_size_override("font_size", 13)
        menu_switch.pressed.connect(toggle_language)
        root.add_child(menu_switch)
    menu_switch.visible = true

func _ensure_journal_switch() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var layer: CanvasLayer = journal.get("layer") as CanvasLayer
    if layer == null:
        return
    journal_switch = layer.get_node_or_null("LanguageSwitchV33") as Button
    if journal_switch == null:
        journal_switch = Button.new()
        journal_switch.name = "LanguageSwitchV33"
        journal_switch.focus_mode = Control.FOCUS_NONE
        journal_switch.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        journal_switch.offset_left = -142.0
        journal_switch.offset_top = 12.0
        journal_switch.offset_right = -12.0
        journal_switch.offset_bottom = 50.0
        journal_switch.add_theme_font_size_override("font_size", 13)
        journal_switch.pressed.connect(toggle_language)
        layer.add_child(journal_switch)
    journal_switch.visible = journal.has_method("is_open") and bool(journal.call("is_open"))

func _refresh_switch_labels() -> void:
    var label: String = "BAHASA: ID" if current_locale == "id" else "LANGUAGE: EN"
    if menu_switch != null and is_instance_valid(menu_switch):
        menu_switch.text = label
        menu_switch.tooltip_text = "Switch to English" if current_locale == "id" else "Ganti ke Bahasa Indonesia"
    if journal_switch != null and is_instance_valid(journal_switch):
        journal_switch.text = label
        journal_switch.tooltip_text = "Switch to English" if current_locale == "id" else "Ganti ke Bahasa Indonesia"

func _translate_tree(node: Node) -> void:
    if node == null:
        return
    if str(node.name) == "LanguageSwitchV33":
        return

    if node is Label:
        var label: Label = node as Label
        label.text = localize(label.text)
        label.tooltip_text = localize(label.tooltip_text)
    elif node is RichTextLabel:
        var rich: RichTextLabel = node as RichTextLabel
        rich.text = localize(rich.text)
        rich.tooltip_text = localize(rich.tooltip_text)
    elif node is Button:
        var button: Button = node as Button
        button.text = localize(button.text)
        button.tooltip_text = localize(button.tooltip_text)
    elif node is LineEdit:
        var line_edit: LineEdit = node as LineEdit
        line_edit.placeholder_text = localize(line_edit.placeholder_text)
        line_edit.tooltip_text = localize(line_edit.tooltip_text)
    elif node is Label3D:
        var label_3d: Label3D = node as Label3D
        label_3d.text = localize(label_3d.text)

    if node is OptionButton:
        var option: OptionButton = node as OptionButton
        for index: int in range(option.item_count):
            option.set_item_text(index, localize(option.get_item_text(index)))

    for child: Node in node.get_children():
        _translate_tree(child)

func _translate_journal_runtime() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var layer: CanvasLayer = journal.get("layer") as CanvasLayer
    if layer != null:
        _translate_tree(layer)

func _localize_dynamic(source: String) -> String:
    var result: String = source

    if current_locale == "id":
        result = _replace_prefix_word(result, "HEALTH", "NYAWA")
        result = _replace_prefix_word(result, "HUNGER", "LAPAR")
        result = _replace_prefix_word(result, "THIRST", "HAUS")
        result = _replace_prefix_word(result, "BATTERY", "BATERAI")
        result = _replace_prefix_word(result, "DARKNESS", "KEGELAPAN")
        result = _replace_prefix_word(result, "PANIC", "PANIK")
        result = _replace_prefix_word(result, "FOOD", "MAKAN")
        result = _replace_prefix_word(result, "H2O", "AIR")
        result = _replace_prefix_word(result, "BATT", "BATT")
        result = _replace_prefix_word(result, "DARK", "GELAP")
        result = result.replace("INVENTORY\n", "INVENTARIS\n")
        result = result.replace("\n(empty)", "\n(kosong)")
        result = result.replace("SHELTER  |", "BASE  |")
        result = result.replace("CAMPFIRE", "API UNGGUN")
        result = result.replace("STORAGE", "PENYIMPANAN")
        result = result.replace("ENTRY ", "CATATAN ")
        result = result.replace("Inspect evidence: ", "Periksa evidence: ")
        result = result.replace(" — reviewed", " — sudah diperiksa")
        result = result.replace("Journal updated: ", "Jurnal diperbarui: ")
        result = result.replace(". Press J to read it.", ". Tekan J untuk membacanya.")
        result = result.replace(". Tap JOURNAL to read it.", ". Ketuk JURNAL untuk membacanya.")
        result = result.replace("You have no food.", "Kamu tidak punya makanan.")
        result = result.replace("You have no water.", "Kamu tidak punya air.")
        result = result.replace("You have no medkit.", "Kamu tidak punya kotak P3K.")
        result = result.replace("The flashlight battery is already full.", "Baterai senter sudah penuh.")
        result = result.replace("You have no replacement battery.", "Kamu tidak punya baterai pengganti.")
        result = result.replace("You replace the flashlight battery.", "Kamu mengganti baterai senter.")
        result = result.replace("Your flashlight died. Darkness is not safe. Find a battery.", "Senter mati. Kegelapan tidak aman. Cari baterai.")
        result = result.replace("The flashlight battery is dead. Replace it with BATT.", "Baterai senter habis. Ganti dengan BATT.")
    else:
        result = _replace_prefix_word(result, "NYAWA", "HEALTH")
        result = _replace_prefix_word(result, "LAPAR", "HUNGER")
        result = _replace_prefix_word(result, "HAUS", "THIRST")
        result = _replace_prefix_word(result, "BATERAI", "BATTERY")
        result = _replace_prefix_word(result, "KEGELAPAN", "DARKNESS")
        result = _replace_prefix_word(result, "PANIK", "PANIC")
        result = _replace_prefix_word(result, "MAKAN", "FOOD")
        result = _replace_prefix_word(result, "AIR", "H2O")
        result = _replace_prefix_word(result, "GELAP", "DARK")
        result = result.replace("INVENTARIS\n", "INVENTORY\n")
        result = result.replace("\n(kosong)", "\n(empty)")
        result = result.replace("BASE  |", "SHELTER  |")
        result = result.replace("API UNGGUN", "CAMPFIRE")
        result = result.replace("PENYIMPANAN", "STORAGE")
        result = result.replace("CATATAN ", "ENTRY ")
        result = result.replace("Periksa evidence: ", "Inspect evidence: ")
        result = result.replace(" — sudah diperiksa", " — reviewed")
        result = result.replace("Jurnal diperbarui: ", "Journal updated: ")
        result = result.replace(". Tekan J untuk membacanya.", ". Press J to read it.")
        result = result.replace(". Ketuk JURNAL untuk membacanya.", ". Tap JOURNAL to read it.")
        result = result.replace("Kamu tidak punya makanan.", "You have no food.")
        result = result.replace("Kamu tidak punya air.", "You have no water.")
        result = result.replace("Kamu tidak punya kotak P3K.", "You have no medkit.")
        result = result.replace("Baterai senter sudah penuh.", "The flashlight battery is already full.")
        result = result.replace("Kamu tidak punya baterai pengganti.", "You have no replacement battery.")
        result = result.replace("Kamu mengganti baterai senter.", "You replace the flashlight battery.")
        result = result.replace("Senter mati. Kegelapan tidak aman. Cari baterai.", "Your flashlight died. Darkness is not safe. Find a battery.")
        result = result.replace("Baterai senter habis. Ganti dengan BATT.", "The flashlight battery is dead. Replace it with BATT.")

    return _translate_item_lines(result)

func _replace_prefix_word(source: String, from_word: String, to_word: String) -> String:
    if source == from_word:
        return to_word
    if source.begins_with(from_word + " "):
        return to_word + source.substr(from_word.length())
    return source

func _translate_item_lines(source: String) -> String:
    var result: String = source
    var item_keys: Array[String] = [
        "wood", "scrap", "fuel_can", "water", "food", "medkit",
        "flashlight_battery", "firewood", "bandage", "raw_meat", "cooked_meat",
        "raw_fish", "cooked_fish", "hunting_bow", "hunting_knife", "fishing_rod"
    ]
    for item_key: String in item_keys:
        var pair: Array = Array(TEXT_PAIRS[item_key])
        var target: String = str(pair[0] if current_locale == "id" else pair[1])
        var other: String = str(pair[1] if current_locale == "id" else pair[0])
        result = result.replace("• %s x" % other, "• %s x" % target)
    return result
