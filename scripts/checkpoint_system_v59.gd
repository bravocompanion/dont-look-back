extends "res://scripts/checkpoint_system.gd"

# v0.59 checkpoint semantics: a checkpoint is a time snapshot, not only a
# respawn transform. Shared world/progression/finite-loot state rolls back with
# each survivor's own local checkpoint inventory/stats after a wipe.

const FOREST_SCENE_V59: String = "res://scenes/forest.tscn"
const MINE_SCENE_V59: String = "res://scenes/mine.tscn"
const LABYRINTH_SCENE_V59: String = "res://scenes/main.tscn"
const FACILITY_SCENE_V59: String = "res://scenes/research_facility.tscn"

var shared_snapshot_v59: Dictionary = {}
var checkpoint_scene_path_v59: String = ""
var wipe_restore_pending_v59: bool = false
var wipe_source_scene_id_v59: int = 0
var restore_running_v59: bool = false

func _ready() -> void:
    super._ready()
    if not multiplayer.peer_connected.is_connected(_on_peer_connected_v59):
        multiplayer.peer_connected.connect(_on_peer_connected_v59)

func save_checkpoint(player: CharacterBody3D, world_position: Vector3, label: String) -> void:
    if player == null:
        return
    if _network_online_v59() and not _is_host_v59():
        return

    super.save_checkpoint(player, world_position, label)
    checkpoint_scene_path_v59 = _current_scene_path_v59()

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("build_checkpoint_shared_snapshot"):
        var snapshot_value: Variant = save_system.call("build_checkpoint_shared_snapshot", player)
        if snapshot_value is Dictionary:
            shared_snapshot_v59 = Dictionary(snapshot_value).duplicate(true)

    if _network_online_v59() and _is_host_v59():
        _capture_checkpoint_remote_v59.rpc(
            checkpoint_position,
            checkpoint_rotation_y,
            checkpoint_name,
            checkpoint_scene_path_v59,
            shared_snapshot_v59.duplicate(true)
        )

func clear_checkpoint() -> void:
    super.clear_checkpoint()
    shared_snapshot_v59.clear()
    checkpoint_scene_path_v59 = ""
    wipe_restore_pending_v59 = false
    wipe_source_scene_id_v59 = 0
    restore_running_v59 = false

func prepare_team_wipe_restore_v59() -> bool:
    if not checkpoint_active or shared_snapshot_v59.is_empty():
        return false
    var scene: Node = get_tree().current_scene
    if scene == null:
        return false

    wipe_restore_pending_v59 = true
    restore_pending = false
    wipe_source_scene_id_v59 = int(scene.get_instance_id())

    var consumable: Node = get_node_or_null("/root/ConsumableActionSystem")
    if consumable != null and consumable.has_method("cancel_current_action"):
        consumable.call("cancel_current_action", "checkpoint wipe")
    return true

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D

    # Solo death uses Player's normal restart/reload path. Arm the same snapshot
    # restore before that scene reload occurs.
    if (
        checkpoint_active
        and not wipe_restore_pending_v59
        and not restore_running_v59
        and player != null
        and bool(player.get("is_dead"))
    ):
        prepare_team_wipe_restore_v59()

    if not wipe_restore_pending_v59 or restore_running_v59:
        last_scene_id = scene_id
        return

    # Wait until the old scene has actually been replaced.
    if scene_id == wipe_source_scene_id_v59:
        return

    if not checkpoint_scene_path_v59.is_empty() and scene.scene_file_path != checkpoint_scene_path_v59:
        wipe_restore_pending_v59 = false
        wipe_source_scene_id_v59 = 0
        last_scene_id = scene_id
        return

    if player == null:
        return

    wipe_restore_pending_v59 = false
    restore_running_v59 = true
    last_scene_id = scene_id
    call_deferred("_restore_snapshot_after_reload_v59", player, scene_id)

@rpc("authority", "call_remote", "reliable", 62)
func _capture_checkpoint_remote_v59(
    world_position: Vector3,
    rotation_y: float,
    label: String,
    scene_path: String,
    shared_snapshot: Dictionary
) -> void:
    if _is_host_v59():
        return
    call_deferred(
        "_capture_remote_checkpoint_when_ready_v59",
        world_position,
        rotation_y,
        label,
        scene_path,
        shared_snapshot.duplicate(true)
    )

func _capture_remote_checkpoint_when_ready_v59(
    world_position: Vector3,
    rotation_y: float,
    label: String,
    scene_path: String,
    shared_snapshot: Dictionary
) -> void:
    var player: CharacterBody3D = null
    for _frame_index: int in range(240):
        await get_tree().process_frame
        var scene: Node = get_tree().current_scene
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if scene != null and player != null and scene.scene_file_path == scene_path:
            break
    if player == null:
        return

    _capture_local_checkpoint_v59(player, world_position, rotation_y, label)
    checkpoint_scene_path_v59 = scene_path
    shared_snapshot_v59 = shared_snapshot.duplicate(true)

func _capture_local_checkpoint_v59(
    player: CharacterBody3D,
    world_position: Vector3,
    rotation_y: float,
    label: String
) -> void:
    checkpoint_active = true
    checkpoint_position = world_position
    checkpoint_rotation_y = rotation_y
    checkpoint_name = label
    checkpoint_state = {
        "health": float(player.get("health")),
        "hunger": float(player.get("hunger")),
        "thirst": float(player.get("thirst")),
        "stamina": float(player.get("stamina")),
        "flashlight_battery": float(player.get("flashlight_battery")),
        "darkness_exposure": float(player.get("darkness_exposure")),
        "inventory_names": Dictionary(player.get("inventory_names")).duplicate(true),
        "inventory_counts": Dictionary(player.get("inventory_counts")).duplicate(true),
        "flashlight_on": _is_flashlight_on(player)
    }

    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth != null:
        checkpoint_state["bleeding"] = float(depth.get("bleeding"))
        checkpoint_state["infection"] = float(depth.get("infection"))

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        checkpoint_state["cold_exposure"] = float(outside.get("cold_exposure"))

func _restore_snapshot_after_reload_v59(player: CharacterBody3D, scene_id: int) -> void:
    var ready: bool = false
    for _frame_index: int in range(240):
        await get_tree().process_frame
        var scene: Node = get_tree().current_scene
        if scene == null or int(scene.get_instance_id()) != scene_id:
            continue
        if not is_instance_valid(player):
            player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if player != null and _scene_ready_v59(scene):
            ready = true
            break

    if not ready or player == null or not is_instance_valid(player):
        restore_running_v59 = false
        return

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("restore_checkpoint_shared_snapshot"):
        save_system.call("restore_checkpoint_shared_snapshot", shared_snapshot_v59.duplicate(true))

    # Inherited restore applies this peer's own checkpoint inventory/stats and
    # the shared respawn transform after the world rollback is complete.
    _restore_player(player)
    restore_running_v59 = false
    wipe_source_scene_id_v59 = 0

func _scene_ready_v59(scene: Node) -> bool:
    match scene.scene_file_path:
        FOREST_SCENE_V59:
            return scene.get_node_or_null("OutsideWorld/ForestGround") != null
        MINE_SCENE_V59:
            return scene.get_node_or_null("MineWorld/Floor") != null
        LABYRINTH_SCENE_V59:
            return scene.get_node_or_null("LabyrinthExpansion") != null and scene.get_node_or_null("Arc1Expansion") != null
        FACILITY_SCENE_V59:
            return scene.get_node_or_null("FacilityWorld/Floor") != null
    return false

func _on_peer_connected_v59(peer_id: int) -> void:
    if not _is_host_v59() or peer_id <= 1 or not checkpoint_active or shared_snapshot_v59.is_empty():
        return
    call_deferred("_send_checkpoint_to_peer_v59", peer_id)

func _send_checkpoint_to_peer_v59(peer_id: int) -> void:
    await get_tree().create_timer(0.75).timeout
    if not _is_host_v59() or not checkpoint_active or shared_snapshot_v59.is_empty():
        return
    _capture_checkpoint_remote_v59.rpc_id(
        peer_id,
        checkpoint_position,
        checkpoint_rotation_y,
        checkpoint_name,
        checkpoint_scene_path_v59,
        shared_snapshot_v59.duplicate(true)
    )

func _current_scene_path_v59() -> String:
    var scene: Node = get_tree().current_scene
    return scene.scene_file_path if scene != null else ""

func _network_online_v59() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host_v59() -> bool:
    if not _network_online_v59():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))
