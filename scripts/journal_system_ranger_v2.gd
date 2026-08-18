extends "res://scripts/journal_system_v19.gd"

const RANGER_FOREST: String = "res://scenes/forest.tscn"
const RANGER_MINE: String = "res://scenes/mine.tscn"
const RANGER_LABYRINTH: String = "res://scenes/main.tscn"
const RANGER_FACILITY: String = "res://scenes/research_facility.tscn"

func _ready() -> void:
    super._ready()
    # Replace old Labyrinth-first guide entries with the ranger-first canon.
    _add_entry(
        "world_premise",
        "Kasus Ranger 07 — Tim Survey Hilang",
        "LORE",
        "Kamu adalah ranger yang ditugaskan mencari jawaban setelah tim survey menghilang di forest. Cabin adalah base operasi, bukan ending. Bertahan hidup lebih dulu, stabilkan shelter, lalu ikuti evidence dari lokasi ke lokasi. Jejak kasus mengarah dari Forest ke Old Mine, kemudian ke fasilitas bawah tanah yang disebut Level 03 / Labyrinth."
    )
    _add_entry(
        "humanity_mission",
        "Misi Jangka Panjang",
        "PRIMARY MISSION",
        "FASE 1 — SURVIVE: kuasai cabin, food, water, fuel, light, weather, hunting, dan cold.\n\nFASE 2 — INVESTIGATE FOREST: Abandoned House → Gas Station → Warehouse → optional Water Pump.\n\nFASE 3 — OLD MINE: cari log pekerja, laporan shaft, dan Facility Access Badge.\n\nFASE 4 — LABYRINTH: pulihkan sistem, pahami T-03, dan bawa data keluar.\n\nFASE 5 — RESEARCH NETWORK: ikuti routing table menuju Hospital, Museum, Laboratory, Cave, dan node lain.\n\nTujuan akhir bukan sekadar kabur; ranger harus menyusun bukti yang menjelaskan bagaimana manusia dapat bertahan dari fenomena ini."
    )
    _add_entry(
        "route_overview",
        "Rute Investigasi Utama",
        "MISSION GUIDE",
        "START — Ranger Cabin: jadikan halaman 30×30 m sebagai safe base.\n\nFOREST CASE — Abandoned House → Old Gas Station → Warehouse → Old Mine. Water Pump memberi evidence samping.\n\nOLD MINE — Foreman's Log → Sealed Shaft Report → Facility Access Badge → Gate Level 03.\n\nLABYRINTH — emergency relays → Maintenance → Flooded Service → Archive → Lockdown.\n\nRESTRICTED FACILITY — routing terminal membuka daftar ekspedisi berikutnya. Setiap lokasi adalah scene terpisah agar gameplay, spawn, dan aset tidak bocor antar-map."
    )
    _add_entry(
        "forest_survival_plan",
        "Rencana Operasi Ranger",
        "SURVIVAL PLAN",
        "Cabin menghadap ke pusat forest. Siapkan ekspedisi dari halaman aman, keluar melalui gate forest-side, kumpulkan resource dan evidence, lalu kembali sebelum darkness, weather, cold, dan jarak menghabiskan persediaan. Random resource dan hostile tidak spawn di halaman/cabin; fixed base equipment tetap boleh ada sebagai infrastruktur ranger."
    )
    _update_mission()
    _update_entry_display()

func _configure_scene(scene: Node) -> void:
    if scene == null or not is_instance_valid(scene):
        return
    # Apartment/relay notes are Labyrinth-only. InvestigationSystem owns notes
    # in Forest/Mine/Facility.
    if scene.scene_file_path != RANGER_LABYRINTH:
        return
    await super._configure_scene(scene)

func _get_current_mission() -> String:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path in [RANGER_FOREST, RANGER_MINE, RANGER_FACILITY]:
        var investigation: Node = get_node_or_null("/root/InvestigationSystem")
        if investigation != null and investigation.has_method("get_current_mission_text"):
            var text: String = str(investigation.call("get_current_mission_text"))
            if not text.is_empty():
                return text
    return super._get_current_mission()
