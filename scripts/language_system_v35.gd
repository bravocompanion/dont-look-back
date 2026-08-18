extends "res://scripts/language_system.gd"

# v0.35 parser-safe Ranger localization layer.
# This intentionally avoids the v34 -> v34b -> v34c inheritance chain and
# nested typed translation arrays that made the localization autoload fragile.

const RANGER_MENU_SCENE_PATH: String = "res://scenes/main_menu_ranger.tscn"
const LANGUAGE_BUTTON_NAME: String = "LanguageToggle"

var extra_en_to_id: Dictionary = {}
var extra_id_to_en: Dictionary = {}
var phrase_pairs: Array = []
var journal_entries: Dictionary = {}
var top_menu_switch: Button = null
var top_journal_switch: Button = null

func _ready() -> void:
    _build_ranger_dictionary()
    _build_phrase_pairs()
    _build_journal_entries()
    super._ready()
    process_priority = 220
    _rebuild_extra_reverse_map()

func _load_language() -> void:
    language_code = "id"
    var config := ConfigFile.new()
    if config.load(LANGUAGE_PATH) != OK:
        return
    var saved := str(config.get_value("language", "locale", ""))
    if saved.is_empty():
        saved = str(config.get_value("localization", "language", "id"))
    saved = saved.to_lower()
    if SUPPORTED_LANGUAGES.has(saved):
        language_code = saved

func _save_language() -> void:
    var config := ConfigFile.new()
    config.set_value("language", "locale", language_code)
    config.set_value("localization", "language", language_code)
    config.save(LANGUAGE_PATH)

func _build_ranger_dictionary() -> void:
    extra_en_to_id = {
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
        "DOWNED": "TUMBANG",
        "USE TO REVIVE": "GUNAKAN UNTUK MEMBANGKITKAN",
        "YOU ARE DOWNED": "KAMU TUMBANG",
        "CASE FILE": "BERKAS KASUS",
        "CASE EVIDENCE": "BUKTI KASUS",
        "FIELD SAMPLE": "SAMPEL LAPANGAN",
        "MINE LOG": "LOG TAMBANG",
        "INCIDENT": "INSIDEN",
        "ACCESS": "AKSES",
        "RESTRICTED": "TERBATAS",
        "SIGNAL": "SINYAL",
        "MAP": "PETA",
        "EXPEDITION BOARD": "PAPAN EKSPEDISI",
        "Review Ranger Case Board": "Periksa Papan Kasus Ranger",
        "Enter Old Mine": "Masuk ke Tambang Tua",
        "Old Mine sealed — find the maintenance map": "Tambang Tua terkunci — cari peta maintenance",
        "Return to Ranger Forest": "Kembali ke Hutan Ranger",
        "Enter Labyrinth / Facility Level 03": "Masuk Labyrinth / Fasilitas Level 03",
        "Facility gate locked — find an access badge": "Gerbang fasilitas terkunci — cari badge akses",
        "Deeper route locked — more evidence required": "Jalur lebih dalam terkunci — butuh bukti tambahan",
        "Light campfire (Firewood/Wood)": "Nyalakan api unggun (Kayu Bakar/Kayu)",
        "Sleep until morning": "Tidur sampai pagi",
        "Sleep until morning (host only)": "Tidur sampai pagi (hanya host)",
        "Shared storage (host controlled)": "Penyimpanan bersama (dikontrol host)",
        "Storage: STORE one supply": "Penyimpanan: SIMPAN satu suplai",
        "Storage: TAKE one supply": "Penyimpanan: AMBIL satu suplai",
        "Craft Firewood Bundle (2 Wood)": "Buat Bundel Kayu Bakar (2 Kayu)",
        "Craft Improvised Battery (1 Wood + 2 Scrap)": "Buat Baterai Improvisasi (1 Kayu + 2 Besi Bekas)",
        "Craft Bandage (2 Cloth)": "Buat Perban (2 Kain)",
        "Cooking rack": "Rak memasak",
        "Cooking rack — light the campfire first": "Rak memasak — nyalakan api unggun terlebih dahulu",
        "Cook Raw Meat": "Masak Daging Mentah",
        "Cook Raw Fish": "Masak Ikan Mentah",
        "Cooking rack — no raw food": "Rak memasak — tidak ada makanan mentah",
        "Fishing spot — but you need a Fishing Rod": "Tempat memancing — kamu membutuhkan Pancing",
        "Fish here": "Memancing di sini",
        "Collect Dirty Water": "Ambil Air Kotor",
        "Boil Dirty Water": "Rebus Air Kotor",
        "Carcass already harvested": "Bangkai sudah dipanen",
        "Empty survival cache": "Cache survival kosong",
        "Search old ranger survival cache": "Periksa cache survival ranger lama",
        "Dirty Water": "Air Kotor",
        "Clean Water": "Air Bersih",
        "Wood": "Kayu",
        "Scrap": "Besi Bekas",
        "Fuel Can": "Jeriken Bahan Bakar",
        "Firewood Bundle": "Bundel Kayu Bakar",
        "Improvised Battery": "Baterai Improvisasi",
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
        "Preparing the ranger station in the forest...": "Menyiapkan ranger station di hutan...",
        "Connected. Preparing the ranger investigation...": "Terhubung. Menyiapkan investigasi ranger...",
        "NEW GAME: Ranger Forest → evidence → Old Mine → Labyrinth → Research Facility.": "GAME BARU: Hutan Ranger → bukti → Tambang Tua → Labyrinth → Fasilitas Riset.",
        "The game starts in Ranger Forest. Progress follows Forest → Mine → Labyrinth → Research Facility.": "Game dimulai di Hutan Ranger. Progress mengikuti Hutan → Tambang → Labyrinth → Fasilitas Riset.",
        "Start as a ranger at the forest cabin. Survive first, then follow the evidence.": "Mulai sebagai ranger di cabin hutan. Bertahan dulu, lalu ikuti bukti.",
        "Host co-op starts in the same Ranger Forest.": "Host co-op dimulai di Hutan Ranger yang sama.",
        "Join the host and synchronize to the host's investigation scene.": "Gabung ke host dan sinkron ke scene investigasi host.",
        "RANGER DEPLOYMENT: Cabin behind you. Face the forest, secure the shelter, then begin the investigation.": "DEPLOYMENT RANGER: Cabin ada di belakangmu. Hadapi hutan, amankan base, lalu mulai investigasi.",
        "RANGER BASE: Secure food, water, fuel, and light before night.": "BASE RANGER: Amankan makanan, air, bahan bakar, dan cahaya sebelum malam.",
        "MINE INVESTIGATION: Find evidence and the sealed facility access.": "INVESTIGASI TAMBANG: Temukan bukti dan akses fasilitas yang disegel.",
        "RESTRICTED FACILITY: Inspect the routing terminal.": "FASILITAS TERBATAS: Periksa terminal routing.",
        "Something is forming in the dark. GET TO THE LIGHT.": "Sesuatu sedang terbentuk dalam kegelapan. SEGERA KE CAHAYA.",
        "You're bleeding. Use a Bandage or Medkit before the wound gets infected.": "Kamu mengalami pendarahan. Gunakan Perban atau Medkit sebelum luka terinfeksi.",
        "You drink clean water.": "Kamu meminum air bersih.",
        "You drink untreated water. Thirst drops, but Infection rises.": "Kamu meminum air tanpa pengolahan. Haus berkurang, tetapi Infeksi meningkat.",
        "You bind the wound with a Bandage.": "Kamu membalut luka dengan Perban.",
        "You clean and dress your wounds with the Medkit.": "Kamu membersihkan dan merawat luka dengan Medkit.",
        "You need a Bandage or Medkit to stop the bleeding.": "Kamu membutuhkan Perban atau Medkit untuk menghentikan pendarahan.",
        "You need a Medkit to treat the infection.": "Kamu membutuhkan Medkit untuk mengobati infeksi.",
        "You do not need medical aid right now.": "Kamu belum membutuhkan bantuan medis saat ini.",
        "You have no medical supplies.": "Kamu tidak punya persediaan medis.",
        "You need the Fishing Rod from the ranger cache before fishing.": "Kamu membutuhkan Pancing dari cache ranger sebelum memancing.",
        "You need the Hunting Bow from the ranger cache.": "Kamu membutuhkan Busur Berburu dari cache ranger.",
        "No arrows left. Search containers or return to the ranger cache on a fresh run.": "Panah habis. Cari container atau kembali ke cache ranger pada run baru.",
        "The arrow vanishes between the trees.": "Panah menghilang di antara pepohonan.",
        "The arrow strikes something that is not prey.": "Panah mengenai sesuatu yang bukan hewan buruan.",
        "A survivor must reach you and revive you.\nStay together. Light protects the team.": "Seorang survivor harus mencapai dan membangkitkanmu.\nTetap bersama. Cahaya melindungi tim.",
        "Need at least 2 survivors before START.": "Butuh setidaknya 2 survivor sebelum MULAI.",
        "Every connected survivor must be READY.": "Semua survivor yang terhubung harus SIAP.",
        "Player not ready yet.": "Player belum siap.",
        "Team ready. Stay together and keep the light moving.": "Tim siap. Tetap bersama dan jaga cahaya terus bergerak."
    }

func _build_phrase_pairs() -> void:
    phrase_pairs = [
        ["Read ", "Baca "],
        ["Inspect evidence: ", "Periksa bukti: "],
        [" — reviewed", " — sudah diperiksa"],
        ["Feed campfire (", "Tambah bahan bakar api unggun ("],
        ["Refuel generator (", "Isi bahan bakar generator ("],
        ["Water source recovering (", "Sumber air pulih kembali ("],
        ["Harvest ", "Panen bangkai "],
        [" carcass (Hunting Knife)", " (Pisau Berburu)"],
        ["Revive ", "Bangkitkan "],
        ["RANGER CACHE: ", "CACHE RANGER: "],
        [" Arrows", " Panah"],
        ["WEATHER ", "CUACA "],
        ["WET ", "BASAH "],
        ["CLEAR", "CERAH"],
        ["CLOUDY", "BERAWAN"],
        ["RAIN", "HUJAN"],
        ["STORM", "BADAI"],
        ["BLEEDING ", "PENDARAHAN "],
        ["BLEED ", "DARAH "],
        ["INFECTION ", "INFEKSI "],
        ["FISHING: caught ", "MEMANCING: mendapat "],
        [" freshwater fish. Cook it before eating.", " ikan air tawar. Masak sebelum dimakan."],
        ["HUNT: ", "BURU: "],
        ["HARVEST: ", "PANEN: "],
        [". Raw food must be cooked at the campfire.", ". Makanan mentah harus dimasak di api unggun."],
        ["CURRENT MISSION", "MISI SAAT INI"],
        ["OBJECTIVE:", "TUJUAN:"],
        ["CONTEXT:", "KONTEKS:"],
        ["RULE:", "ATURAN:"],
        ["RESULT:", "HASIL:"],
        ["AFTER COMPLETION:", "SETELAH SELESAI:"],
        ["SAFE ZONE:", "ZONA AMAN:"],
        ["ROUTE:", "RUTE:"],
        ["Old Mine", "Tambang Tua"],
        ["Research Facility", "Fasilitas Riset"],
        ["Abandoned House", "Rumah Kosong"],
        ["Old Gas Station", "SPBU Tua"],
        ["Warehouse", "Gudang"],
        ["Water Pump", "Pompa Air"]
    ]

func _build_journal_entries() -> void:
    journal_entries = {
        "investigation_survey_manifest": {
            "id_title": "Manifest Tim Survey",
            "en_title": "Survey Team Manifest",
            "id_category": "BUKTI KASUS",
            "en_category": "CASE EVIDENCE",
            "id_body": "Empat anggota tim survey meninggalkan ranger station menuju rumah kosong di sektor barat. Catatan terakhir menyebut mereka berencana mencari radio kendaraan di SPBU tua setelah menemukan simbol tambang pada dinding basement.",
            "en_body": "Four survey team members left the ranger station for the abandoned house in the western sector. Their final note says they planned to look for the vehicle radio at the old gas station after finding a mine symbol on the basement wall."
        },
        "investigation_radio_trace": {
            "id_title": "Log Frekuensi Radio Rusak",
            "en_title": "Broken Radio Frequency Log",
            "id_category": "SINYAL",
            "en_category": "SIGNAL",
            "id_body": "Radio tua merekam burst pendek pada frekuensi maintenance. Koordinatnya mengarah ke gudang lama. Pesan yang tersisa hanya: shaft access... map cabinet... jangan gunakan jalan utama setelah gelap.",
            "en_body": "The old radio recorded a short burst on the maintenance frequency. Its coordinates point to the old warehouse. The remaining message says only: shaft access... map cabinet... do not use the main road after dark."
        },
        "investigation_maintenance_map": {
            "id_title": "Peta Maintenance — Tambang Tua",
            "en_title": "Maintenance Map — Old Mine",
            "id_category": "PETA",
            "en_category": "MAP",
            "id_body": "Peta gudang menunjukkan jalur servis menuju sebuah mine shaft di sudut barat-daya hutan. Di bawah simbol tambang ada jalur lain yang diberi label FACILITY ACCESS / LEVEL 03.",
            "en_body": "The warehouse map shows a service path to a mine shaft in the southwest corner of the forest. Beneath the mine symbol is another route labeled FACILITY ACCESS / LEVEL 03."
        },
        "investigation_water_sample": {
            "id_title": "Catatan Sampel Air Dingin",
            "en_title": "Cold Water Sample Note",
            "id_category": "SAMPEL LAPANGAN",
            "en_category": "FIELD SAMPLE",
            "id_body": "Air pompa tetap beberapa derajat lebih dingin dari udara sekitar dan menyebabkan sensor cahaya ranger berkedip. Fenomena yang sama disebut dalam laporan fasilitas bawah tanah.",
            "en_body": "The pump water stays several degrees colder than the surrounding air and makes the ranger light sensor flicker. The same phenomenon is mentioned in underground facility reports."
        },
        "investigation_foreman_log": {
            "id_title": "Shift Terakhir Foreman",
            "en_title": "Foreman's Last Shift",
            "id_category": "LOG TAMBANG",
            "en_category": "MINE LOG",
            "id_body": "Tim tambang menemukan pintu logam yang tidak tercantum pada izin penggalian. Setelah pintu itu terbuka, pekerja mulai melaporkan lorong yang berubah panjang ketika lampu dimatikan.",
            "en_body": "The mining crew found a metal door not listed on the excavation permit. After it was opened, workers began reporting corridors that changed length when the lights were switched off."
        },
        "investigation_sealed_shaft_report": {
            "id_title": "Laporan Insiden Shaft Tersegel",
            "en_title": "Sealed Shaft Incident Report",
            "id_category": "INSIDEN",
            "en_category": "INCIDENT",
            "id_body": "Shaft terdalam ditutup setelah tiga pekerja menghilang dalam jarak kurang dari dua puluh meter. Tim recovery menemukan helm dan lampu mereka, tetapi tidak menemukan jejak keluar dari terowongan.",
            "en_body": "The deepest shaft was sealed after three workers vanished within less than twenty meters. The recovery team found their helmets and lamps, but no tracks leading out of the tunnel."
        },
        "investigation_facility_badge": {
            "id_title": "Badge Akses Fasilitas T-03",
            "en_title": "Facility Access Badge T-03",
            "id_category": "AKSES",
            "en_category": "ACCESS",
            "id_body": "Badge milik teknisi fasilitas berada di dekat gerbang bawah tambang. Kode T-03 cocok dengan referensi fenomena occupancy pada catatan lama. Badge ini membuka jalur menuju Labyrinth.",
            "en_body": "A facility technician's badge lies near the lower mine gate. The T-03 code matches old references to the occupancy phenomenon. This badge opens the route to the Labyrinth."
        },
        "investigation_facility_terminal": {
            "id_title": "Tabel Routing Fasilitas Terbatas",
            "en_title": "Restricted Facility Routing Table",
            "id_category": "TERBATAS",
            "en_category": "RESTRICTED",
            "id_body": "Data dari Labyrinth mengarah ke jaringan lokasi lain: rumah sakit, museum, laboratorium containment, sistem gua, dan beberapa simpul Labyrinth lain. Hutan hanyalah base pertama; investigasi baru dimulai.",
            "en_body": "Data from the Labyrinth points to a network of other locations: a hospital, museum, containment laboratory, cave system, and several other Labyrinth nodes. The forest is only the first base; the investigation has just begun."
        }
    }

func _rebuild_extra_reverse_map() -> void:
    extra_id_to_en.clear()
    for english_text in extra_en_to_id.keys():
        extra_id_to_en[str(extra_en_to_id[english_text])] = str(english_text)

func _ensure_language_controls() -> void:
    super._ensure_language_controls()
    var scene := get_tree().current_scene
    if scene == null:
        return
    if scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        _ensure_top_menu_switch(scene)
        top_journal_switch = null
    else:
        top_menu_switch = null
        _ensure_top_journal_switch()

func _ensure_top_menu_switch(scene: Node) -> void:
    var root := scene.get_node_or_null("MenuLayer/Root")
    if root == null or not (root is Control):
        return
    top_menu_switch = root.get_node_or_null(LANGUAGE_BUTTON_NAME)
    if top_menu_switch == null:
        top_menu_switch = Button.new()
        top_menu_switch.name = LANGUAGE_BUTTON_NAME
        top_menu_switch.focus_mode = Control.FOCUS_NONE
        top_menu_switch.anchor_left = 1.0
        top_menu_switch.anchor_right = 1.0
        top_menu_switch.offset_left = -184.0
        top_menu_switch.offset_top = 12.0
        top_menu_switch.offset_right = -12.0
        top_menu_switch.offset_bottom = 50.0
        top_menu_switch.add_theme_font_size_override("font_size", 13)
        top_menu_switch.pressed.connect(_toggle_language)
        root.add_child(top_menu_switch)
    top_menu_switch.visible = true
    _set_language_button_text(top_menu_switch)

func _ensure_top_journal_switch() -> void:
    var journal := get_node_or_null("/root/JournalSystem")
    if journal == null:
        top_journal_switch = null
        return
    var layer = journal.get("layer")
    if not (layer is CanvasLayer):
        return
    top_journal_switch = layer.get_node_or_null(LANGUAGE_BUTTON_NAME)
    if top_journal_switch == null:
        top_journal_switch = Button.new()
        top_journal_switch.name = LANGUAGE_BUTTON_NAME
        top_journal_switch.focus_mode = Control.FOCUS_NONE
        top_journal_switch.anchor_left = 1.0
        top_journal_switch.anchor_right = 1.0
        top_journal_switch.offset_left = -184.0
        top_journal_switch.offset_top = 12.0
        top_journal_switch.offset_right = -12.0
        top_journal_switch.offset_bottom = 50.0
        top_journal_switch.add_theme_font_size_override("font_size", 13)
        top_journal_switch.pressed.connect(_toggle_language)
        layer.add_child(top_journal_switch)
    top_journal_switch.visible = journal.has_method("is_open") and bool(journal.call("is_open"))
    _set_language_button_text(top_journal_switch)

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
    var scene := get_tree().current_scene
    if scene == null:
        return
    if scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        _localize_main_menu(scene)
    _localize_current_hud_extras()
    _localize_mobile_controls()
    _localize_world_labels(scene)
    _localize_runtime_autoload_ui()
    _sync_journal_entries()
    _sync_world_note_sources()
    if top_menu_switch != null and is_instance_valid(top_menu_switch):
        _set_language_button_text(top_menu_switch)
    if top_journal_switch != null and is_instance_valid(top_journal_switch):
        _set_language_button_text(top_journal_switch)

func _localize_ui_exact(text: String) -> String:
    var canonical := str(extra_id_to_en.get(text, text))
    var parent_result := super._localize_ui_exact(canonical)
    if language_code == "id" and extra_en_to_id.has(canonical):
        return str(extra_en_to_id[canonical])
    if language_code == "en" and extra_id_to_en.has(parent_result):
        return str(extra_id_to_en[parent_result])
    return parent_result

func _localize_status(text: String) -> String:
    var canonical := str(extra_id_to_en.get(text, text))
    var parent_result := super._localize_status(canonical)
    if language_code == "id" and extra_en_to_id.has(canonical):
        return str(extra_en_to_id[canonical])
    if language_code == "en":
        return str(extra_id_to_en.get(parent_result, parent_result))
    return parent_result

func _canonicalize_text(text: String) -> String:
    var result := str(extra_id_to_en.get(text, text))
    result = super._canonicalize_text(result)
    for pair in phrase_pairs:
        if pair is Array and pair.size() >= 2:
            result = result.replace(str(pair[1]), str(pair[0]))
    for id_text in extra_id_to_en.keys():
        result = result.replace(str(id_text), str(extra_id_to_en[id_text]))
    result = result.replace("Menyiapkan ranger station di forest...", "Preparing the ranger station in the forest...")
    result = result.replace("Terhubung. Menyiapkan ranger investigation...", "Connected. Preparing the ranger investigation...")
    result = result.replace("Kamu membutuhkan Hunting Knife untuk memanen carcass tanpa merusak daging dan hide.", "You need the Hunting Knife to harvest the carcass without damaging the meat and hide.")
    result = result.replace("Carcass itu sudah tidak dapat dipanen.", "That carcass can no longer be harvested.")
    result = result.replace("Carcass itu sudah dipanen anggota tim lain.", "That carcass was already harvested by another teammate.")
    return result

func _translate_gameplay_to_indonesian(text: String) -> String:
    if extra_en_to_id.has(text):
        return str(extra_en_to_id[text])
    var result := super._translate_gameplay_to_indonesian(text)
    for pair in phrase_pairs:
        if pair is Array and pair.size() >= 2:
            result = result.replace(str(pair[0]), str(pair[1]))
    for english_text in extra_en_to_id.keys():
        result = result.replace(str(english_text), str(extra_en_to_id[english_text]))
    return result

func get_journal_entry_data(entry_id: String) -> Dictionary:
    if not journal_entries.has(entry_id):
        return {}
    var row: Dictionary = journal_entries[entry_id]
    if language_code == "id":
        return {
            "title": str(row.get("id_title", entry_id)),
            "category": str(row.get("id_category", "CATATAN")),
            "body": str(row.get("id_body", ""))
        }
    return {
        "title": str(row.get("en_title", entry_id)),
        "category": str(row.get("en_category", "NOTE")),
        "body": str(row.get("en_body", ""))
    }

func _sync_journal_entries() -> void:
    var journal := get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var entries = journal.get("entries")
    if not (entries is Dictionary):
        return
    var changed := false
    for entry_id in journal_entries.keys():
        if entries.has(entry_id):
            entries[entry_id] = get_journal_entry_data(str(entry_id))
            changed = true
    if changed and journal.has_method("is_open") and bool(journal.call("is_open")) and journal.has_method("_update_entry_display"):
        journal.call("_update_entry_display")

func _sync_world_note_sources() -> void:
    for node in get_tree().get_nodes_in_group("journal_note"):
        if node == null or not is_instance_valid(node):
            continue
        var entry_id := str(node.get("entry_id"))
        var data := get_journal_entry_data(entry_id)
        if data.is_empty():
            continue
        node.set("entry_title", str(data.get("title", "")))
        node.set("entry_category", str(data.get("category", "")))
        node.set("entry_body", str(data.get("body", "")))

func _localize_current_hud_extras() -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player == null:
        return
    var paths := ["HUD/CaseFile", "HUD/ShelterStatus"]
    for path in paths:
        var label := player.get_node_or_null(path)
        if label is Label:
            label.text = localize_gameplay_text(label.text)
    var top_bar := player.get_node_or_null("HUD/TopStatusBarV32")
    if top_bar != null:
        for node in top_bar.find_children("*", "Label", true, false):
            if node is Label:
                node.text = _localize_stat_line(node.text)
    var end_panel := player.get_node_or_null("HUD/EndPanel")
    if end_panel != null:
        _localize_control_tree(end_panel)

func _localize_mobile_controls() -> void:
    var mobile := get_node_or_null("/root/MobileControls")
    if mobile == null:
        return
    var layer = mobile.get("layer")
    if not (layer is CanvasLayer):
        return
    for node in layer.find_children("*", "Button", true, false):
        if node is Button:
            node.text = _localize_ui_exact(node.text)

func _localize_world_labels(scene: Node) -> void:
    for node in scene.find_children("*", "Label3D", true, false):
        if node is Label3D:
            node.text = localize_gameplay_text(node.text)

func _localize_runtime_autoload_ui() -> void:
    var forest_runtime := get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if forest_runtime != null:
        _localize_property_tree(forest_runtime, "ui_layer")
    var coop := get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        _localize_property_tree(coop, "downed_layer")
    var polish := get_node_or_null("/root/MultiplayerPolishSystem")
    if polish != null:
        _localize_property_tree(polish, "layer")
    var depth := get_node_or_null("/root/SurvivalDepthSystem")
    if depth != null:
        var status = _safe_property(depth, "status_label")
        if status is Label:
            status.text = localize_gameplay_text(status.text)

func _localize_property_tree(owner: Object, property_name: String) -> void:
    var value = _safe_property(owner, property_name)
    if value is Node:
        _localize_runtime_tree(value)

func _localize_runtime_tree(node: Node) -> void:
    if node is Button:
        if node.name != LANGUAGE_BUTTON_NAME:
            node.text = _localize_ui_exact(node.text)
    elif node is Label:
        node.text = localize_gameplay_text(_localize_ui_exact(node.text))
    elif node is RichTextLabel:
        node.text = localize_gameplay_text(node.text)
    elif node is LineEdit:
        node.placeholder_text = _localize_ui_exact(node.placeholder_text)
    for child in node.get_children():
        _localize_runtime_tree(child)

func _safe_property(owner: Object, property_name: String):
    if owner == null:
        return null
    for info in owner.get_property_list():
        if str(info.get("name", "")) == property_name:
            return owner.get(property_name)
    return null

func _localize_inventory(text: String) -> String:
    var result := super._localize_inventory(text)
    for english_text in extra_en_to_id.keys():
        var id_text := str(extra_en_to_id[english_text])
        if language_code == "id":
            result = result.replace(str(english_text), id_text)
        else:
            result = result.replace(id_text, str(english_text))
    return result

func _localize_controls_text(text: String) -> String:
    var result := super._localize_controls_text(text)
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
