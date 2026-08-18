extends "res://scripts/language_system.gd"

const RANGER_MENU_SCENE_PATH: String = "res://scenes/main_menu_ranger.tscn"

var ranger_en_to_id: Dictionary = {}
var ranger_id_to_en: Dictionary = {}
var top_language_button: Button
var journal_language_button: Button

func _ready() -> void:
    _build_ranger_dictionary()
    _build_ranger_reverse()
    super._ready()

func _load_language() -> void:
    language_code = "id"
    var config: ConfigFile = ConfigFile.new()
    if config.load(LANGUAGE_PATH) != OK:
        return
    var saved: String = str(config.get_value("language", "locale", ""))
    if saved.is_empty():
        saved = str(config.get_value("localization", "language", "id"))
    saved = saved.to_lower()
    if SUPPORTED_LANGUAGES.has(saved):
        language_code = saved

func _save_language() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("language", "locale", language_code)
    config.set_value("localization", "language", language_code)
    config.save(LANGUAGE_PATH)

func _build_ranger_dictionary() -> void:
    ranger_en_to_id = {
        "USE": "GUNAKAN",
        "RUN": "LARI",
        "LIGHT": "SENTER",
        "BATT": "BATERAI",
        "FOOD": "MAKAN",
        "WATER": "AIR",
        "MED": "OBAT",
        "JUMP": "LOMPAT",
        "RESTART": "ULANG",
        "HUNT": "BURU",
        "READY": "SIAP",
        "NOT READY": "BELUM SIAP",
        "START": "MULAI",
        "LEAVE": "KELUAR",
        "RECONNECT": "SAMBUNG LAGI",
        "YOU ARE DOWNED": "KAMU TUMBANG",
        "DOWNED": "TUMBANG",
        "Review Ranger Case Board": "Periksa Papan Kasus Ranger",
        "Enter Old Mine": "Masuk ke Tambang Tua",
        "Old Mine sealed — find the maintenance map": "Tambang Tua terkunci — cari peta maintenance",
        "Return to Ranger Forest": "Kembali ke Hutan Ranger",
        "Enter Labyrinth / Facility Level 03": "Masuk Labyrinth / Fasilitas Level 03",
        "Facility gate locked — find an access badge": "Gerbang fasilitas terkunci — cari badge akses",
        "Deeper route locked — more evidence required": "Jalur lebih dalam terkunci — butuh bukti tambahan",
        "Cooking rack": "Rak memasak",
        "Cooking rack — light the campfire first": "Rak memasak — nyalakan api unggun terlebih dahulu",
        "Cook Raw Meat": "Masak Daging Mentah",
        "Cook Raw Fish": "Masak Ikan Mentah",
        "Fishing spot — but you need a Fishing Rod": "Tempat memancing — kamu membutuhkan Pancing",
        "Fish here": "Memancing di sini",
        "Collect Dirty Water": "Ambil Air Kotor",
        "Boil Dirty Water": "Rebus Air Kotor",
        "Dirty Water": "Air Kotor",
        "Clean Water": "Air Bersih",
        "Wood": "Kayu",
        "Scrap": "Besi Bekas",
        "Fuel Can": "Jeriken Bahan Bakar",
        "Firewood Bundle": "Bundel Kayu Bakar",
        "Raw Meat": "Daging Mentah",
        "Cooked Meat": "Daging Matang",
        "Raw Fish": "Ikan Mentah",
        "Cooked Fish": "Ikan Matang",
        "Hunting Bow": "Busur Berburu",
        "Hunting Knife": "Pisau Berburu",
        "Fishing Rod": "Pancing",
        "Arrow": "Panah",
        "Hide": "Kulit",
        "Bone": "Tulang",
        "Fat": "Lemak",
        "Deer": "Rusa",
        "Rabbit": "Kelinci",
        "Boar": "Babi Hutan",
        "Wolf": "Serigala",
        "Survey Team Manifest": "Manifest Tim Survey",
        "Broken Radio Frequency Log": "Log Frekuensi Radio Rusak",
        "Maintenance Map — Old Mine": "Peta Maintenance — Tambang Tua",
        "Cold Water Sample Note": "Catatan Sampel Air Dingin",
        "Foreman's Last Shift": "Shift Terakhir Foreman",
        "Sealed Shaft Incident Report": "Laporan Insiden Shaft Tersegel",
        "Facility Access Badge T-03": "Badge Akses Fasilitas T-03",
        "Restricted Facility Routing Table": "Tabel Routing Fasilitas Terbatas",
        "RANGER CASE 07 — Survive the forest, investigate the missing survey team, then follow the evidence underground.": "KASUS RANGER 07 — Bertahan di hutan, selidiki tim survey yang hilang, lalu ikuti bukti ke bawah tanah.",
        "NEW GAME: Ranger Forest → evidence → Old Mine → Labyrinth → Research Facility.": "GAME BARU: Hutan Ranger → bukti → Tambang Tua → Labyrinth → Fasilitas Riset.",
        "Something is forming in the dark. GET TO THE LIGHT.": "Sesuatu sedang terbentuk dalam kegelapan. SEGERA KE CAHAYA.",
        "You're bleeding. Use a Bandage or Medkit before the wound gets infected.": "Kamu mengalami pendarahan. Gunakan Perban atau Medkit sebelum luka terinfeksi.",
        "You drink clean water.": "Kamu meminum air bersih.",
        "You drink untreated water. Thirst drops, but Infection rises.": "Kamu meminum air tanpa pengolahan. Haus berkurang, tetapi Infeksi meningkat.",
        "You bind the wound with a Bandage.": "Kamu membalut luka dengan Perban.",
        "You clean and dress your wounds with the Medkit.": "Kamu membersihkan dan merawat luka dengan Medkit.",
        "You need the Fishing Rod from the ranger cache before fishing.": "Kamu membutuhkan Pancing dari cache ranger sebelum memancing.",
        "You need the Hunting Bow from the ranger cache.": "Kamu membutuhkan Busur Berburu dari cache ranger.",
        "The arrow vanishes between the trees.": "Panah menghilang di antara pepohonan.",
        "The arrow strikes something that is not prey.": "Panah mengenai sesuatu yang bukan hewan buruan.",
        "Need at least 2 survivors before START.": "Butuh setidaknya 2 survivor sebelum MULAI.",
        "Every connected survivor must be READY.": "Semua survivor yang terhubung harus SIAP.",
        "Player not ready yet.": "Player belum siap.",
        "Team ready. Stay together and keep the light moving.": "Tim siap. Tetap bersama dan jaga cahaya terus bergerak."
    }

func _build_ranger_reverse() -> void:
    ranger_id_to_en.clear()
    for english_variant: Variant in ranger_en_to_id.keys():
        var english_text: String = str(english_variant)
        ranger_id_to_en[str(ranger_en_to_id[english_variant])] = english_text

func _ensure_language_controls() -> void:
    super._ensure_language_controls()
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    if scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        var settings_box: VBoxContainer = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel/VBox") as VBoxContainer
        var settings_panel: PanelContainer = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel") as PanelContainer
        _ensure_button_in_box(settings_box, settings_panel)
        _ensure_ranger_menu_button(scene)
        journal_language_button = null
    else:
        top_language_button = null
        _ensure_journal_button()

func _ensure_ranger_menu_button(scene: Node) -> void:
    var root: Control = scene.get_node_or_null("MenuLayer/Root") as Control
    if root == null:
        return
    top_language_button = root.get_node_or_null("LanguageToggle") as Button
    if top_language_button == null:
        top_language_button = Button.new()
        top_language_button.name = "LanguageToggle"
        top_language_button.focus_mode = Control.FOCUS_NONE
        top_language_button.anchor_left = 1.0
        top_language_button.anchor_right = 1.0
        top_language_button.offset_left = -184.0
        top_language_button.offset_top = 12.0
        top_language_button.offset_right = -12.0
        top_language_button.offset_bottom = 50.0
        root.add_child(top_language_button)
    top_language_button.visible = true
    _set_language_button_text(top_language_button)

func _ensure_journal_button() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        journal_language_button = null
        return
    var layer_value: Variant = journal.get("layer")
    if not (layer_value is CanvasLayer):
        return
    var layer: CanvasLayer = layer_value as CanvasLayer
    journal_language_button = layer.get_node_or_null("LanguageToggle") as Button
    if journal_language_button == null:
        journal_language_button = Button.new()
        journal_language_button.name = "LanguageToggle"
        journal_language_button.focus_mode = Control.FOCUS_NONE
        journal_language_button.anchor_left = 1.0
        journal_language_button.anchor_right = 1.0
        journal_language_button.offset_left = -184.0
        journal_language_button.offset_top = 12.0
        journal_language_button.offset_right = -12.0
        journal_language_button.offset_bottom = 50.0
        layer.add_child(journal_language_button)
    journal_language_button.visible = journal.has_method("is_open") and bool(journal.call("is_open"))
    _set_language_button_text(journal_language_button)

func _set_language_button_text(button: Button) -> void:
    if button == null:
        return
    if language_code == "id":
        button.text = "BAHASA: INDONESIA"
        button.tooltip_text = "Ganti ke English"
    else:
        button.text = "LANGUAGE: ENGLISH"
        button.tooltip_text = "Switch to Bahasa Indonesia"

func _apply_localization() -> void:
    super._apply_localization()
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    if scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        _localize_main_menu(scene)
    _localize_ranger_hud()
    _localize_mobile_buttons()
    _localize_world_labels(scene)
    _sync_evidence_journal()
    if top_language_button != null and is_instance_valid(top_language_button):
        _set_language_button_text(top_language_button)
    if journal_language_button != null and is_instance_valid(journal_language_button):
        _set_language_button_text(journal_language_button)

func _localize_ui_exact(text: String) -> String:
    var canonical: String = str(ranger_id_to_en.get(text, text))
    var result: String = super._localize_ui_exact(canonical)
    if language_code == "id" and ranger_en_to_id.has(canonical):
        return str(ranger_en_to_id[canonical])
    if language_code == "en":
        return str(ranger_id_to_en.get(result, result))
    return result

func _localize_status(text: String) -> String:
    var canonical: String = str(ranger_id_to_en.get(text, text))
    var result: String = super._localize_status(canonical)
    if language_code == "id" and ranger_en_to_id.has(canonical):
        return str(ranger_en_to_id[canonical])
    if language_code == "en":
        return str(ranger_id_to_en.get(result, result))
    return result

func _canonicalize_text(text: String) -> String:
    var result: String = str(ranger_id_to_en.get(text, text))
    result = super._canonicalize_text(result)
    result = result.replace("Menyiapkan ranger station di forest...", "Preparing the ranger station in the forest...")
    result = result.replace("Terhubung. Menyiapkan ranger investigation...", "Connected. Preparing the ranger investigation...")
    result = result.replace("Kamu membutuhkan Hunting Knife untuk memanen carcass tanpa merusak daging dan hide.", "You need the Hunting Knife to harvest the carcass without damaging the meat and hide.")
    result = result.replace("Carcass itu sudah tidak dapat dipanen.", "That carcass can no longer be harvested.")
    result = result.replace("Carcass itu sudah dipanen anggota tim lain.", "That carcass was already harvested by another teammate.")
    return result

func _translate_gameplay_to_indonesian(text: String) -> String:
    if ranger_en_to_id.has(text):
        return str(ranger_en_to_id[text])
    var result: String = super._translate_gameplay_to_indonesian(text)
    result = result.replace("Read ", "Baca ")
    result = result.replace("Inspect evidence: ", "Periksa bukti: ")
    result = result.replace(" — reviewed", " — sudah diperiksa")
    result = result.replace("Revive ", "Bangkitkan ")
    result = result.replace("RANGER CACHE: ", "CACHE RANGER: ")
    result = result.replace("WEATHER ", "CUACA ")
    result = result.replace("WET ", "BASAH ")
    result = result.replace("CLEAR", "CERAH")
    result = result.replace("CLOUDY", "BERAWAN")
    result = result.replace("RAIN", "HUJAN")
    result = result.replace("STORM", "BADAI")
    result = result.replace("BLEEDING ", "PENDARAHAN ")
    result = result.replace("INFECTION ", "INFEKSI ")
    result = result.replace("CURRENT MISSION", "MISI SAAT INI")
    result = result.replace("OBJECTIVE:", "TUJUAN:")
    result = result.replace("CONTEXT:", "KONTEKS:")
    result = result.replace("RULE:", "ATURAN:")
    result = result.replace("RESULT:", "HASIL:")
    result = result.replace("AFTER COMPLETION:", "SETELAH SELESAI:")
    result = result.replace("SAFE ZONE:", "ZONA AMAN:")
    result = result.replace("ROUTE:", "RUTE:")
    for english_variant: Variant in ranger_en_to_id.keys():
        var english_text: String = str(english_variant)
        result = result.replace(english_text, str(ranger_en_to_id[english_variant]))
    return result

func get_journal_entry_data(entry_id: String) -> Dictionary:
    var id_mode: bool = language_code == "id"
    match entry_id:
        "investigation_survey_manifest":
            if id_mode:
                return {"title": "Manifest Tim Survey", "category": "BUKTI KASUS", "body": "Empat anggota tim survey meninggalkan ranger station menuju rumah kosong di sektor barat. Jejak terakhir mengarah ke SPBU tua dan simbol tambang."}
            return {"title": "Survey Team Manifest", "category": "CASE EVIDENCE", "body": "Four survey team members left the ranger station for the abandoned house in the western sector. Their last trail points to the old gas station and a mine symbol."}
        "investigation_radio_trace":
            if id_mode:
                return {"title": "Log Frekuensi Radio Rusak", "category": "SINYAL", "body": "Radio tua merekam burst pada frekuensi maintenance yang mengarah ke gudang lama dan akses shaft."}
            return {"title": "Broken Radio Frequency Log", "category": "SIGNAL", "body": "The old radio recorded a maintenance-frequency burst pointing to the old warehouse and shaft access."}
        "investigation_maintenance_map":
            if id_mode:
                return {"title": "Peta Maintenance — Tambang Tua", "category": "PETA", "body": "Peta gudang menunjukkan jalur servis menuju Tambang Tua dan FACILITY ACCESS / LEVEL 03."}
            return {"title": "Maintenance Map — Old Mine", "category": "MAP", "body": "The warehouse map shows a service route to the Old Mine and FACILITY ACCESS / LEVEL 03."}
        "investigation_water_sample":
            if id_mode:
                return {"title": "Catatan Sampel Air Dingin", "category": "SAMPEL LAPANGAN", "body": "Air pompa lebih dingin dari udara sekitar dan membuat sensor cahaya ranger berkedip."}
            return {"title": "Cold Water Sample Note", "category": "FIELD SAMPLE", "body": "The pump water is colder than the surrounding air and makes the ranger light sensor flicker."}
        "investigation_foreman_log":
            if id_mode:
                return {"title": "Shift Terakhir Foreman", "category": "LOG TAMBANG", "body": "Tim tambang menemukan pintu logam yang tidak tercantum pada izin. Setelah dibuka, lorong dilaporkan berubah saat lampu padam."}
            return {"title": "Foreman's Last Shift", "category": "MINE LOG", "body": "The mining crew found an unlisted metal door. After it opened, corridors were reported to change when the lights went out."}
        "investigation_sealed_shaft_report":
            if id_mode:
                return {"title": "Laporan Insiden Shaft Tersegel", "category": "INSIDEN", "body": "Shaft terdalam ditutup setelah tiga pekerja menghilang. Helm dan lampu mereka ditemukan tanpa jejak keluar."}
            return {"title": "Sealed Shaft Incident Report", "category": "INCIDENT", "body": "The deepest shaft was sealed after three workers vanished. Their helmets and lamps were found with no tracks leading out."}
        "investigation_facility_badge":
            if id_mode:
                return {"title": "Badge Akses Fasilitas T-03", "category": "AKSES", "body": "Badge teknisi berkode T-03 membuka jalur menuju Labyrinth."}
            return {"title": "Facility Access Badge T-03", "category": "ACCESS", "body": "A technician badge marked T-03 opens the route to the Labyrinth."}
        "investigation_facility_terminal":
            if id_mode:
                return {"title": "Tabel Routing Fasilitas Terbatas", "category": "TERBATAS", "body": "Data Labyrinth mengarah ke rumah sakit, museum, laboratorium containment, gua, dan simpul Labyrinth lain."}
            return {"title": "Restricted Facility Routing Table", "category": "RESTRICTED", "body": "Labyrinth data points to a hospital, museum, containment laboratory, cave system, and other Labyrinth nodes."}
    return {}

func _sync_evidence_journal() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var entries_value: Variant = journal.get("entries")
    if not (entries_value is Dictionary):
        return
    var entries: Dictionary = Dictionary(entries_value)
    var evidence_ids: PackedStringArray = PackedStringArray([
        "investigation_survey_manifest",
        "investigation_radio_trace",
        "investigation_maintenance_map",
        "investigation_water_sample",
        "investigation_foreman_log",
        "investigation_sealed_shaft_report",
        "investigation_facility_badge",
        "investigation_facility_terminal"
    ])
    for entry_id: String in evidence_ids:
        if entries.has(entry_id):
            entries[entry_id] = get_journal_entry_data(entry_id)

func _localize_ranger_hud() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var case_file: Label = player.get_node_or_null("HUD/CaseFile") as Label
    if case_file != null:
        case_file.text = localize_gameplay_text(case_file.text)
    var shelter_status: Label = player.get_node_or_null("HUD/ShelterStatus") as Label
    if shelter_status != null:
        shelter_status.text = localize_gameplay_text(shelter_status.text)

func _localize_mobile_buttons() -> void:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile == null:
        return
    var layer_value: Variant = mobile.get("layer")
    if not (layer_value is CanvasLayer):
        return
    var layer: CanvasLayer = layer_value as CanvasLayer
    for node: Node in layer.find_children("*", "Button", true, false):
        var button: Button = node as Button
        if button != null:
            button.text = _localize_ui_exact(button.text)

func _localize_world_labels(scene: Node) -> void:
    for node: Node in scene.find_children("*", "Label3D", true, false):
        var label: Label3D = node as Label3D
        if label != null:
            label.text = localize_gameplay_text(label.text)

func _localize_inventory(text: String) -> String:
    var result: String = super._localize_inventory(text)
    for english_variant: Variant in ranger_en_to_id.keys():
        var english_text: String = str(english_variant)
        var id_text: String = str(ranger_en_to_id[english_variant])
        if language_code == "id":
            result = result.replace(english_text, id_text)
        else:
            result = result.replace(id_text, english_text)
    return result

func _localize_controls_text(text: String) -> String:
    var result: String = super._localize_controls_text(text)
    if language_code == "id":
        result = result.replace("Inspect/Use", "Periksa/Gunakan")
        result = result.replace("E Inspect", "E Periksa")
        result = result.replace("J Evidence Journal", "J Jurnal Bukti")
        result = result.replace("J Journal", "J Jurnal")
        result = result.replace("K Save", "K Simpan")
    else:
        result = result.replace("Periksa/Gunakan", "Inspect/Use")
        result = result.replace("E Periksa", "E Inspect")
        result = result.replace("J Jurnal Bukti", "J Evidence Journal")
        result = result.replace("J Jurnal", "J Journal")
        result = result.replace("K Simpan", "K Save")
    return result
