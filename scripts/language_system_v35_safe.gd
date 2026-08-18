extends "res://scripts/language_system.gd"

# Parser-safe Ranger localization hotfix.
# Keep this file deliberately simple so the localization autoload works across
# Godot 4.x versions used by the project.

const RANGER_MENU_SCENE_PATH = "res://scenes/main_menu_ranger.tscn"
const LANGUAGE_BUTTON_NAME = "LanguageToggle"

var extra_en_to_id = {}
var extra_id_to_en = {}
var journal_entries = {}
var top_menu_switch = null
var top_journal_switch = null

func _ready():
    _build_extra_dictionary()
    _build_journal_entries()
    _build_extra_reverse()
    super._ready()

func _load_language():
    language_code = "id"
    var config = ConfigFile.new()
    if config.load(LANGUAGE_PATH) != OK:
        return
    var saved = str(config.get_value("language", "locale", ""))
    if saved.is_empty():
        saved = str(config.get_value("localization", "language", "id"))
    saved = saved.to_lower()
    if SUPPORTED_LANGUAGES.has(saved):
        language_code = saved

func _save_language():
    var config = ConfigFile.new()
    config.set_value("language", "locale", language_code)
    config.set_value("localization", "language", language_code)
    config.save(LANGUAGE_PATH)

func _build_extra_dictionary():
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
        "YOU ARE DOWNED": "KAMU TUMBANG",
        "DOWNED": "TUMBANG",
        "USE TO REVIVE": "GUNAKAN UNTUK MEMBANGKITKAN",
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

func _build_extra_reverse():
    extra_id_to_en.clear()
    for key in extra_en_to_id.keys():
        extra_id_to_en[str(extra_en_to_id[key])] = str(key)

func _build_journal_entries():
    journal_entries = {
        "investigation_survey_manifest": ["Manifest Tim Survey", "Survey Team Manifest", "BUKTI KASUS", "CASE EVIDENCE", "Empat anggota tim survey meninggalkan ranger station menuju rumah kosong di sektor barat. Catatan terakhir mengarah ke SPBU tua dan simbol tambang.", "Four survey team members left the ranger station for the abandoned house in the western sector. Their final note points to the old gas station and a mine symbol."],
        "investigation_radio_trace": ["Log Frekuensi Radio Rusak", "Broken Radio Frequency Log", "SINYAL", "SIGNAL", "Radio tua merekam burst pendek pada frekuensi maintenance. Koordinatnya mengarah ke gudang lama dan akses shaft.", "The old radio recorded a short burst on the maintenance frequency. Its coordinates point to the old warehouse and shaft access."],
        "investigation_maintenance_map": ["Peta Maintenance — Tambang Tua", "Maintenance Map — Old Mine", "PETA", "MAP", "Peta gudang menunjukkan jalur servis menuju mine shaft dan jalur FACILITY ACCESS / LEVEL 03.", "The warehouse map shows a service path to a mine shaft and a route labeled FACILITY ACCESS / LEVEL 03."],
        "investigation_water_sample": ["Catatan Sampel Air Dingin", "Cold Water Sample Note", "SAMPEL LAPANGAN", "FIELD SAMPLE", "Air pompa tetap lebih dingin dari udara sekitar dan membuat sensor cahaya ranger berkedip.", "The pump water stays colder than the surrounding air and makes the ranger light sensor flicker."],
        "investigation_foreman_log": ["Shift Terakhir Foreman", "Foreman's Last Shift", "LOG TAMBANG", "MINE LOG", "Tim tambang menemukan pintu logam yang tidak tercantum pada izin penggalian. Setelah dibuka, lorong dilaporkan berubah panjang saat lampu dimatikan.", "The mining crew found a metal door not listed on the excavation permit. After it opened, corridors were reported to change length when the lights were switched off."],
        "investigation_sealed_shaft_report": ["Laporan Insiden Shaft Tersegel", "Sealed Shaft Incident Report", "INSIDEN", "INCIDENT", "Shaft terdalam ditutup setelah tiga pekerja menghilang. Helm dan lampu mereka ditemukan, tetapi tidak ada jejak keluar.", "The deepest shaft was sealed after three workers vanished. Their helmets and lamps were found, but there were no tracks leading out."],
        "investigation_facility_badge": ["Badge Akses Fasilitas T-03", "Facility Access Badge T-03", "AKSES", "ACCESS", "Badge teknisi fasilitas berkode T-03 membuka jalur menuju Labyrinth.", "A facility technician badge marked T-03 opens the route to the Labyrinth."],
        "investigation_facility_terminal": ["Tabel Routing Fasilitas Terbatas", "Restricted Facility Routing Table", "TERBATAS", "RESTRICTED", "Data Labyrinth mengarah ke rumah sakit, museum, laboratorium containment, sistem gua, dan simpul Labyrinth lain.", "Labyrinth data points to a hospital, museum, containment laboratory, cave system, and other Labyrinth nodes."]
    }

func get_journal_entry_data(entry_id):
    if not journal_entries.has(entry_id):
        return {}
    var row = journal_entries[entry_id]
    if row.size() < 6:
        return {}
    if language_code == "id":
        return {"title": str(row[0]), "category": str(row[2]), "body": str(row[4])}
    return {"title": str(row[1]), "category": str(row[3]), "body": str(row[5])}

func _ensure_language_controls():
    super._ensure_language_controls()
    var scene = get_tree().current_scene
    if scene == null:
        return
    if scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        var settings_box = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel/VBox")
        var settings_panel = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel")
        if settings_box is VBoxContainer and settings_panel is PanelContainer:
            _ensure_button_in_box(settings_box, settings_panel)
        _ensure_top_menu_switch(scene)
        top_journal_switch = null
    else:
        top_menu_switch = null
        _ensure_top_journal_switch()

func _ensure_top_menu_switch(scene):
    var root = scene.get_node_or_null("MenuLayer/Root")
    if not (root is Control):
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
        root.add_child(top_menu_switch)
    top_menu_switch.visible = true
    _set_language_button_text(top_menu_switch)

func _ensure_top_journal_switch():
    var journal = get_node_or_null("/root/JournalSystem")
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
        layer.add_child(top_journal_switch)
    top_journal_switch.visible = journal.has_method("is_open") and bool(journal.call("is_open"))
    _set_language_button_text(top_journal_switch)

func _set_language_button_text(button):
    if button == null:
        return
    if language_code == "id":
        button.text = "BAHASA: INDONESIA"
        button.tooltip_text = "Ganti ke English"
    else:
        button.text = "LANGUAGE: ENGLISH"
        button.tooltip_text = "Switch to Bahasa Indonesia"

func _apply_localization():
    super._apply_localization()
    var scene = get_tree().current_scene
    if scene == null:
        return
    if scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        _localize_main_menu(scene)
    _localize_ranger_hud()
    _localize_mobile_buttons()
    _localize_world_labels(scene)
    _sync_journal_entries()
    _sync_world_notes()
    if top_menu_switch != null and is_instance_valid(top_menu_switch):
        _set_language_button_text(top_menu_switch)
    if top_journal_switch != null and is_instance_valid(top_journal_switch):
        _set_language_button_text(top_journal_switch)

func _localize_ui_exact(text):
    var canonical = str(extra_id_to_en.get(text, text))
    var result = super._localize_ui_exact(canonical)
    if language_code == "id" and extra_en_to_id.has(canonical):
        return str(extra_en_to_id[canonical])
    if language_code == "en":
        return str(extra_id_to_en.get(result, result))
    return result

func _localize_status(text):
    var canonical = str(extra_id_to_en.get(text, text))
    var result = super._localize_status(canonical)
    if language_code == "id" and extra_en_to_id.has(canonical):
        return str(extra_en_to_id[canonical])
    if language_code == "en":
        return str(extra_id_to_en.get(result, result))
    return result

func _canonicalize_text(text):
    var result = str(extra_id_to_en.get(text, text))
    result = super._canonicalize_text(result)
    result = result.replace("Menyiapkan ranger station di forest...", "Preparing the ranger station in the forest...")
    result = result.replace("Terhubung. Menyiapkan ranger investigation...", "Connected. Preparing the ranger investigation...")
    result = result.replace("Kamu membutuhkan Hunting Knife untuk memanen carcass tanpa merusak daging dan hide.", "You need the Hunting Knife to harvest the carcass without damaging the meat and hide.")
    result = result.replace("Carcass itu sudah tidak dapat dipanen.", "That carcass can no longer be harvested.")
    result = result.replace("Carcass itu sudah dipanen anggota tim lain.", "That carcass was already harvested by another teammate.")
    return result

func _translate_gameplay_to_indonesian(text):
    if extra_en_to_id.has(text):
        return str(extra_en_to_id[text])
    var result = super._translate_gameplay_to_indonesian(text)
    var pairs = [
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
        ["CURRENT MISSION", "MISI SAAT INI"],
        ["OBJECTIVE:", "TUJUAN:"],
        ["CONTEXT:", "KONTEKS:"],
        ["RULE:", "ATURAN:"],
        ["RESULT:", "HASIL:"],
        ["AFTER COMPLETION:", "SETELAH SELESAI:"],
        ["SAFE ZONE:", "ZONA AMAN:"],
        ["ROUTE:", "RUTE:"]
    ]
    for pair in pairs:
        result = result.replace(str(pair[0]), str(pair[1]))
    for key in extra_en_to_id.keys():
        result = result.replace(str(key), str(extra_en_to_id[key]))
    return result

func _localize_ranger_hud():
    var player = get_tree().get_first_node_in_group("player")
    if player == null:
        return
    var paths = ["HUD/CaseFile", "HUD/ShelterStatus"]
    for path in paths:
        var label = player.get_node_or_null(path)
        if label is Label:
            label.text = localize_gameplay_text(label.text)
    var top_bar = player.get_node_or_null("HUD/TopStatusBarV32")
    if top_bar != null:
        for child in top_bar.find_children("*", "Label", true, false):
            if child is Label:
                child.text = _localize_stat_line(child.text)

func _localize_mobile_buttons():
    var mobile = get_node_or_null("/root/MobileControls")
    if mobile == null:
        return
    var layer = mobile.get("layer")
    if not (layer is CanvasLayer):
        return
    for child in layer.find_children("*", "Button", true, false):
        if child is Button:
            child.text = _localize_ui_exact(child.text)

func _localize_world_labels(scene):
    for child in scene.find_children("*", "Label3D", true, false):
        if child is Label3D:
            child.text = localize_gameplay_text(child.text)

func _sync_journal_entries():
    var journal = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var entries = journal.get("entries")
    if not (entries is Dictionary):
        return
    for entry_id in journal_entries.keys():
        if entries.has(entry_id):
            entries[entry_id] = get_journal_entry_data(str(entry_id))
    if journal.has_method("is_open") and bool(journal.call("is_open")) and journal.has_method("_update_entry_display"):
        journal.call("_update_entry_display")

func _sync_world_notes():
    for node in get_tree().get_nodes_in_group("journal_note"):
        if node == null or not is_instance_valid(node):
            continue
        var entry_id = str(node.get("entry_id"))
        var data = get_journal_entry_data(entry_id)
        if data.is_empty():
            continue
        node.set("entry_title", str(data.get("title", "")))
        node.set("entry_category", str(data.get("category", "")))
        node.set("entry_body", str(data.get("body", "")))

func _localize_inventory(text):
    var result = super._localize_inventory(text)
    for key in extra_en_to_id.keys():
        var id_text = str(extra_en_to_id[key])
        if language_code == "id":
            result = result.replace(str(key), id_text)
        else:
            result = result.replace(id_text, str(key))
    return result

func _localize_controls_text(text):
    var result = super._localize_controls_text(text)
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
