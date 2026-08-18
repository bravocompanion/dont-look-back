extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const MINE_SCENE_PATH: String = "res://scenes/mine.tscn"
const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const FACILITY_SCENE_PATH: String = "res://scenes/research_facility.tscn"
const MENU_SCENE_PATH: String = "res://scenes/main_menu_ranger.tscn"
const INTERACTABLE_SCRIPT_PATH: String = "res://scripts/investigation_interactable.gd"

const MINE_ENTRANCE_POSITION: Vector3 = Vector3(-98.0, 0.0, -338.0)

const EVIDENCE_DATA: Dictionary = {
    "survey_manifest": {
        "title": "Survey Team Manifest",
        "category": "CASE EVIDENCE",
        "body": "Empat anggota survey meninggalkan ranger station menuju rumah kosong di sektor barat. Catatan terakhir menyebut mereka berencana mencari radio kendaraan di old gas station setelah menemukan simbol tambang pada dinding basement."
    },
    "radio_trace": {
        "title": "Broken Radio Frequency Log",
        "category": "SIGNAL",
        "body": "Radio tua merekam burst pendek pada frekuensi maintenance. Koordinatnya mengarah ke warehouse lama. Pesan yang tersisa hanya: 'shaft access... map cabinet... do not use the main road after dark.'"
    },
    "maintenance_map": {
        "title": "Maintenance Map — Old Mine",
        "category": "MAP",
        "body": "Peta warehouse menunjukkan jalur servis menuju sebuah mine shaft di sudut barat-daya forest. Di bawah simbol tambang ada jalur lain yang diberi label FACILITY ACCESS / LEVEL 03."
    },
    "water_sample": {
        "title": "Cold Water Sample Note",
        "category": "FIELD SAMPLE",
        "body": "Air pompa tetap beberapa derajat lebih dingin dari udara sekitar dan menyebabkan sensor cahaya ranger berkedip. Fenomena yang sama disebut dalam laporan fasilitas bawah tanah."
    },
    "foreman_log": {
        "title": "Foreman's Last Shift",
        "category": "MINE LOG",
        "body": "Tim tambang menemukan pintu logam yang tidak tercantum pada izin penggalian. Setelah pintu itu terbuka, pekerja mulai melaporkan lorong yang berubah panjang ketika lampu dimatikan."
    },
    "sealed_shaft_report": {
        "title": "Sealed Shaft Incident Report",
        "category": "INCIDENT",
        "body": "Shaft terdalam ditutup setelah tiga pekerja menghilang dalam jarak kurang dari dua puluh meter. Tim recovery menemukan helm dan lampu mereka, tetapi tidak menemukan jejak keluar dari terowongan."
    },
    "facility_badge": {
        "title": "Facility Access Badge T-03",
        "category": "ACCESS",
        "body": "Badge milik teknisi fasilitas berada di dekat gate bawah tambang. Kode T-03 cocok dengan referensi fenomena occupancy pada catatan lama. Badge ini membuka jalur menuju Labyrinth."
    },
    "facility_terminal": {
        "title": "Restricted Facility Routing Table",
        "category": "RESTRICTED",
        "body": "Data dari Labyrinth mengarah ke jaringan lokasi lain: rumah sakit, museum, laboratorium containment, sistem gua, dan beberapa simpul Labyrinth lain. Forest hanyalah base pertama; investigasi baru dimulai."
    }
}

var evidence: Dictionary = {}
var progress_flags: Dictionary = {}
var configured_scene_id: int = 0
var interactable_script: Script
var lab_completion_checked: bool = false
var ui_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    interactable_script = load(INTERACTABLE_SCRIPT_PATH) as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        lab_completion_checked = false
        call_deferred("_configure_scene", scene)

    if scene.scene_file_path == LABYRINTH_SCENE_PATH:
        _check_labyrinth_completion()

    ui_timer -= delta
    if ui_timer <= 0.0:
        ui_timer = 0.75
        _refresh_tooltip(scene)

func _configure_scene(scene: Node) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if scene == null or not is_instance_valid(scene) or get_tree().current_scene != scene:
        return

    _configure_narrative_scope(scene.scene_file_path)
    match scene.scene_file_path:
        FOREST_SCENE_PATH:
            _configure_forest(scene)
        MINE_SCENE_PATH:
            _configure_mine(scene)
        FACILITY_SCENE_PATH:
            _configure_facility(scene)
        LABYRINTH_SCENE_PATH:
            pass
    _refresh_tooltip(scene, true)

func _configure_narrative_scope(scene_path: String) -> void:
    var narrative: Node = get_node_or_null("/root/SurvivalSystem/NarrativeLoreRuntime")
    if narrative == null:
        return
    var labyrinth_active: bool = scene_path == LABYRINTH_SCENE_PATH
    if not labyrinth_active and narrative.has_method("_hide_narrative_ui"):
        narrative.call("_hide_narrative_ui")
    narrative.set_process(labyrinth_active)

func _configure_forest(scene: Node) -> void:
    _spawn_interactable(scene, "RangerCaseBoard", "case_board", "case_board", "Ranger Case Board", Vector3(12.15, 1.35, -83.45), Vector3(1.65, 1.05, 0.08))
    _spawn_interactable(scene, "EvidenceSurveyManifest", "evidence", "survey_manifest", "Survey Team Manifest", Vector3(-72.0, 0.92, -157.2), Vector3(0.55, 0.08, 0.40))
    _spawn_interactable(scene, "EvidenceRadioTrace", "evidence", "radio_trace", "Radio Frequency Log", Vector3(78.0, 0.92, -228.0), Vector3(0.48, 0.12, 0.36))
    _spawn_interactable(scene, "EvidenceMaintenanceMap", "evidence", "maintenance_map", "Maintenance Map", Vector3(-70.0, 0.92, -288.0), Vector3(0.62, 0.06, 0.46))
    _spawn_interactable(scene, "EvidenceWaterSample", "evidence", "water_sample", "Cold Water Sample", Vector3(62.0, 0.78, -332.0), Vector3(0.20, 0.42, 0.20))
    _build_forest_mine_entrance(scene)

func _configure_mine(scene: Node) -> void:
    _spawn_interactable(scene, "MineReturn", "forest_return", "forest_return", "Return to Forest", Vector3(0.0, 1.15, 13.0), Vector3(2.2, 2.3, 0.18))
    _spawn_interactable(scene, "EvidenceForemanLog", "evidence", "foreman_log", "Foreman's Log", Vector3(-2.4, 0.78, -18.0), Vector3(0.52, 0.08, 0.38))
    _spawn_interactable(scene, "EvidenceShaftReport", "evidence", "sealed_shaft_report", "Sealed Shaft Report", Vector3(2.3, 0.78, -42.0), Vector3(0.52, 0.08, 0.38))
    _spawn_interactable(scene, "EvidenceFacilityBadge", "evidence", "facility_badge", "Facility Access Badge", Vector3(-1.8, 0.82, -59.0), Vector3(0.22, 0.06, 0.32))
    _spawn_interactable(scene, "LabyrinthAccessGate", "labyrinth_entrance", "labyrinth_gate", "Facility Gate / Labyrinth", Vector3(0.0, 1.3, -70.0), Vector3(3.2, 2.6, 0.20))

func _configure_facility(scene: Node) -> void:
    _spawn_interactable(scene, "EvidenceFacilityTerminal", "evidence", "facility_terminal", "Routing Terminal", Vector3(0.0, 1.05, -22.0), Vector3(1.15, 0.85, 0.24))
    _spawn_interactable(scene, "FacilityDeeperRoute", "facility_route", "future_route", "Deeper Containment Route", Vector3(0.0, 1.3, -39.0), Vector3(3.3, 2.6, 0.20))

func _build_forest_mine_entrance(scene: Node) -> void:
    var root: Node3D = scene.get_node_or_null("InvestigationMineEntrance") as Node3D
    if root == null:
        root = Node3D.new()
        root.name = "InvestigationMineEntrance"
        root.position = MINE_ENTRANCE_POSITION
        scene.add_child(root)
        var material: StandardMaterial3D = StandardMaterial3D.new()
        material.albedo_color = Color(0.09, 0.075, 0.055, 1.0)
        material.roughness = 1.0
        _add_static_box(root, "MineLeft", Vector3(-2.0, 1.5, 0.0), Vector3(1.0, 3.0, 2.4), material)
        _add_static_box(root, "MineRight", Vector3(2.0, 1.5, 0.0), Vector3(1.0, 3.0, 2.4), material)
        _add_static_box(root, "MineTop", Vector3(0.0, 3.0, 0.0), Vector3(5.0, 1.0, 2.4), material)
        var sign: Label3D = Label3D.new()
        sign.name = "MineSign"
        sign.text = "OLD MINE — SHAFT 03"
        sign.position = Vector3(0.0, 3.35, 0.65)
        sign.font_size = 34
        sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        root.add_child(sign)
    _spawn_interactable(scene, "OldMineGate", "mine_entrance", "old_mine", "Old Mine Shaft 03", MINE_ENTRANCE_POSITION + Vector3(0.0, 1.25, 0.65), Vector3(2.7, 2.5, 0.18))

func _spawn_interactable(scene: Node, node_name: String, kind: String, interaction_id: String, display_name: String, position_value: Vector3, size: Vector3) -> void:
    if interactable_script == null or scene.get_node_or_null(NodePath(node_name)) != null:
        return
    var body: StaticBody3D = StaticBody3D.new()
    body.name = node_name
    body.set_script(interactable_script)
    body.set("interaction_kind", kind)
    body.set("interaction_id", interaction_id)
    body.set("display_name", display_name)
    body.set("visual_size", size)
    body.set("visual_offset", Vector3.ZERO)
    body.position = position_value
    scene.add_child(body)

func _add_static_box(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.name = node_name
    body.position = local_position
    parent.add_child(body)
    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    body.add_child(mesh_instance)
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

func get_interaction_text(kind: String, interaction_id: String, display_name: String) -> String:
    match kind:
        "case_board":
            return "Review Ranger Case Board"
        "evidence":
            return "%s — reviewed" % display_name if has_evidence(interaction_id) else "Inspect evidence: %s" % display_name
        "mine_entrance":
            return "Enter Old Mine" if can_enter_mine() else "Old Mine sealed — find the maintenance map"
        "forest_return":
            return "Return to Ranger Forest"
        "labyrinth_entrance":
            return "Enter Labyrinth / Facility Level 03" if can_enter_labyrinth() else "Facility gate locked — find an access badge"
        "facility_route":
            return "Deeper route locked — more evidence required"
    return display_name

func interact_with(kind: String, interaction_id: String, _source: Node) -> void:
    match kind:
        "case_board":
            _set_local_objective(get_current_objective())
        "evidence":
            request_collect_evidence(interaction_id)
        "mine_entrance":
            if not can_enter_mine():
                _set_local_objective("INVESTIGATION: Warehouse lama menyimpan maintenance map yang menunjukkan akses menuju mine.")
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
                _set_local_objective("MINE: Cari Facility Access Badge di shaft terdalam sebelum membuka gate Level 03.")
                return
            var transition_lab: Node = get_node_or_null("/root/MapTransitionSystem")
            if transition_lab != null and transition_lab.has_method("request_labyrinth_transition"):
                transition_lab.call("request_labyrinth_transition")
        "facility_route":
            _set_local_objective("RESTRICTED FACILITY: routing table menunjuk ke Hospital, Museum, Laboratory, Cave, dan node Labyrinth lain. Jalur berikutnya belum terbuka.")

func request_collect_evidence(evidence_id: String) -> void:
    if not EVIDENCE_DATA.has(evidence_id) or has_evidence(evidence_id):
        if has_evidence(evidence_id):
            _set_local_objective("Evidence sudah tercatat di Journal. %s" % get_current_objective())
        return
    if _network_online() and not _is_authoritative():
        _request_evidence_remote.rpc_id(1, evidence_id)
        return
    _collect_evidence_authoritative(evidence_id, _local_peer_id())

@rpc("any_peer", "call_remote", "reliable", 41)
func _request_evidence_remote(evidence_id: String) -> void:
    if not _is_authoritative() or not EVIDENCE_DATA.has(evidence_id):
        return
    _collect_evidence_authoritative(evidence_id, multiplayer.get_remote_sender_id())

func _collect_evidence_authoritative(evidence_id: String, collector_peer_id: int) -> void:
    if has_evidence(evidence_id):
        return
    evidence[evidence_id] = true
    _discover_journal_entry(evidence_id)
    if _network_online():
        _sync_investigation_state.rpc(evidence.duplicate(true), progress_flags.duplicate(true))
    var data: Dictionary = Dictionary(EVIDENCE_DATA.get(evidence_id, {}))
    _feedback_peer(collector_peer_id, "EVIDENCE: %s. %s" % [str(data.get("title", evidence_id)), get_current_objective()])
    _request_autosave("Investigation evidence")

@rpc("authority", "call_remote", "reliable", 42)
func _sync_investigation_state(remote_evidence: Dictionary, remote_flags: Dictionary) -> void:
    evidence = remote_evidence.duplicate(true)
    progress_flags = remote_flags.duplicate(true)
    _discover_all_collected_entries()
    _set_local_objective(get_current_objective())

func _check_labyrinth_completion() -> void:
    if lab_completion_checked and bool(progress_flags.get("labyrinth_cleared", false)):
        return
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null or int(arc.get("current_stage")) < 6:
        return
    lab_completion_checked = true
    if not _is_authoritative():
        return
    if bool(progress_flags.get("labyrinth_cleared", false)):
        return
    progress_flags["labyrinth_cleared"] = true
    if _network_online():
        _sync_investigation_state.rpc(evidence.duplicate(true), progress_flags.duplicate(true))
    _request_autosave("Labyrinth investigation complete")

func has_evidence(evidence_id: String) -> bool:
    return bool(evidence.get(evidence_id, false))

func can_enter_mine() -> bool:
    return has_evidence("maintenance_map")

func can_enter_labyrinth() -> bool:
    return has_evidence("facility_badge")

func can_enter_research_facility() -> bool:
    return bool(progress_flags.get("labyrinth_cleared", false))

func get_current_objective() -> String:
    var scene: Node = get_tree().current_scene
    var path: String = scene.scene_file_path if scene != null else ""
    if path == FOREST_SCENE_PATH:
        if not has_evidence("survey_manifest"):
            return "CASE 01: Periksa Abandoned House di jalur barat. Cari jejak survey team yang hilang."
        if not has_evidence("radio_trace"):
            return "CASE 02: Ikuti petunjuk survey team ke Old Gas Station dan cari radio/log komunikasi."
        if not has_evidence("maintenance_map"):
            return "CASE 03: Sinyal maintenance mengarah ke Warehouse. Cari peta akses bawah tanah."
        if not has_evidence("water_sample"):
            return "OLD MINE TERUNGKAP: Mine dapat dimasuki. Opsional: periksa Water Pump untuk sampel anomali sebelum turun."
        return "OLD MINE TERUNGKAP: Siapkan food, water, battery, medkit, lalu ikuti trail dari Warehouse menuju Shaft 03."
    if path == MINE_SCENE_PATH:
        if not has_evidence("foreman_log"):
            return "MINE INVESTIGATION: Telusuri shaft dan cari log foreman."
        if not has_evidence("sealed_shaft_report"):
            return "MINE INVESTIGATION: Cari laporan insiden dari shaft yang disegel."
        if not has_evidence("facility_badge"):
            return "MINE INVESTIGATION: Gate bawah membutuhkan Facility Access Badge. Cari di bagian terdalam."
        return "FACILITY ACCESS: Badge ditemukan. Masuk gate Level 03 menuju Labyrinth."
    if path == LABYRINTH_SCENE_PATH:
        return "LABYRINTH: Pulihkan fasilitas dan cari data T-03. Journal (J) menyimpan evidence dari forest dan mine."
    if path == FACILITY_SCENE_PATH:
        if not has_evidence("facility_terminal"):
            return "RESTRICTED FACILITY: Periksa routing terminal dan cari tujuan investigasi berikutnya."
        return "INVESTIGATION EXPANDS: Hospital, Museum, Laboratory, Cave, dan Labyrinth lain kini tercatat sebagai target berikutnya."
    return "SURVIVE • INVESTIGATE • RETURN WITH EVIDENCE"

func get_current_mission_text() -> String:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return "INVESTIGATION: menunggu world."
    match scene.scene_file_path:
        FOREST_SCENE_PATH:
            return "RANGER INVESTIGATION — FOREST\nTUJUAN: %s\nLOOP: siapkan gear di cabin → ekspedisi → kumpulkan evidence/resource → kembali sebelum kondisi memburuk.\nSAFE ZONE: halaman cabin 30×30 m; hostile dan random resource tidak spawn di dalam.\nROUTE: Cabin → Abandoned House → Gas Station → Warehouse → Old Mine." % get_current_objective()
        MINE_SCENE_PATH:
            return "OLD MINE — INVESTIGATION LAYER\nTUJUAN: %s\nATURAN: mine adalah scene terpisah; resource dan ancaman forest tidak ikut dimuat. Cahaya redup membantu melihat, tetapi tidak selalu melindungi dari Darkness.\nROUTE: Mine Entrance → Foreman Log → Sealed Shaft → Facility Badge → Labyrinth Gate." % get_current_objective()
        FACILITY_SCENE_PATH:
            return "RESTRICTED RESEARCH FACILITY\nTUJUAN: %s\nHASIL: data Labyrinth mengubah investigasi dari satu kasus lokal menjadi jaringan lokasi anomali. Lokasi berikutnya akan dibuka melalui evidence, bukan teleport acak." % get_current_objective()
    return ""

func get_save_state() -> Dictionary:
    return {
        "evidence": evidence.duplicate(true),
        "progress_flags": progress_flags.duplicate(true)
    }

func restore_save_state(state: Dictionary) -> void:
    evidence = Dictionary(state.get("evidence", {})).duplicate(true)
    progress_flags = Dictionary(state.get("progress_flags", {})).duplicate(true)
    _discover_all_collected_entries()
    var scene: Node = get_tree().current_scene
    if scene != null:
        call_deferred("_refresh_tooltip", scene, true)

func reset_progress() -> void:
    evidence.clear()
    progress_flags.clear()
    lab_completion_checked = false

func _discover_all_collected_entries() -> void:
    for id_value: Variant in evidence.keys():
        var evidence_id: String = str(id_value)
        if bool(evidence.get(evidence_id, false)):
            _discover_journal_entry(evidence_id)

func _discover_journal_entry(evidence_id: String) -> void:
    var data: Dictionary = Dictionary(EVIDENCE_DATA.get(evidence_id, {}))
    if data.is_empty():
        return
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null or not journal.has_method("discover_entry"):
        return
    var journal_id: String = "investigation_%s" % evidence_id
    if journal.has_method("has_entry") and bool(journal.call("has_entry", journal_id)):
        return
    journal.call("discover_entry", journal_id, str(data.get("title", evidence_id)), str(data.get("category", "EVIDENCE")), str(data.get("body", "")), false)

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
                controls.text = "RANGER: WASD Move  Shift Sprint  E Inspect/Use  F Flashlight  B Battery  J Journal  K Save  M Co-op"
            MINE_SCENE_PATH:
                controls.text = "MINE: WASD Move  Shift Sprint  E Inspect  F Flashlight  B Battery  J Evidence Journal  K Save"
            LABYRINTH_SCENE_PATH:
                controls.text = "LABYRINTH: WASD Move  Shift Sprint  E Use  F Flashlight  B Battery  J Journal  K Save"
            FACILITY_SCENE_PATH:
                controls.text = "FACILITY: WASD Move  E Inspect  F Flashlight  J Journal  K Save"
    if force_objective:
        _set_local_objective(get_current_objective())

func _set_local_objective(text: String) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _feedback_peer(peer_id: int, text: String) -> void:
    if not _network_online() or peer_id == _local_peer_id():
        _set_local_objective(text)
        return
    _receive_feedback_remote.rpc_id(peer_id, text)

@rpc("authority", "call_remote", "reliable", 43)
func _receive_feedback_remote(text: String) -> void:
    _set_local_objective(text)

func _request_autosave(reason: String) -> void:
    var save: Node = get_node_or_null("/root/SaveSystem")
    if save != null and save.has_method("request_autosave"):
        save.call("request_autosave", reason)

func _local_player() -> CharacterBody3D:
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

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _local_peer_id() -> int:
    return multiplayer.get_unique_id() if _network_online() else 1

func _on_peer_connected(peer_id: int) -> void:
    if not _is_authoritative() or peer_id <= 1:
        return
    _sync_investigation_state.rpc_id(peer_id, evidence.duplicate(true), progress_flags.duplicate(true))
