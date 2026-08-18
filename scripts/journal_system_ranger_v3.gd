extends "res://scripts/journal_system_ranger_v2.gd"

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
                return "RANGER CASE 07 — LABYRINTH / MAINTENANCE\nTUJUAN: Pulihkan tiga fuse box (%d/3) dan cari hubungan T-03 dengan tim survey.\nKONTEKS: Kamu masuk ke fasilitas ini melalui Old Mine; jalur kembali bukan tujuan utama. Evidence harus dibawa maju." % fuse_count
            if stage == 2:
                var valve_count: int = _count_arc_ids(completed, ["valve_a", "valve_b"])
                return "RANGER CASE 07 — FLOODED SERVICE\nTUJUAN: Tutup pressure valve (%d/2), pertahankan battery, dan cari data facility route.\nKONTEKS: Mine membuktikan fasilitas ini terhubung ke insiden permukaan." % valve_count
            if stage == 3:
                return "RANGER CASE 07 — ARCHIVE\nTUJUAN: Masukkan breaker B → A → C dan ambil data T-03.\nKONTEKS: Archive adalah alasan ranger turun sejauh ini: cari jawaban, bukan sekadar pintu keluar."
            if stage == 4:
                return "RANGER CASE 07 — LOCKDOWN PREP\nTUJUAN: Siapkan health, food, water, stamina, dan battery sebelum console terakhir.\nHASIL YANG DICARI: jalur menuju Restricted Research Facility."
            if stage == 5 or holdout_active:
                var seconds: int = maxi(0, int(ceil(holdout_remaining)))
                return "RANGER CASE 07 — LOCKDOWN ACTIVE\nTUJUAN: Bertahan %d:%02d. Bergerak antar pocket cahaya dan jangan habiskan stamina.\nSETELAH SELESAI: ikuti exit menuju Restricted Research Facility." % [seconds / 60, seconds % 60]
            if stage >= 6:
                return "RANGER CASE 07 — LABYRINTH CLEARED\nTUJUAN: Ikuti exit ke Restricted Research Facility. T-03 bukan kasus tunggal; routing table di fasilitas berikutnya menentukan ekspedisi selanjutnya."

        var relay_count: int = _relay_count()
        return "RANGER CASE 07 — FACILITY LEVEL 03\nTUJUAN: Aktifkan emergency relay (%d/3), jaga Darkness Exposure, dan cari data T-03.\nKONTEKS: Kamu datang dari Old Mine setelah menemukan Facility Access Badge." % relay_count

    return super._get_current_mission()
