extends Node

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"

var active_player: CharacterBody3D
var tracked_player_id: int = 0
var last_scene_id: int = 0
var current_state_key: String = ""
var previous_dead: bool = false
var state_probe_timer: float = 0.0
var player_probe_timer: float = 0.0
var flavor_timer: float = 18.0
var flavor_index: int = 0

var layer: CanvasLayer
var chapter_panel: PanelContainer
var chapter_title: Label
var chapter_body: Label
var chapter_hint: Label
var flavor_label: Label
var chapter_hold: float = 0.0
var chapter_fade: float = 0.0
var flavor_hold: float = 0.0
var flavor_fade: float = 0.0
var layout_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 20
    _build_ui()
    call_deferred("_bind_player")

func _process(delta: float) -> void:
    _update_fades(delta)

    layout_timer -= delta
    if layout_timer <= 0.0:
        layout_timer = 0.45
        _apply_responsive_layout()

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        _release_player()
        _hide_narrative_ui()
        current_state_key = ""
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != last_scene_id:
        last_scene_id = scene_id
        current_state_key = ""
        flavor_timer = 12.0
        call_deferred("_bind_player")

    player_probe_timer -= delta
    if player_probe_timer <= 0.0:
        player_probe_timer = 0.35
        _bind_player()

    if not is_instance_valid(active_player):
        return

    var is_dead: bool = bool(active_player.get("is_dead"))
    if is_dead and not previous_dead:
        call_deferred("_enrich_death_screen")
    previous_dead = is_dead
    if is_dead:
        return

    state_probe_timer -= delta
    if state_probe_timer <= 0.0:
        state_probe_timer = 0.35
        var next_state: String = _resolve_state_key(scene)
        if not next_state.is_empty() and next_state != current_state_key:
            current_state_key = next_state
            _enter_narrative_state(next_state)

    flavor_timer -= delta
    if flavor_timer <= 0.0 and not _ui_blocked():
        flavor_timer = 38.0
        _show_next_flavor_line()

func _bind_player() -> void:
    var found: CharacterBody3D = _find_local_player()
    if found == null:
        _release_player()
        return

    var found_id: int = int(found.get_instance_id())
    if found == active_player and found_id == tracked_player_id:
        return

    active_player = found
    tracked_player_id = found_id
    previous_dead = bool(active_player.get("is_dead"))
    state_probe_timer = 0.0

func _release_player() -> void:
    active_player = null
    tracked_player_id = 0
    previous_dead = false

func _find_local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback

func _resolve_state_key(scene: Node) -> String:
    if active_player == null:
        return ""

    if scene.scene_file_path == LABYRINTH_SCENE_PATH:
        var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
        if arc != null:
            var holdout_active: bool = bool(arc.get("holdout_active"))
            var stage: int = int(arc.get("current_stage"))
            if holdout_active or stage == 5:
                return "lab_lockdown_holdout"
            if stage == 1:
                return "lab_maintenance"
            if stage == 2:
                return "lab_flooded"
            if stage == 3:
                return "lab_archive"
            if stage == 4:
                return "lab_lockdown_prep"
            if stage >= 6:
                return "lab_exit"

        var relay_count: int = _relay_count()
        if relay_count >= 3:
            return "lab_gate"
        if active_player.global_position.z < -15.0:
            return "lab_lower"
        return "lab_opening"

    if scene.scene_file_path == FOREST_SCENE_PATH:
        var outside: Node = get_node_or_null("/root/OutsideDirector")
        var night: bool = outside != null and outside.has_method("is_night") and bool(outside.call("is_night"))
        var powered: bool = outside != null and bool(outside.get("shelter_powered"))
        var shelter: Node = get_node_or_null("/root/ShelterSystem")
        if shelter != null:
            powered = powered or bool(shelter.get("generator_running"))

        if active_player.global_position.z > -72.0:
            return "outside_arrival"
        if night:
            return "outside_night"
        if active_player.global_position.z < -132.0:
            return "outside_ruins"
        if not powered:
            return "outside_shelter"
        return "outside_day"

    return ""

func _relay_count() -> int:
    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth == null:
        return 0
    var relays: Dictionary = Dictionary(labyrinth.get("active_relays"))
    var count: int = 0
    for value: Variant in relays.values():
        if bool(value):
            count += 1
    return count

func _enter_narrative_state(state_key: String) -> void:
    var data: Dictionary = _chapter_data(state_key)
    if data.is_empty():
        return

    _show_chapter(
        str(data.get("title", "")),
        str(data.get("body", "")),
        str(data.get("hint", ""))
    )
    flavor_index = 0
    flavor_timer = 24.0
    _discover_lore_entry(data)

func _discover_lore_entry(data: Dictionary) -> void:
    var entry_id: String = str(data.get("entry_id", ""))
    if entry_id.is_empty():
        return
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null or not journal.has_method("discover_entry"):
        return
    if journal.has_method("has_entry") and bool(journal.call("has_entry", entry_id)):
        return
    journal.call(
        "discover_entry",
        entry_id,
        str(data.get("entry_title", data.get("title", "Unknown"))),
        str(data.get("category", "LORE")),
        str(data.get("lore", data.get("body", ""))),
        false
    )

func _chapter_data(state_key: String) -> Dictionary:
    match state_key:
        "lab_opening":
            return {
                "title": "BAB I — APARTMENT 03",
                "body": "Kamu terbangun di lorong yang seharusnya tidak sepanjang ini. Apartemen 03 masih memiliki bekas penghuni terakhir, dan pintu di ujung koridor terkunci dari sisi yang salah.",
                "hint": "Cari Apartment 03 → ambil perlengkapan → temukan akses menuju koridor bawah. Jangan biarkan cahaya habis.",
                "entry_id": "lore_apartment03",
                "entry_title": "Apartment 03 — Penghuni Terakhir",
                "category": "LORE",
                "lore": "Catatan gedung menyebut Apartment 03 kosong sejak tiga tahun lalu. Anehnya, tagihan listrik unit itu tidak pernah berhenti. Petugas terakhir yang masuk menulis satu kalimat pada laporan: 'Lorongnya bertambah panjang ketika saya pulang.' Tidak ada denah yang menunjukkan ruang di balik dinding utara, tetapi suara langkah selalu datang dari sana."
            }
        "lab_lower":
            return {
                "title": "BAB II — LOWER LABYRINTH",
                "body": "Di bawah gedung ada jaringan pemeliharaan yang tidak tercatat. Tiga emergency relay memberi daya pada gerbang lebih dalam; setiap relay yang hidup juga membuat sesuatu di lorong sadar bahwa kamu masih di sini.",
                "hint": "Aktifkan 3 emergency relay. Cari baterai dan suplai di cabang samping sebelum masuk lebih jauh.",
                "entry_id": "lore_lower_labyrinth",
                "entry_title": "Denah yang Tidak Pernah Disetujui",
                "category": "FACILITY",
                "lore": "Blueprint resmi berhenti di basement. Blueprint teknisi melanjutkan enam tingkat lebih bawah, semuanya diberi cap VOID. Relay darurat dibuat bukan untuk menjaga manusia tetap hidup, melainkan agar lampu tetap menyala ketika sesuatu memutus jaringan utama dari dalam."
            }
        "lab_gate":
            return {
                "title": "GERBANG DARURAT TERBUKA",
                "body": "Ketiga relay menyala. Untuk pertama kalinya suara mesin tua terdengar lebih keras daripada langkah di belakangmu. Jalur menuju fasilitas inti sekarang terbuka.",
                "hint": "Ikuti beacon menuju Maintenance Wing. Isi baterai, air, makanan, dan medical supply sebelum melewati gerbang.",
                "entry_id": "lore_emergency_gate",
                "entry_title": "Protokol Gerbang Darurat",
                "category": "PROTOCOL",
                "lore": "Gerbang hanya dirancang terbuka ketika tiga relay terpisah setuju bahwa jalur evakuasi aman. Pada malam insiden, ketiganya dipaksa mati secara manual. Log terakhir mencatat satu perintah tanpa nama operator: KEEP THEM BELOW."
            }
        "lab_maintenance":
            return {
                "title": "ARC 1 — MAINTENANCE WING",
                "body": "Sirkuit bawah mati total. Tiga fuse box harus dipulihkan agar pintu servis berikutnya mendapatkan daya. Mourner berkeliaran di jalur ini dan bereaksi pada suara lebih baik daripada cahaya.",
                "hint": "Pulihkan Fuse A, B, C. Bergerak seperlunya—sprint, benturan, dan interaksi keras membuatmu lebih mudah ditemukan.",
                "entry_id": "lore_maintenance_shift",
                "entry_title": "Shift Terakhir Maintenance",
                "category": "LOG",
                "lore": "22:41 — Fuse C meledak lagi. 22:47 — suara menangis dari ventilation shaft. 22:51 — supervisor memerintahkan semua staf tidak menjawab suara yang menyebut nama mereka. 22:54 — tiga badge karyawan membuka pintu keluar secara bersamaan. Kamera menunjukkan lorong kosong."
            }
        "lab_flooded":
            return {
                "title": "ARC 1 — FLOODED SERVICE",
                "body": "Pipa lama menenggelamkan bagian servis. Dua pressure valve harus ditutup sebelum sistem listrik bisa dialihkan ke Archive. Air memperlambat keputusanmu, bukan ancaman di dalamnya.",
                "hint": "Temukan Valve A dan B. Periksa side route untuk suplai; jangan bertahan terlalu lama di area gelap hanya karena jalurnya lebih pendek.",
                "entry_id": "lore_flooded_service",
                "entry_title": "Air dari Bawah",
                "category": "INCIDENT",
                "lore": "Tim kualitas air menemukan sampel dengan suhu empat derajat lebih rendah daripada pipa sekitarnya. Sampel itu mematikan semua sensor cahaya di laboratorium selama sebelas detik. Setelah itu seorang teknisi bersikeras melihat seseorang berdiri di refleksi air, padahal ruangan kosong."
            }
        "lab_archive":
            return {
                "title": "ARC 1 — ARCHIVE",
                "body": "Archive menyimpan catatan eksperimen dan urutan breaker manual. Sistem hanya menerima urutan B → A → C. Kesalahan memicu blackout alarm dan memberi semua penghuni fasilitas alasan untuk mendekat.",
                "hint": "Breaker B → A → C. Salah urutan = blackout + aggression meningkat. Hafalkan sebelum menyentuh panel pertama.",
                "entry_id": "lore_archive_subject",
                "entry_title": "File SUBJEK T-03",
                "category": "RESTRICTED",
                "lore": "T-03 tidak tercatat sebagai manusia atau organisme. Peneliti menyebutnya 'occupancy phenomenon': ruang gelap yang cukup lama kosong mulai berperilaku seolah memiliki penghuni. Ketika diamati, fenomena kehilangan kemampuan berpindah. Ketika tidak diamati, jarak tidak lagi menjadi batas. Nama lapangannya kemudian menjadi The Tenant."
            }
        "lab_lockdown_prep":
            return {
                "title": "ARC 1 — LOCKDOWN",
                "body": "Console terakhir dapat menstabilkan fasilitas, tetapi prosesnya mengunci pintu selama dua menit. Setelah dimulai, tidak ada jalan aman untuk membatalkannya.",
                "hint": "SEBELUM MULAI: heal → minum → makan → cek baterai → siapkan jalur antar pocket cahaya. Aktifkan console hanya saat siap.",
                "entry_id": "lore_lockdown_order",
                "entry_title": "Perintah Lockdown 03:13",
                "category": "ORDER",
                "lore": "03:13 — seluruh staf diminta bertahan di bawah lampu emergency selama 120 detik sementara sistem mengisolasi sektor. Rekaman berhenti pada detik ke-87. Satu kamera kembali hidup tiga hari kemudian dan menunjukkan semua lampu masih menyala, tetapi tidak ada seorang pun di bawahnya."
            }
        "lab_lockdown_holdout":
            return {
                "title": "LOCKDOWN AKTIF",
                "body": "Pintu terkunci. Alarm menarik Mourner dan Crawler dari jalur samping. Tujuannya bukan membunuh semuanya—tujuannya bertahan sampai sistem selesai.",
                "hint": "Bergerak antar pocket cahaya, jangan terjebak di sudut, simpan stamina untuk reposisi dan baterai untuk jalur gelap.",
                "entry_id": "lore_lockdown_survival",
                "entry_title": "Mengapa Dua Menit Terasa Lama",
                "category": "SURVIVOR NOTE",
                "lore": "Tulisan pada sisi console: 'Kalau alarm mulai, jangan jadi pahlawan. Cahaya adalah posisi bertahan, bukan tempat tinggal. Bergerak sebelum mereka menutup jalur, lalu berhenti cukup lama untuk mendengar dari arah mana mereka datang.'"
            }
        "lab_exit":
            return {
                "title": "JALUR KELUAR",
                "body": "Fasilitas berhenti melawanmu. Pintu menuju permukaan terbuka, tetapi udara dari luar membawa bau tanah basah dan asap generator—bukti bahwa dunia di atas juga belum selesai.",
                "hint": "Ikuti final beacon dan keluar. Inventory, kondisi tubuh, luka, dan suplai akan dibawa ke The Outside.",
                "entry_id": "lore_exit_warning",
                "entry_title": "Peringatan di Pintu Keluar",
                "category": "WARNING",
                "lore": "Seseorang menggores kalimat ini dari sisi luar pintu: 'Jika kamu berhasil keluar, jangan mengira gelap hanya tinggal di bawah tanah. Di luar, gelap punya lebih banyak tempat untuk bersembunyi.'"
            }
        "outside_arrival":
            return {
                "title": "BAB III — THE OUTSIDE",
                "body": "Kamu keluar menjelang senja. Jalan lama mengarah ke sebuah cabin, tetapi jaringan listrik daerah sudah mati. Siang memberi ruang untuk bernapas; malam mengambilnya kembali.",
                "hint": "Temukan cabin → periksa generator → cari Fuel Can sebelum malam. Jangan habiskan semua baterai selama masih ada daylight.",
                "entry_id": "lore_outside_broadcast",
                "entry_title": "Siaran Evakuasi Terakhir",
                "category": "RADIO",
                "lore": "'Untuk warga sektor utara: jangan gunakan jalan utama setelah matahari terbenam. Bergerak hanya dari satu sumber cahaya ke sumber cahaya berikutnya. Jika melihat seseorang berdiri di luar jangkauan lampu, jangan panggil namanya. Kami ulangi: jangan panggil namanya.' Siaran berhenti tanpa penutup."
            }
        "outside_shelter":
            return {
                "title": "CABIN TANPA DAYA",
                "body": "Cabin bisa menjadi checkpoint dan safe shelter, tetapi generatornya kering. Jejak pemilik lama menunjukkan ia mengandalkan fuel can dari bangunan sekitar.",
                "hint": "Cari Fuel Can → kembali ke generator → nyalakan shelter. Sambil mencari, kumpulkan food, water, medicine, cloth, dan battery.",
                "entry_id": "lore_cabin_owner",
                "entry_title": "Catatan Pemilik Cabin",
                "category": "PERSONAL",
                "lore": "Hari 8. Lampu teras masih bekerja kalau generator mau menyala. Mereka tidak menyeberangi lingkar cahaya, setidaknya belum. Aku mulai menyalakan radio hanya untuk mendengar suara manusia, walaupun semua frekuensi cuma memutar ulang peringatan yang sama."
            }
        "outside_day":
            return {
                "title": "DAYLIGHT WINDOW",
                "body": "Shelter hidup. Sekarang siang adalah waktu untuk mengambil risiko: cari suplai, rawat luka, siapkan air bersih, dan petakan jalur pulang sebelum cahaya turun.",
                "hint": "Loot region → prioritaskan Fuel, Battery, Food, Water, Cloth, Medkit → kembali ke shelter sebelum malam bila kondisi buruk.",
                "entry_id": "lore_daylight_rule",
                "entry_title": "Aturan Daylight",
                "category": "SURVIVAL",
                "lore": "Penyintas lokal membagi hari bukan menjadi pagi dan malam, melainkan WINDOW dan CLOSED. WINDOW adalah saat bayangan masih punya arah. CLOSED dimulai ketika bayangan tidak lagi menunjuk menjauh dari matahari. Setelah itu, setiap area tanpa lampu dianggap milik mereka."
            }
        "outside_ruins":
            return {
                "title": "ABANDONED REGION",
                "body": "Gas station, warehouse, rumah kosong, dan hand pump membentuk sisa komunitas yang pernah mencoba bertahan. Barang berguna masih ada, tetapi setiap bangunan punya blind spot dan jalur pulang yang berbeda.",
                "hint": "Cari suplai bernilai tinggi. Dirty Water harus direbus. Warehouse berbahaya saat gelap; jangan masuk tanpa rencana keluar dan baterai cukup.",
                "entry_id": "lore_region_fall",
                "entry_title": "Bagaimana Daerah Ini Jatuh",
                "category": "LORE",
                "lore": "Daerah ini tidak dievakuasi sekaligus. Orang-orang bertahan berminggu-minggu dengan generator, lampu kendaraan, dan api unggun. Yang menghancurkan mereka bukan kekurangan makanan terlebih dahulu, melainkan kebiasaan: satu lampu mati, seseorang berjalan sendiri untuk memperbaikinya, lalu jumlah orang yang kembali selalu satu lebih sedikit atau satu lebih banyak."
            }
        "outside_night":
            return {
                "title": "NIGHT CYCLE",
                "body": "Malam membuat jarak antar cahaya terasa lebih jauh. Suhu turun, Darkness menjadi agresif, dan jalur yang aman siang hari berubah menjadi perangkap terbuka.",
                "hint": "Utamakan shelter dan cahaya. Kalau harus keluar: baterai penuh, stamina cukup, jalur pulang jelas, dan jangan mengejar suara di luar lampu.",
                "entry_id": "lore_night_rule",
                "entry_title": "Aturan Malam: Hitung Orangnya",
                "category": "WARNING",
                "lore": "Tulisan di warehouse: 'Sebelum menjawab seseorang yang memanggil dari lorong gelap, hitung semua orang di bawah lampu. Kalau jumlahnya sudah benar, jangan jawab suara itu. Kalau jumlahnya lebih banyak dari seharusnya, matikan radio dan jangan menoleh.'"
            }
    return {}

func _show_chapter(title: String, body: String, hint: String) -> void:
    if chapter_panel == null:
        return
    chapter_title.text = title
    chapter_body.text = body
    chapter_hint.text = hint
    chapter_panel.visible = true
    chapter_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
    chapter_hold = 6.5
    chapter_fade = 1.2

func _show_next_flavor_line() -> void:
    var lines: Array[String] = _flavor_lines(current_state_key)
    if lines.is_empty() or flavor_label == null:
        return
    flavor_index = wrapi(flavor_index, 0, lines.size())
    flavor_label.text = lines[flavor_index]
    flavor_index += 1
    flavor_label.visible = true
    flavor_label.modulate = Color(1.0, 1.0, 1.0, 0.86)
    flavor_hold = 4.8
    flavor_fade = 1.2

func _flavor_lines(state_key: String) -> Array[String]:
    match state_key:
        "lab_opening":
            return [
                "Dari balik dinding terdengar pipa bergetar—atau seseorang mengetuk dengan pola yang terlalu teratur.",
                "Lampu koridor berdengung. Ketika dengungnya berhenti, langkah lain ikut berhenti.",
                "Nomor Apartment 03 tampak pernah dicopot, lalu dipasang kembali dari sisi dalam pintu."
            ]
        "lab_lower", "lab_gate":
            return [
                "Udara di bawah sini lebih dingin, tetapi tidak ada ventilasi yang masih bekerja.",
                "Salah satu speaker emergency berbisik sebentar sebelum kembali menjadi static.",
                "Debu di lantai menyimpan jejak sepatu yang berhenti tepat di depan dinding."
            ]
        "lab_maintenance":
            return [
                "Ada suara menangis jauh di depan. Tidak pernah terdengar lebih dekat, tetapi juga tidak pernah benar-benar menjauh.",
                "Fuse box yang mati masih terasa hangat saat dilewati.",
                "Sesuatu menggesek ventilation shaft mengikuti langkahmu, lalu berhenti ketika kamu berhenti."
            ]
        "lab_flooded":
            return [
                "Permukaan air bergerak beberapa detik setelah kakimu berhenti.",
                "Pantulan lampu di air kadang menunjukkan satu bayangan lebih banyak.",
                "Dari pipa terbuka terdengar napas pendek yang tidak mengikuti ritmemu."
            ]
        "lab_archive":
            return [
                "Beberapa folder sudah kosong. Labelnya masih ada: T-01, T-02, T-03.",
                "Printer mati mengeluarkan satu lembar kosong, lalu berhenti lagi.",
                "Jam dinding Archive selalu menunjukkan 03:13, bahkan setelah dayanya kembali."
            ]
        "lab_lockdown_prep", "lab_lockdown_holdout":
            return [
                "Alarm membuat dinding bergetar. Sesuatu di lorong menjawabnya.",
                "Lampu emergency berkedip tidak serempak—seolah ada sesuatu bergerak di antara sumber dayanya.",
                "Dua menit tidak lama sampai semua pintu di belakangmu terkunci."
            ]
        "outside_arrival", "outside_shelter", "outside_day":
            return [
                "Angin membawa bau pinus, tanah basah, dan bensin lama dari arah jalan.",
                "Sebuah radio jauh menyala sesaat. Tidak ada kata yang jelas, hanya nada peringatan berulang.",
                "Burung masih ada di sini. Mereka hanya tidak pernah terbang melewati area yang terlalu gelap."
            ]
        "outside_ruins":
            return [
                "Pintu gas station berdering saat angin mendorongnya, meski engselnya sudah macet.",
                "Di warehouse, satu lampu emergency masih berkedip tanpa kabel yang terhubung.",
                "Ada bekas api unggun di pinggir jalan. Abu di tengahnya belum sepenuhnya dingin."
            ]
        "outside_night":
            return [
                "Dari luar jangkauan lampu, sesuatu meniru suara generator—terlambat setengah detik.",
                "Pohon-pohon tidak bergerak, tetapi bayangannya tetap bergeser.",
                "Seseorang memanggil dari arah jalan. Suaranya terdengar seperti milik orang yang kamu kenal, tapi kamu tidak ingat siapa."
            ]
    return []

func _enrich_death_screen() -> void:
    if not is_instance_valid(active_player):
        return
    await get_tree().process_frame
    if not is_instance_valid(active_player) or not bool(active_player.get("is_dead")):
        return

    var panel: Control = active_player.get_node_or_null("HUD/CaughtPanel") as Control
    var title: Label = active_player.get_node_or_null("HUD/CaughtPanel/Title") as Label
    var rule: Label = active_player.get_node_or_null("HUD/CaughtPanel/Rule") as Label
    var restart: Label = active_player.get_node_or_null("HUD/CaughtPanel/Restart") as Label
    if panel == null or title == null or rule == null or restart == null:
        return

    var cause: String = _extract_death_cause(rule.text)
    var story: Dictionary = _death_story(cause)
    var condition: String = _death_condition_line()
    var place: String = _death_place_line()

    title.text = str(story.get("title", "CATATAN TERAKHIR"))
    rule.text = "%s\n\nPENYEBAB AKHIR: %s\n%s\n%s\n\nCATATAN: %s\nCOBA BERIKUTNYA: %s" % [
        str(story.get("opening", "Kamu bertahan sejauh yang kamu bisa.")),
        cause,
        place,
        condition,
        str(story.get("note", "Tidak semua kematian datang dari satu kesalahan.")),
        str(story.get("lesson", "Masuk lagi dengan persiapan yang lebih baik."))
    ]
    restart.text = "Tap RESTART untuk mencoba lagi dari checkpoint." if _mobile_active() else "Tekan R untuk mencoba lagi dari checkpoint terakhir."

    rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    rule.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    _layout_death_panel(title, rule, restart)

func _extract_death_cause(text: String) -> String:
    var clean: String = text.strip_edges()
    if clean.begins_with("Cause:"):
        clean = clean.trim_prefix("Cause:").strip_edges()
    if clean.is_empty():
        clean = "unknown"
    return clean

func _death_story(cause: String) -> Dictionary:
    var c: String = cause.to_lower()
    if c.contains("tenant"):
        return {
            "title": "THE TENANT MENANG KALI INI",
            "opening": "Kamu sempat mendengar langkahnya berhenti ketika menoleh. Saat pandanganmu lepas sekali lagi, jarak yang tersisa sudah terlalu pendek.",
            "note": "The Tenant bukan pengejar biasa. Ia memanfaatkan momen ketika perhatianmu pecah dan panic membuat keputusanmu lebih buruk.",
            "lesson": "Jaga ia dalam pandangan saat dekat, gunakan cahaya untuk memaksa ruang aman, dan jangan sprint tanpa rencana karena gerak menaikkan panic."
        }
    if c.contains("darkness"):
        return {
            "title": "CAHAYA PADAM TERLEBIH DAHULU",
            "opening": "Gelap tidak menyerang sekaligus. Ia mengambil jarak pandangmu, lalu arah, lalu keyakinan bahwa jalur di depan masih sama seperti beberapa detik lalu.",
            "note": "Darkness menjadi ancaman nyata ketika kamu terlalu lama berada di luar protective light.",
            "lesson": "Sisakan baterai untuk transisi antar sumber cahaya. Kalau flashlight lemah, cari pocket cahaya sebelum exposure mencapai titik kritis."
        }
    if c.contains("mourner"):
        return {
            "title": "SUARA ITU AKHIRNYA MENEMUKANMU",
            "opening": "Tangisannya terdengar jauh sampai detik terakhir. Mourner tidak perlu melihatmu lebih dulu—suara langkah dan interaksi cukup untuk menunjukkan arah.",
            "note": "Mourner merespons noise dan menjadi lebih agresif ketika fasilitas memasuki tahap berbahaya.",
            "lesson": "Kurangi sprint, hindari membuat noise beruntun, dan gunakan jalur terang untuk memperlambat pendekatannya."
        }
    if c.contains("crawler"):
        return {
            "title": "JALUR RENDAH TIDAK KOSONG",
            "opening": "Kamu melihat gerak terlalu rendah di lantai ketika sudah terlambat. Crawler memilih jalur cepat dan memanfaatkan ruang sempit untuk memotong jalan keluar.",
            "note": "Crawler berbahaya ketika stamina habis dan kamu tidak punya ruang reposisi.",
            "lesson": "Jangan masuk koridor sempit dengan stamina kosong. Gunakan cahaya dan ruang terbuka untuk memaksa jarak."
        }
    if c.contains("warden"):
        return {
            "title": "WARDEN MENUTUP JALURMU",
            "opening": "Ia tidak sekadar mengejar. Ia membuatmu memilih jalur yang salah sampai ruang aman terakhir berada di belakangnya.",
            "note": "Warden menghukum pemain yang bertahan terlalu lama di satu pola pergerakan.",
            "lesson": "Pindah lebih awal, simpan stamina untuk perubahan arah, dan jangan bergantung pada satu sumber cahaya saja."
        }
    if c.contains("bleeding"):
        return {
            "title": "LUKANYA TIDAK PERNAH BENAR-BENAR BERHENTI",
            "opening": "Serangan yang melukaimu sudah lama berlalu. Yang membunuhmu adalah menit-menit setelahnya, ketika darah terus hilang sedikit demi sedikit.",
            "note": "Bleeding adalah ancaman tertunda. HP yang masih tinggi bukan berarti lukanya aman.",
            "lesson": "Gunakan Bandage lebih awal atau Medkit sebelum bleeding berubah menjadi infection dan damage berkala."
        }
    if c.contains("infection"):
        return {
            "title": "INFEKSI MENANG PELAN-PELAN",
            "opening": "Tidak ada satu serangan terakhir. Tubuhmu hanya semakin lambat, semakin dingin, lalu tidak mampu mengimbangi kerusakan yang sudah menumpuk.",
            "note": "Infection tumbuh dari luka yang tidak dirawat dan air yang tidak aman.",
            "lesson": "Rawat bleeding, gunakan Medkit untuk menekan infection, dan rebus Dirty Water sebelum diminum bila memungkinkan."
        }
    if c.contains("dehydration"):
        return {
            "title": "KAMU KEHABISAN AIR SEBELUM JALAN",
            "opening": "Mulut kering berubah menjadi pusing, pusing menjadi langkah pendek, lalu tubuh berhenti memedulikan seberapa dekat tujuanmu.",
            "note": "Dehydration merusakmu terus-menerus ketika thirst mencapai nol.",
            "lesson": "Bawa air sebelum eksplorasi jauh. Dirty Water bisa menyelamatkan thirst, tetapi berisiko infection jika tidak direbus."
        }
    if c.contains("starvation"):
        return {
            "title": "TUBUHMU KEHABISAN CADANGAN",
            "opening": "Ancaman di luar masih ada, tetapi tubuhmu lebih dulu menyerah. Setiap sprint terakhir meminjam tenaga yang tidak lagi kamu miliki.",
            "note": "Hunger rendah memperburuk pemulihan stamina dan akhirnya mulai mengikis health.",
            "lesson": "Makan sebelum kondisi kritis. Simpan satu food item sebagai cadangan sebelum memulai area panjang atau holdout."
        }
    if c.contains("exposure") or c.contains("cold"):
        return {
            "title": "MALAM MENGAMBIL PANAS TERAKHIR",
            "opening": "Dingin terasa seperti masalah kecil sampai jari sulit bergerak dan cahaya di depan tidak lagi terasa cukup dekat.",
            "note": "Cold exposure menjadi lebih berbahaya jauh dari shelter, terutama ketika malam turun.",
            "lesson": "Gunakan daylight untuk eksplorasi jauh dan pulang lebih awal. Shelter bertenaga adalah perlindungan, bukan sekadar checkpoint."
        }
    return {
        "title": "KAMU TIDAK KEMBALI",
        "opening": "Untuk beberapa detik terakhir, semuanya masih terasa bisa diselamatkan. Lalu satu keputusan kecil bertemu dengan kondisi yang sudah terlalu buruk.",
        "note": "Kematian biasanya adalah hasil beberapa masalah yang menumpuk: panic, stamina, luka, darkness, dan suplai.",
        "lesson": "Baca kondisi sebelum maju. Mundur untuk pulih sering lebih murah daripada memaksa satu ruangan lagi."
    }

func _death_condition_line() -> String:
    if active_player == null:
        return "KONDISI: data tidak tersedia"
    var panic: int = int(round(float(active_player.get("flashlight_panic"))))
    var battery: int = int(round(float(active_player.get("flashlight_battery"))))
    var hunger: int = int(round(float(active_player.get("hunger"))))
    var thirst: int = int(round(float(active_player.get("thirst"))))
    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    var bleeding: int = int(round(float(depth.get("bleeding")))) if depth != null else 0
    var infection: int = int(round(float(depth.get("infection")))) if depth != null else 0
    return "KONDISI: Panic %d%% • Battery %d%% • Hunger %d%% • Thirst %d%% • Bleeding %d%% • Infection %d%%" % [panic, battery, hunger, thirst, bleeding, infection]

func _death_place_line() -> String:
    var chapter: Dictionary = _chapter_data(current_state_key)
    var place: String = str(chapter.get("title", "AREA TIDAK DIKENAL"))
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null and outside.has_method("get_time_minutes") and get_tree().current_scene != null and get_tree().current_scene.scene_file_path == FOREST_SCENE_PATH:
        var minutes_total: int = int(outside.call("get_time_minutes"))
        var hour: int = (minutes_total / 60) % 24
        var minute: int = minutes_total % 60
        var day: int = int(outside.get("day_index"))
        return "LOKASI: %s • Hari %d • %02d:%02d" % [place, day, hour, minute]
    return "LOKASI: %s" % place

func _layout_death_panel(title: Label, rule: Label, restart: Label) -> void:
    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = size.x < 800.0 or _mobile_active()
    if compact:
        title.offset_left = -160.0
        title.offset_top = -260.0
        title.offset_right = 160.0
        title.offset_bottom = -205.0
        title.add_theme_font_size_override("font_size", 28)
        rule.offset_left = -160.0
        rule.offset_top = -190.0
        rule.offset_right = 160.0
        rule.offset_bottom = 155.0
        rule.add_theme_font_size_override("font_size", 14)
        restart.offset_left = -160.0
        restart.offset_top = 178.0
        restart.offset_right = 160.0
        restart.offset_bottom = 226.0
        restart.add_theme_font_size_override("font_size", 14)
    else:
        title.offset_left = -430.0
        title.offset_top = -245.0
        title.offset_right = 430.0
        title.offset_bottom = -175.0
        title.add_theme_font_size_override("font_size", 40)
        rule.offset_left = -430.0
        rule.offset_top = -155.0
        rule.offset_right = 430.0
        rule.offset_bottom = 150.0
        rule.add_theme_font_size_override("font_size", 18)
        restart.offset_left = -360.0
        restart.offset_top = 178.0
        restart.offset_right = 360.0
        restart.offset_bottom = 230.0
        restart.add_theme_font_size_override("font_size", 17)

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "NarrativeLoreUI"
    layer.layer = 38
    add_child(layer)

    chapter_panel = PanelContainer.new()
    chapter_panel.name = "ChapterCard"
    chapter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    chapter_panel.anchor_left = 0.5
    chapter_panel.anchor_top = 0.0
    chapter_panel.anchor_right = 0.5
    chapter_panel.anchor_bottom = 0.0
    chapter_panel.add_theme_stylebox_override("panel", _panel_style())
    chapter_panel.visible = false
    layer.add_child(chapter_panel)

    var box: VBoxContainer = VBoxContainer.new()
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_theme_constant_override("separation", 5)
    chapter_panel.add_child(box)

    chapter_title = Label.new()
    chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    chapter_title.add_theme_font_size_override("font_size", 20)
    chapter_title.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1.0))
    box.add_child(chapter_title)

    chapter_body = Label.new()
    chapter_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    chapter_body.add_theme_font_size_override("font_size", 14)
    chapter_body.add_theme_color_override("font_color", Color(0.88, 0.89, 0.91, 1.0))
    box.add_child(chapter_body)

    chapter_hint = Label.new()
    chapter_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    chapter_hint.add_theme_font_size_override("font_size", 13)
    chapter_hint.add_theme_color_override("font_color", Color(0.62, 0.74, 0.78, 1.0))
    box.add_child(chapter_hint)

    flavor_label = Label.new()
    flavor_label.name = "AtmosphereLine"
    flavor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flavor_label.anchor_left = 0.5
    flavor_label.anchor_top = 1.0
    flavor_label.anchor_right = 0.5
    flavor_label.anchor_bottom = 1.0
    flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    flavor_label.add_theme_font_size_override("font_size", 14)
    flavor_label.add_theme_color_override("font_color", Color(0.72, 0.74, 0.78, 1.0))
    flavor_label.visible = false
    layer.add_child(flavor_label)

    _apply_responsive_layout()

func _panel_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.008, 0.010, 0.014, 0.86)
    style.border_color = Color(0.68, 0.60, 0.45, 0.28)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    style.content_margin_left = 14.0
    style.content_margin_right = 14.0
    style.content_margin_top = 10.0
    style.content_margin_bottom = 10.0
    return style

func _apply_responsive_layout() -> void:
    if chapter_panel == null or flavor_label == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = size.x < 800.0 or _mobile_active()
    if compact:
        chapter_panel.offset_left = -165.0
        chapter_panel.offset_top = 78.0
        chapter_panel.offset_right = 165.0
        chapter_panel.offset_bottom = 245.0
        chapter_title.add_theme_font_size_override("font_size", 17)
        chapter_body.add_theme_font_size_override("font_size", 12)
        chapter_hint.add_theme_font_size_override("font_size", 11)
        flavor_label.offset_left = -155.0
        flavor_label.offset_top = -166.0
        flavor_label.offset_right = 155.0
        flavor_label.offset_bottom = -118.0
        flavor_label.add_theme_font_size_override("font_size", 12)
    else:
        chapter_panel.offset_left = -330.0
        chapter_panel.offset_top = 82.0
        chapter_panel.offset_right = 330.0
        chapter_panel.offset_bottom = 238.0
        chapter_title.add_theme_font_size_override("font_size", 20)
        chapter_body.add_theme_font_size_override("font_size", 14)
        chapter_hint.add_theme_font_size_override("font_size", 13)
        flavor_label.offset_left = -360.0
        flavor_label.offset_top = -92.0
        flavor_label.offset_right = 360.0
        flavor_label.offset_bottom = -48.0
        flavor_label.add_theme_font_size_override("font_size", 14)

func _update_fades(delta: float) -> void:
    if chapter_panel != null and chapter_panel.visible:
        if chapter_hold > 0.0:
            chapter_hold = maxf(0.0, chapter_hold - delta)
        elif chapter_fade > 0.0:
            chapter_fade = maxf(0.0, chapter_fade - delta)
            chapter_panel.modulate.a = chapter_fade / 1.2
        else:
            chapter_panel.visible = false

    if flavor_label != null and flavor_label.visible:
        if flavor_hold > 0.0:
            flavor_hold = maxf(0.0, flavor_hold - delta)
        elif flavor_fade > 0.0:
            flavor_fade = maxf(0.0, flavor_fade - delta)
            flavor_label.modulate.a = 0.86 * (flavor_fade / 1.2)
        else:
            flavor_label.visible = false

func _hide_narrative_ui() -> void:
    if chapter_panel != null:
        chapter_panel.visible = false
    if flavor_label != null:
        flavor_label.visible = false

func _ui_blocked() -> bool:
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return true
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return true
    var inventory: Node = get_node_or_null("/root/SurvivalSystem/InventoryMenuRuntime")
    if inventory != null and inventory.has_method("is_open") and bool(inventory.call("is_open")):
        return true
    return false

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
