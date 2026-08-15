extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const LABYRINTH_SPAWN: Vector3 = Vector3(0.0, 0.92, 9.5)
const FOREST_SPAWN: Vector3 = Vector3(0.0, 0.92, -57.5)

var transitioning: bool = false
var pending_player_state: Dictionary = {}
var layer: CanvasLayer
var overlay: ColorRect
var title_label: Label
var detail_label: Label
var progress_bar: ProgressBar

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_loading_ui()
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func request_forest_transition() -> void:
    if transitioning:
        return

    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if not online:
        _begin_transition(FOREST_SCENE_PATH, FOREST_SPAWN, "THE OUTSIDE", "Leaving the labyrinth...")
        return

    var hosting: bool = network.has_method("is_server") and bool(network.call("is_server"))
    if hosting:
        _host_start_forest_transition()
    else:
        _request_forest_transition.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 7)
func _request_forest_transition() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_server") or not bool(network.call("is_server")):
        return
    _host_start_forest_transition()

func _host_start_forest_transition() -> void:
    if transitioning or not _labyrinth_exit_unlocked():
        return
    _transition_to_forest_remote.rpc()
    _begin_transition(FOREST_SCENE_PATH, FOREST_SPAWN, "THE OUTSIDE", "Leaving the labyrinth...")

@rpc("authority", "call_remote", "reliable", 7)
func _transition_to_forest_remote() -> void:
    if transitioning:
        return
    _begin_transition(FOREST_SCENE_PATH, FOREST_SPAWN, "THE OUTSIDE", "Leaving the labyrinth...")

func _on_peer_connected(peer_id: int) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_server") or not bool(network.call("is_server")):
        return
    call_deferred("_send_current_map_to_peer", peer_id)

func _send_current_map_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var scene_path: String = scene.scene_file_path
    if scene_path != LABYRINTH_SCENE_PATH and scene_path != FOREST_SCENE_PATH:
        scene_path = LABYRINTH_SCENE_PATH
    _sync_map_remote.rpc_id(peer_id, scene_path)

@rpc("authority", "call_remote", "reliable", 7)
func _sync_map_remote(scene_path: String) -> void:
    if scene_path != LABYRINTH_SCENE_PATH and scene_path != FOREST_SCENE_PATH:
        return
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == scene_path:
        return
    var spawn: Vector3 = FOREST_SPAWN if scene_path == FOREST_SCENE_PATH else LABYRINTH_SPAWN
    var title: String = "SYNCING FOREST" if scene_path == FOREST_SCENE_PATH else "SYNCING LABYRINTH"
    _begin_transition(scene_path, spawn, title, "Matching the host world...")

func _begin_transition(scene_path: String, spawn_position: Vector3, title: String, detail: String) -> void:
    if transitioning:
        return
    transitioning = true
    pending_player_state = _capture_local_player_state()
    _show_loading(title, detail)
    _block_mobile(true)

    var old_player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if old_player != null:
        _lock_player(old_player)

    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    call_deferred("_change_scene_and_restore", scene_path, spawn_position)

func _change_scene_and_restore(scene_path: String, spawn_position: Vector3) -> void:
    progress_bar.value = 18.0
    var change_error: Error = get_tree().change_scene_to_file(scene_path)
    if change_error != OK:
        _fail_transition("Could not load the next map.")
        return

    var player: CharacterBody3D = null
    var world_ready: bool = false
    for frame_index: int in range(48):
        await get_tree().process_frame
        progress_bar.value = minf(88.0, 24.0 + float(frame_index) * 1.5)
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if player != null:
            _lock_player(player)
        var scene: Node = get_tree().current_scene
        if scene != null and scene.scene_file_path == scene_path:
            if scene_path == FOREST_SCENE_PATH:
                world_ready = scene.get_node_or_null("OutsideWorld/ForestGround") != null
            else:
                world_ready = scene.get_node_or_null("LabyrinthExpansion") != null
        if player != null and world_ready:
            break

    if player == null or not world_ready:
        _fail_transition("The map loaded, but world geometry was not ready.")
        return

    _apply_local_player_state(player, pending_player_state)
    player.global_position = spawn_position
    player.velocity = Vector3.ZERO
    player.set("flashlight_panic", 0.0)

    if scene_path == FOREST_SCENE_PATH:
        player.set("darkness_exposure", minf(18.0, float(player.get("darkness_exposure"))))
        var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
        if checkpoint != null and checkpoint.has_method("save_checkpoint"):
            checkpoint.call("save_checkpoint", player, spawn_position, "Forest entrance")
        var forest_objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if forest_objective != null:
            forest_objective.text = "THE OUTSIDE: Find the cabin. Search for fuel before night."
        detail_label.text = "Forest ready. Keep your light close."
    else:
        var labyrinth_objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if labyrinth_objective != null:
            labyrinth_objective.text = "LABYRINTH: Restore all 3 emergency relays. Light keeps the dark away."
        detail_label.text = "Labyrinth synchronized with host."

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

func _capture_local_player_state() -> Dictionary:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return {}
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    return {
        "rotation_y": player.rotation.y,
        "health": float(player.get("health")),
        "hunger": float(player.get("hunger")),
        "thirst": float(player.get("thirst")),
        "stamina": float(player.get("stamina")),
        "flashlight_battery": float(player.get("flashlight_battery")),
        "darkness_exposure": float(player.get("darkness_exposure")),
        "inventory_names": Dictionary(player.get("inventory_names")).duplicate(true),
        "inventory_counts": Dictionary(player.get("inventory_counts")).duplicate(true),
        "flashlight_on": flashlight != null and flashlight.visible,
        "bleeding": float(depth.get("bleeding")) if depth != null else 0.0,
        "infection": float(depth.get("infection")) if depth != null else 0.0
    }

func _apply_local_player_state(player: CharacterBody3D, state: Dictionary) -> void:
    if state.is_empty():
        return
    player.rotation.y = float(state.get("rotation_y", player.rotation.y))
    player.set("health", clampf(float(state.get("health", 100.0)), 1.0, float(player.get("max_health"))))
    player.set("hunger", clampf(float(state.get("hunger", 100.0)), 0.0, float(player.get("max_hunger"))))
    player.set("thirst", clampf(float(state.get("thirst", 100.0)), 0.0, float(player.get("max_thirst"))))
    player.set("stamina", clampf(float(state.get("stamina", 100.0)), 0.0, float(player.get("max_stamina"))))
    player.set("flashlight_battery", clampf(float(state.get("flashlight_battery", 100.0)), 0.0, float(player.get("max_flashlight_battery"))))
    player.set("darkness_exposure", clampf(float(state.get("darkness_exposure", 0.0)), 0.0, 100.0))
    player.set("inventory_names", Dictionary(state.get("inventory_names", {})).duplicate(true))
    player.set("inventory_counts", Dictionary(state.get("inventory_counts", {})).duplicate(true))
    player.set("is_dead", false)

    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if flashlight != null:
        flashlight.visible = bool(state.get("flashlight_on", true)) and float(player.get("flashlight_battery")) > 0.0

    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth != null:
        depth.set("bleeding", clampf(float(state.get("bleeding", 0.0)), 0.0, 100.0))
        depth.set("infection", clampf(float(state.get("infection", 0.0)), 0.0, 100.0))
        depth.set("last_health", float(player.get("health")))
        depth.set("tracked_player_id", int(player.get_instance_id()))

    if player.has_method("_update_inventory_hud"):
        player.call("_update_inventory_hud")
    if player.has_method("_update_survival_hud"):
        player.call("_update_survival_hud")

func _labyrinth_exit_unlocked() -> bool:
    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth == null:
        return true
    var relays: Dictionary = Dictionary(labyrinth.get("active_relays"))
    for relay_id: int in range(3):
        if not bool(relays.get(relay_id, false)):
            return false
    return true

func _lock_player(player: CharacterBody3D) -> void:
    player.velocity = Vector3.ZERO
    player.set_process(false)
    player.set_physics_process(false)
    player.set_process_unhandled_input(false)

func _unlock_player(player: CharacterBody3D) -> void:
    var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online and polish != null and not bool(polish.get("session_started")):
        return
    player.set_process(true)
    player.set_physics_process(true)
    player.set_process_unhandled_input(true)

func _build_loading_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "MapLoadingUI"
    layer.layer = 120
    add_child(layer)

    overlay = ColorRect.new()
    overlay.color = Color(0.003, 0.004, 0.006, 1.0)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    title_label = Label.new()
    title_label.anchor_left = 0.5
    title_label.anchor_top = 0.5
    title_label.anchor_right = 0.5
    title_label.anchor_bottom = 0.5
    title_label.offset_left = -300.0
    title_label.offset_top = -75.0
    title_label.offset_right = 300.0
    title_label.offset_bottom = -20.0
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 34)
    overlay.add_child(title_label)

    detail_label = Label.new()
    detail_label.anchor_left = 0.5
    detail_label.anchor_top = 0.5
    detail_label.anchor_right = 0.5
    detail_label.anchor_bottom = 0.5
    detail_label.offset_left = -300.0
    detail_label.offset_top = -10.0
    detail_label.offset_right = 300.0
    detail_label.offset_bottom = 30.0
    detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    detail_label.add_theme_font_size_override("font_size", 16)
    overlay.add_child(detail_label)

    progress_bar = ProgressBar.new()
    progress_bar.anchor_left = 0.5
    progress_bar.anchor_top = 0.5
    progress_bar.anchor_right = 0.5
    progress_bar.anchor_bottom = 0.5
    progress_bar.offset_left = -180.0
    progress_bar.offset_top = 52.0
    progress_bar.offset_right = 180.0
    progress_bar.offset_bottom = 72.0
    progress_bar.show_percentage = false
    overlay.add_child(progress_bar)

    overlay.visible = false

func _show_loading(title: String, detail: String) -> void:
    overlay.visible = true
    title_label.text = title
    detail_label.text = detail
    progress_bar.value = 6.0

func _hide_loading() -> void:
    overlay.visible = false

func _fail_transition(message: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        _unlock_player(player)
        var objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if objective != null:
            objective.text = "Map transition failed: %s" % message
    _block_mobile(false)
    pending_player_state.clear()
    transitioning = false
    _hide_loading()

func _block_mobile(value: bool) -> void:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile != null and mobile.has_method("set_external_blocked"):
        mobile.call("set_external_blocked", value)

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
