extends "res://scripts/journal_system_ranger_v3.gd"

func _is_id() -> bool:
    var language: Node = get_node_or_null("/root/LanguageSystem")
    return language == null or not language.has_method("is_indonesian") or bool(language.call("is_indonesian"))

func _pick(id_text: String, en_text: String) -> String:
    return id_text if _is_id() else en_text

func _get_current_mission() -> String:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == RANGER_LABYRINTH:
        var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
        if arc != null:
            var stage: int = int(arc.get("current_stage"))
            var completed: Dictionary = Dictionary(arc.get("completed"))
            var holdout_active: bool = bool(arc.get("holdout_active"))
            var holdout_remaining: float = float(arc.get("holdout_remaining"))
            if stage == 1:
                var fuse_count: int = _count_arc_ids(completed, ["fuse_a", "fuse_b", "fuse_c"])
                return _pick(
                    "KASUS RANGER 07 — LABYRINTH / MAINTENANCE\nTUJUAN: Pulihkan tiga fuse box (%d/3) dan cari hubungan T-03 dengan tim survey.\nKONTEKS: Kamu masuk ke fasilitas ini melalui Tambang Tua; jalur kembali bukan tujuan utama. Bukti harus dibawa maju." % fuse_count,
                    "RANGER CASE 07 — LABYRINTH / MAINTENANCE\nOBJECTIVE: Restore three fuse boxes (%d/3) and find T-03's connection to the survey team.\nCONTEXT: You entered this facility through the Old Mine; returning is not the primary objective. The evidence must move forward." % fuse_count
                )
            if stage == 2:
                var valve_count: int = _count_arc_ids(completed, ["valve_a", "valve_b"])
                return _pick(
                    "KASUS RANGER 07 — LAYANAN TERGENANG\nTUJUAN: Tutup pressure valve (%d/2), pertahankan baterai, dan cari data rute fasilitas.\nKONTEKS: Tambang membuktikan fasilitas ini terhubung ke insiden permukaan." % valve_count,
                    "RANGER CASE 07 — FLOODED SERVICE\nOBJECTIVE: Close the pressure valves (%d/2), preserve battery power, and find facility route data.\nCONTEXT: The mine proves this facility is connected to the surface incident." % valve_count
                )
            if stage == 3:
                return _pick(
                    "KASUS RANGER 07 — ARSIP\nTUJUAN: Masukkan breaker B → A → C dan ambil data T-03.\nKONTEKS: Arsip adalah alasan ranger turun sejauh ini: cari jawaban, bukan sekadar pintu keluar.",
                    "RANGER CASE 07 — ARCHIVE\nOBJECTIVE: Enter breaker sequence B → A → C and retrieve the T-03 data.\nCONTEXT: The Archive is why the ranger came this far: find answers, not merely an exit."
                )
            if stage == 4:
                return _pick(
                    "KASUS RANGER 07 — PERSIAPAN LOCKDOWN\nTUJUAN: Siapkan nyawa, makanan, air, stamina, dan baterai sebelum konsol terakhir.\nHASIL YANG DICARI: jalur menuju Fasilitas Riset Terbatas.",
                    "RANGER CASE 07 — LOCKDOWN PREP\nOBJECTIVE: Prepare health, food, water, stamina, and battery power before the final console.\nTARGET RESULT: a route to the Restricted Research Facility."
                )
            if stage == 5 or holdout_active:
                var seconds: int = maxi(0, int(ceil(holdout_remaining)))
                return _pick(
                    "KASUS RANGER 07 — LOCKDOWN AKTIF\nTUJUAN: Bertahan %d:%02d. Bergerak antar kantong cahaya dan jangan habiskan stamina.\nSETELAH SELESAI: ikuti pintu keluar menuju Fasilitas Riset Terbatas." % [seconds / 60, seconds % 60],
                    "RANGER CASE 07 — LOCKDOWN ACTIVE\nOBJECTIVE: Survive %d:%02d. Move between pockets of light and do not exhaust your stamina.\nAFTER COMPLETION: follow the exit to the Restricted Research Facility." % [seconds / 60, seconds % 60]
                )
            if stage >= 6:
                return _pick(
                    "KASUS RANGER 07 — LABYRINTH SELESAI\nTUJUAN: Ikuti pintu keluar ke Fasilitas Riset Terbatas. T-03 bukan kasus tunggal; tabel routing di fasilitas berikutnya menentukan ekspedisi selanjutnya.",
                    "RANGER CASE 07 — LABYRINTH CLEARED\nOBJECTIVE: Follow the exit to the Restricted Research Facility. T-03 is not an isolated case; the routing table in the next facility determines the next expedition."
                )

        var relay_count: int = _relay_count()
        return _pick(
            "KASUS RANGER 07 — FASILITAS LEVEL 03\nTUJUAN: Aktifkan emergency relay (%d/3), jaga Darkness Exposure, dan cari data T-03.\nKONTEKS: Kamu datang dari Tambang Tua setelah menemukan Facility Access Badge." % relay_count,
            "RANGER CASE 07 — FACILITY LEVEL 03\nOBJECTIVE: Activate the emergency relays (%d/3), manage Darkness Exposure, and find T-03 data.\nCONTEXT: You arrived from the Old Mine after finding the Facility Access Badge." % relay_count
        )

    return super._get_current_mission()
