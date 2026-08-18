extends "res://scripts/map_transition_system.gd"

const RANGER_FOREST_SCENE: String = "res://scenes/forest.tscn"
const RANGER_MINE_SCENE: String = "res://scenes/mine.tscn"
const RANGER_LABYRINTH_SCENE: String = "res://scenes/main.tscn"
const RANGER_FACILITY_SCENE: String = "res://scenes/research_facility.tscn"

const RANGER_CABIN_SPAWN: Vector3 = Vector3(14.0, 0.92, -90.0)
const FOREST_MINE_RETURN_SPAWN: Vector3 = Vector3(-94.0, 0.92, -334.0)
const MINE_ENTRY_SPAWN: Vector3 = Vector3(0.0, 0.92, 9.0)
const LAB_ENTRY_SPAWN: Vector3 = Vector3(0.0, 0.92, 9.5)
const FACILITY_ENTRY_SPAWN: Vector3 = Vector3(0.0, 0.92, 8.0)

func request_mine_transition() -> void:
    if transitioning:
        return
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    if investigation != null and investigation.has_method("can_enter_mine") and not bool(investigation.call("can_enter_mine")):
        _objective("Old Mine masih terkunci oleh investigasi. Cari Maintenance Map di Warehouse.")
        return
    if not _network_online_v2():
        _begin_transition(RANGER_MINE_SCENE, MINE_ENTRY_SPAWN, "OLD MINE — SHAFT 03", "Leaving the forest safe route...")
        return
    if _is_host_v2():
        _host_start_mine_transition()
    else:
        _request_mine_transition_remote.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 51)
func _request_mine_transition_remote() -> void:
    if _is_host_v2():
        _host_start_mine_transition()

func _host_start_mine_transition() -> void:
    if transitioning:
        return
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    if investigation != null and investigation.has_method("can_enter_mine") and not bool(investigation.call("can_enter_mine")):
        return
    _transition_mine_remote.rpc()
    _begin_transition(RANGER_MINE_SCENE, MINE_ENTRY_SPAWN, "OLD MINE — SHAFT 03", "Team entering the mine...")

@rpc("authority", "call_remote", "reliable", 51)
func _transition_mine_remote() -> void:
    if not transitioning:
        _begin_transition(RANGER_MINE_SCENE, MINE_ENTRY_SPAWN, "OLD MINE — SHAFT 03", "Matching host investigation...")

func request_forest_return() -> void:
    if transitioning:
        return
    if not _network_online_v2():
        _begin_transition(RANGER_FOREST_SCENE, FOREST_MINE_RETURN_SPAWN, "RANGER FOREST", "Climbing back to the surface...")
        return
    if _is_host_v2():
        _transition_forest_return_remote.rpc()
        _begin_transition(RANGER_FOREST_SCENE, FOREST_MINE_RETURN_SPAWN, "RANGER FOREST", "Team returning to the surface...")
    else:
        _request_forest_return_remote.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 52)
func _request_forest_return_remote() -> void:
    if not _is_host_v2() or transitioning:
        return
    _transition_forest_return_remote.rpc()
    _begin_transition(RANGER_FOREST_SCENE, FOREST_MINE_RETURN_SPAWN, "RANGER FOREST", "Team returning to the surface...")

@rpc("authority", "call_remote", "reliable", 52)
func _transition_forest_return_remote() -> void:
    if not transitioning:
        _begin_transition(RANGER_FOREST_SCENE, FOREST_MINE_RETURN_SPAWN, "RANGER FOREST", "Matching host world...")

func request_labyrinth_transition() -> void:
    if transitioning:
        return
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    if investigation != null and investigation.has_method("can_enter_labyrinth") and not bool(investigation.call("can_enter_labyrinth")):
        _objective("Facility gate membutuhkan Access Badge dari shaft terdalam.")
        return
    if not _network_online_v2():
        _begin_transition(RANGER_LABYRINTH_SCENE, LAB_ENTRY_SPAWN, "FACILITY LEVEL 03 — LABYRINTH", "Descending below the mine...")
        return
    if _is_host_v2():
        _host_start_labyrinth_transition()
    else:
        _request_labyrinth_transition_remote.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 53)
func _request_labyrinth_transition_remote() -> void:
    if _is_host_v2():
        _host_start_labyrinth_transition()

func _host_start_labyrinth_transition() -> void:
    if transitioning:
        return
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    if investigation != null and investigation.has_method("can_enter_labyrinth") and not bool(investigation.call("can_enter_labyrinth")):
        return
    _transition_labyrinth_v2_remote.rpc()
    _begin_transition(RANGER_LABYRINTH_SCENE, LAB_ENTRY_SPAWN, "FACILITY LEVEL 03 — LABYRINTH", "Team descending below the mine...")

@rpc("authority", "call_remote", "reliable", 53)
func _transition_labyrinth_v2_remote() -> void:
    if not transitioning:
        _begin_transition(RANGER_LABYRINTH_SCENE, LAB_ENTRY_SPAWN, "FACILITY LEVEL 03 — LABYRINTH", "Matching host investigation...")

func request_research_transition() -> void:
    if transitioning:
        return
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    var cleared: bool = investigation == null or not investigation.has_method("can_enter_research_facility") or bool(investigation.call("can_enter_research_facility"))
    if not cleared or not _labyrinth_exit_unlocked():
        _objective("Jalur research facility belum aman. Selesaikan sistem Labyrinth terlebih dahulu.")
        return
    if not _network_online_v2():
        _begin_transition(RANGER_FACILITY_SCENE, FACILITY_ENTRY_SPAWN, "RESTRICTED RESEARCH FACILITY", "Following the T-03 data route...")
        return
    if _is_host_v2():
        _host_start_research_transition()
    else:
        _request_research_transition_remote.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 54)
func _request_research_transition_remote() -> void:
    if _is_host_v2():
        _host_start_research_transition()

func _host_start_research_transition() -> void:
    if transitioning or not _labyrinth_exit_unlocked():
        return
    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    if investigation != null and investigation.has_method("can_enter_research_facility") and not bool(investigation.call("can_enter_research_facility")):
        return
    _transition_research_remote.rpc()
    _begin_transition(RANGER_FACILITY_SCENE, FACILITY_ENTRY_SPAWN, "RESTRICTED RESEARCH FACILITY", "Team following the T-03 route...")

@rpc("authority", "call_remote", "reliable", 54)
func _transition_research_remote() -> void:
    if not transitioning:
        _begin_transition(RANGER_FACILITY_SCENE, FACILITY_ENTRY_SPAWN, "RESTRICTED RESEARCH FACILITY", "Matching host investigation...")

func _on_peer_connected(peer_id: int) -> void:
    if not _is_host_v2():
        return
    call_deferred("_send_current_map_to_peer", peer_id)

func _send_current_map_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var scene_path: String = scene.scene_file_path
    if not _allowed_scene(scene_path):
        scene_path = RANGER_FOREST_SCENE
    _sync_map_v2_remote.rpc_id(peer_id, scene_path)

@rpc("authority", "call_remote", "reliable", 55)
func _sync_map_v2_remote(scene_path: String) -> void:
    if not _allowed_scene(scene_path):
        return
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == scene_path:
        return
    _begin_transition(scene_path, _spawn_for_scene(scene_path), _sync_title(scene_path), "Matching the host world...")

func _change_scene_and_restore(scene_path: String, spawn_position: Vector3) -> void:
    progress_bar.value = 18.0
    var change_error: Error = get_tree().change_scene_to_file(scene_path)
    if change_error != OK:
        _fail_transition("Could not load the next map.")
        return

    var player: CharacterBody3D = null
    var world_ready: bool = false
    for frame_index: int in range(90):
        await get_tree().process_frame
        progress_bar.value = minf(88.0, 22.0 + float(frame_index) * 0.75)
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if player != null:
            _lock_player(player)
        var scene: Node = get_tree().current_scene
        if scene != null and scene.scene_file_path == scene_path:
            world_ready = _scene_world_ready(scene, scene_path)
        if player != null and world_ready:
            break

    if player == null or not world_ready:
        _fail_transition("The map loaded, but its scene-specific world was not ready.")
        return

    _apply_local_player_state(player, pending_player_state)
    player.global_position = spawn_position
    player.velocity = Vector3.ZERO
    player.set("flashlight_panic", 0.0)

    if scene_path == RANGER_FOREST_SCENE:
        player.set("darkness_exposure", minf(18.0, float(player.get("darkness_exposure"))))
    elif scene_path == RANGER_MINE_SCENE:
        player.set("darkness_exposure", minf(30.0, float(player.get("darkness_exposure"))))

    var investigation: Node = get_node_or_null("/root/InvestigationSystem")
    var objective_text: String = ""
    if investigation != null and investigation.has_method("get_current_objective"):
        objective_text = str(investigation.call("get_current_objective"))
    if scene_path == RANGER_LABYRINTH_SCENE:
        objective_text = "LABYRINTH: Restore facility systems, recover T-03 data, and survive the lockdown."
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null and not objective_text.is_empty():
        objective.text = objective_text

    detail_label.text = _ready_detail(scene_path)
    progress_bar.value = 100.0
    await get_tree().process_frame
    await get_tree().process_frame

    _unlock_player(player)
    _block_mobile(false)
    if not _mobile_active():
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    _hide_loading()
    pending_player_state.clear()
    transitioning = false

func _scene_world_ready(scene: Node, scene_path: String) -> bool:
    match scene_path:
        RANGER_FOREST_SCENE:
            return scene.get_node_or_null("OutsideWorld/ForestGround") != null
        RANGER_MINE_SCENE:
            return scene.get_node_or_null("MineWorld/Floor") != null
        RANGER_LABYRINTH_SCENE:
            return scene.get_node_or_null("LabyrinthExpansion") != null
        RANGER_FACILITY_SCENE:
            return scene.get_node_or_null("FacilityWorld/Floor") != null
    return false

func _allowed_scene(scene_path: String) -> bool:
    return scene_path in [RANGER_FOREST_SCENE, RANGER_MINE_SCENE, RANGER_LABYRINTH_SCENE, RANGER_FACILITY_SCENE]

func _spawn_for_scene(scene_path: String) -> Vector3:
    match scene_path:
        RANGER_FOREST_SCENE:
            return RANGER_CABIN_SPAWN
        RANGER_MINE_SCENE:
            return MINE_ENTRY_SPAWN
        RANGER_FACILITY_SCENE:
            return FACILITY_ENTRY_SPAWN
    return LAB_ENTRY_SPAWN

func _sync_title(scene_path: String) -> String:
    match scene_path:
        RANGER_FOREST_SCENE: return "SYNCING RANGER FOREST"
        RANGER_MINE_SCENE: return "SYNCING OLD MINE"
        RANGER_FACILITY_SCENE: return "SYNCING RESEARCH FACILITY"
    return "SYNCING LABYRINTH"

func _ready_detail(scene_path: String) -> String:
    match scene_path:
        RANGER_FOREST_SCENE: return "Forest ready. Cabin remains your safe base."
        RANGER_MINE_SCENE: return "Mine ready. Evidence route continues below."
        RANGER_FACILITY_SCENE: return "Facility ready. Review the routing terminal."
    return "Labyrinth ready. Recover the T-03 data."

func _network_online_v2() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host_v2() -> bool:
    if not _network_online_v2():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _objective(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text
