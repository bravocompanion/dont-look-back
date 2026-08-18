extends "res://scripts/investigation_system_v3.gd"

func _is_id() -> bool:
    var language: Node = get_node_or_null("/root/LanguageSystem")
    return language == null or not language.has_method("is_indonesian") or bool(language.call("is_indonesian"))

func _pick(id_text: String, en_text: String) -> String:
    return id_text if _is_id() else en_text

func _localized_evidence_data(evidence_id: String) -> Dictionary:
    var language: Node = get_node_or_null("/root/LanguageSystem")
    if language != null and language.has_method("get_journal_entry_data"):
        var data: Dictionary = Dictionary(language.call("get_journal_entry_data", "investigation_%s" % evidence_id))
        if not data.is_empty():
            return data
    var fallback: Dictionary = Dictionary(EVIDENCE_DATA.get(evidence_id, {}))
    return {
        "title": str(fallback.get("title", evidence_id)),
        "category": str(fallback.get("category", "EVIDENCE")),
        "body": str(fallback.get("body", ""))
    }

func get_interaction_text(kind: String, interaction_id: String, display_name: String) -> String:
    match kind:
        "case_board":
            return _pick("Periksa Papan Kasus Ranger", "Review Ranger Case Board")
        "evidence":
            var title: String = str(_localized_evidence_data(interaction_id).get("title", display_name))
            if has_evidence(interaction_id):
                return _pick("%s — sudah diperiksa" % title, "%s — reviewed" % title)
            return _pick("Periksa bukti: %s" % title, "Inspect evidence: %s" % title)
        "mine_entrance":
            if can_enter_mine():
                return _pick("Masuk ke Tambang Tua", "Enter Old Mine")
            return _pick("Tambang Tua terkunci — cari peta maintenance", "Old Mine sealed — find the maintenance map")
        "forest_return":
            return _pick("Kembali ke Hutan Ranger", "Return to Ranger Forest")
        "labyrinth_entrance":
            if can_enter_labyrinth():
                return _pick("Masuk Labyrinth / Fasilitas Level 03", "Enter Labyrinth / Facility Level 03")
            return _pick("Gerbang fasilitas terkunci — cari badge akses", "Facility gate locked — find an access badge")
        "facility_route":
            return _pick("Jalur lebih dalam terkunci — butuh bukti tambahan", "Deeper route locked — more evidence required")
    return display_name

func interact_with(kind: String, interaction_id: String, _source: Node) -> void:
    match kind:
        "case_board":
            _set_local_objective(get_current_objective())
        "evidence":
            request_collect_evidence(interaction_id)
        "mine_entrance":
            if not can_enter_mine():
                _set_local_objective(_pick(
                    "INVESTIGASI: Gudang lama menyimpan peta maintenance yang menunjukkan akses menuju tambang.",
                    "INVESTIGATION: The old warehouse holds a maintenance map showing access to the mine."
                ))
                return
            var transition: Node = get_node_or_null("/root/MapTransitionSystem")
            if transition != null and transition.has_method("request_mine_transition"):
                transition.call("request_mine_transition")
        "forest_return":
            var transition_back: Node = get_node_or_null("/root/MapTransitionSystem")
            if transition_back != null and transition_back.has_method("request_forest_return"):
                transition_back.call("request_forest_return")
        "labyrinth_entrance":
            if not can_enter_labyrinth():
                _set_local_objective(_pick(
                    "TAMBANG: Cari Facility Access Badge di shaft terdalam sebelum membuka gerbang Level 03.",
                    "MINE: Find the Facility Access Badge in the deepest shaft before opening the Level 03 gate."
                ))
                return
            var transition_lab: Node = get_node_or_null("/root/MapTransitionSystem")
            if transition_lab != null and transition_lab.has_method("request_labyrinth_transition"):
                transition_lab.call("request_labyrinth_transition")
        "facility_route":
            _set_local_objective(_pick(
                "FASILITAS TERBATAS: tabel routing menunjuk ke Hospital, Museum, Laboratory, Cave, dan node Labyrinth lain. Jalur berikutnya belum terbuka.",
                "RESTRICTED FACILITY: the routing table points to the Hospital, Museum, Laboratory, Cave, and other Labyrinth nodes. The next route is not open yet."
            ))

func request_collect_evidence(evidence_id: String) -> void:
    if not EVIDENCE_DATA.has(evidence_id) or has_evidence(evidence_id):
        if has_evidence(evidence_id):
            _set_local_objective(_pick(
                "Bukti sudah tercatat di Jurnal. %s" % get_current_objective(),
                "Evidence is already recorded in the Journal. %s" % get_current_objective()
            ))
        return
    if _network_online() and not _is_authoritative():
        _request_evidence_remote.rpc_id(1, evidence_id)
        return
    _collect_evidence_authoritative(evidence_id, _local_peer_id())

func _collect_evidence_authoritative(evidence_id: String, collector_peer_id: int) -> void:
    if has_evidence(evidence_id):
        return
    evidence[evidence_id] = true
    _discover_journal_entry(evidence_id)
    if _network_online():
        _sync_investigation_state.rpc(evidence.duplicate(true), progress_flags.duplicate(true))
    var data: Dictionary = _localized_evidence_data(evidence_id)
    _feedback_peer(
        collector_peer_id,
        _pick(
            "BUKTI: %s. %s" % [str(data.get("title", evidence_id)), get_current_objective()],
            "EVIDENCE: %s. %s" % [str(data.get("title", evidence_id)), get_current_objective()]
        )
    )
    _request_autosave("Investigation evidence")

func _discover_journal_entry(evidence_id: String) -> void:
    var data: Dictionary = _localized_evidence_data(evidence_id)
    if data.is_empty():
        return
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null or not journal.has_method("discover_entry"):
        return
    var journal_id: String = "investigation_%s" % evidence_id
    if journal.has_method("has_entry") and bool(journal.call("has_entry", journal_id)):
        return
    journal.call(
        "discover_entry",
        journal_id,
        str(data.get("title", evidence_id)),
        str(data.get("category", "EVIDENCE")),
        str(data.get("body", "")),
        false
    )

func get_current_objective() -> String:
    var scene: Node = get_tree().current_scene
    var path: String = scene.scene_file_path if scene != null else ""
    if path == FOREST_SCENE_PATH:
        if not has_evidence("survey_manifest"):
            return _pick(
                "KASUS 01: Periksa Rumah Kosong di jalur barat. Cari jejak tim survey yang hilang.",
                "CASE 01: Inspect the Abandoned House on the western trail. Look for traces of the missing survey team."
            )
        if not has_evidence("radio_trace"):
            return _pick(
                "KASUS 02: Ikuti petunjuk tim survey ke SPBU Tua dan cari radio/log komunikasi.",
                "CASE 02: Follow the survey team's trail to the Old Gas Station and find the radio/communications log."
            )
        if not has_evidence("maintenance_map"):
            return _pick(
                "KASUS 03: Sinyal maintenance mengarah ke Gudang. Cari peta akses bawah tanah.",
                "CASE 03: The maintenance signal leads to the Warehouse. Find the underground access map."
            )
        if not has_evidence("water_sample"):
            return _pick(
                "TAMBANG TUA TERUNGKAP: Tambang dapat dimasuki. Opsional: periksa Pompa Air untuk sampel anomali sebelum turun.",
                "OLD MINE REVEALED: The mine can now be entered. Optional: inspect the Water Pump for an anomalous sample before descending."
            )
        return _pick(
            "TAMBANG TUA TERUNGKAP: Siapkan makanan, air, baterai, medkit, lalu ikuti trail dari Gudang menuju Shaft 03.",
            "OLD MINE REVEALED: Prepare food, water, batteries, and a medkit, then follow the trail from the Warehouse to Shaft 03."
        )
    if path == MINE_SCENE_PATH:
        if not has_evidence("foreman_log"):
            return _pick("INVESTIGASI TAMBANG: Telusuri shaft dan cari log foreman.", "MINE INVESTIGATION: Search the shaft and find the foreman's log.")
        if not has_evidence("sealed_shaft_report"):
            return _pick("INVESTIGASI TAMBANG: Cari laporan insiden dari shaft yang disegel.", "MINE INVESTIGATION: Find the incident report from the sealed shaft.")
        if not has_evidence("facility_badge"):
            return _pick("INVESTIGASI TAMBANG: Gerbang bawah membutuhkan Facility Access Badge. Cari di bagian terdalam.", "MINE INVESTIGATION: The lower gate requires a Facility Access Badge. Search the deepest section.")
        return _pick("AKSES FASILITAS: Badge ditemukan. Masuk gerbang Level 03 menuju Labyrinth.", "FACILITY ACCESS: Badge found. Enter the Level 03 gate leading to the Labyrinth.")
    if path == LABYRINTH_SCENE_PATH:
        return _pick(
            "LABYRINTH: Pulihkan fasilitas dan cari data T-03. Jurnal (J) menyimpan bukti dari hutan dan tambang.",
            "LABYRINTH: Restore the facility and find T-03 data. The Journal (J) contains evidence from the forest and mine."
        )
    if path == FACILITY_SCENE_PATH:
        if not has_evidence("facility_terminal"):
            return _pick(
                "FASILITAS TERBATAS: Periksa terminal routing dan cari tujuan investigasi berikutnya.",
                "RESTRICTED FACILITY: Inspect the routing terminal and identify the next investigation target."
            )
        return _pick(
            "INVESTIGASI MELUAS: Hospital, Museum, Laboratory, Cave, dan Labyrinth lain kini tercatat sebagai target berikutnya.",
            "INVESTIGATION EXPANDS: Hospital, Museum, Laboratory, Cave, and other Labyrinth nodes are now recorded as future targets."
        )
    return _pick("BERTAHAN • SELIDIKI • KEMBALI DENGAN BUKTI", "SURVIVE • INVESTIGATE • RETURN WITH EVIDENCE")

func get_current_mission_text() -> String:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return _pick("INVESTIGASI: menunggu dunia dimuat.", "INVESTIGATION: waiting for the world to load.")
    match scene.scene_file_path:
        FOREST_SCENE_PATH:
            return _pick(
                "INVESTIGASI RANGER — HUTAN\nTUJUAN: %s\nLOOP: siapkan gear di cabin → ekspedisi → kumpulkan bukti/resource → kembali sebelum kondisi memburuk.\nZONA AMAN: halaman cabin 30×30 m; ancaman dan resource acak tidak spawn di dalam.\nRUTE: Cabin → Rumah Kosong → SPBU Tua → Gudang → Tambang Tua." % get_current_objective(),
                "RANGER INVESTIGATION — FOREST\nOBJECTIVE: %s\nLOOP: prepare gear at the cabin → expedition → collect evidence/resources → return before conditions deteriorate.\nSAFE ZONE: the 30×30 m cabin yard; hostiles and random resources do not spawn inside.\nROUTE: Cabin → Abandoned House → Old Gas Station → Warehouse → Old Mine." % get_current_objective()
            )
        MINE_SCENE_PATH:
            return _pick(
                "TAMBANG TUA — LAPISAN INVESTIGASI\nTUJUAN: %s\nATURAN: tambang adalah scene terpisah; resource dan ancaman hutan tidak ikut dimuat. Cahaya redup membantu melihat, tetapi tidak selalu melindungi dari Darkness.\nRUTE: Pintu Tambang → Log Foreman → Shaft Tersegel → Badge Fasilitas → Gerbang Labyrinth." % get_current_objective(),
                "OLD MINE — INVESTIGATION LAYER\nOBJECTIVE: %s\nRULE: the mine is a separate scene; forest resources and threats are not loaded here. Dim light helps visibility but does not always protect against Darkness.\nROUTE: Mine Entrance → Foreman Log → Sealed Shaft → Facility Badge → Labyrinth Gate." % get_current_objective()
            )
        FACILITY_SCENE_PATH:
            return _pick(
                "FASILITAS RISET TERBATAS\nTUJUAN: %s\nHASIL: data Labyrinth mengubah investigasi dari satu kasus lokal menjadi jaringan lokasi anomali. Lokasi berikutnya dibuka melalui bukti, bukan teleport acak." % get_current_objective(),
                "RESTRICTED RESEARCH FACILITY\nOBJECTIVE: %s\nRESULT: Labyrinth data turns the investigation from one local case into a network of anomalous locations. Future locations are unlocked through evidence, not random teleportation." % get_current_objective()
            )
    return ""

func _refresh_tooltip(scene: Node, force_objective: bool = false) -> void:
    if scene == null or scene.scene_file_path == MENU_SCENE_PATH:
        return
    var player: CharacterBody3D = _local_player()
    if player == null:
        return
    var controls: Label = player.get_node_or_null("HUD/Controls") as Label
    if controls != null:
        match scene.scene_file_path:
            FOREST_SCENE_PATH:
                controls.text = _pick(
                    "RANGER: WASD Gerak  Shift Lari  E Periksa/Gunakan  F Senter  B Baterai  J Jurnal  K Simpan  M Co-op",
                    "RANGER: WASD Move  Shift Sprint  E Inspect/Use  F Flashlight  B Battery  J Journal  K Save  M Co-op"
                )
            MINE_SCENE_PATH:
                controls.text = _pick(
                    "TAMBANG: WASD Gerak  Shift Lari  E Periksa  F Senter  B Baterai  J Jurnal Bukti  K Simpan",
                    "MINE: WASD Move  Shift Sprint  E Inspect  F Flashlight  B Battery  J Evidence Journal  K Save"
                )
            LABYRINTH_SCENE_PATH:
                controls.text = _pick(
                    "LABYRINTH: WASD Gerak  Shift Lari  E Gunakan  F Senter  B Baterai  J Jurnal  K Simpan",
                    "LABYRINTH: WASD Move  Shift Sprint  E Use  F Flashlight  B Battery  J Journal  K Save"
                )
            FACILITY_SCENE_PATH:
                controls.text = _pick(
                    "FASILITAS: WASD Gerak  E Periksa  F Senter  J Jurnal  K Simpan",
                    "FACILITY: WASD Move  E Inspect  F Flashlight  J Journal  K Save"
                )
    if force_objective:
        _set_local_objective(get_current_objective())
