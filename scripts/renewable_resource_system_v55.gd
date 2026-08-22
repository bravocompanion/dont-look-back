extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const MENU_SCENE_PATH: String = "res://scenes/main_menu_ranger.tscn"
const BRANCH_SCRIPT_PATH: String = "res://scripts/forest_branch_pile_v55.gd"
const GATHER_DISTANCE: float = 3.2

const BRANCH_SPECS: Array[Dictionary] = [
    {"id": "branch_a", "position": Vector3(-28.0, 0.0, -118.0)},
    {"id": "branch_b", "position": Vector3(34.0, 0.0, -137.0)},
    {"id": "branch_c", "position": Vector3(-54.0, 0.0, -181.0)},
    {"id": "branch_d", "position": Vector3(53.0, 0.0, -207.0)},
    {"id": "branch_e", "position": Vector3(-66.0, 0.0, -252.0)},
    {"id": "branch_f", "position": Vector3(61.0, 0.0, -273.0)},
    {"id": "branch_g", "position": Vector3(-91.0, 0.0, -319.0)},
    {"id": "branch_h", "position": Vector3(46.0, 0.0, -337.0)}
]

var branch_script: Script
var configured_scene_id: int = 0
var branch_nodes: Dictionary = {}
var respawn_remaining: Dictionary = {}
var gather_claims: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    branch_script = load(BRANCH_SCRIPT_PATH) as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected_v55):
        multiplayer.peer_connected.connect(_on_peer_connected_v55)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path != MENU_SCENE_PATH and _is_authoritative_v55():
        _tick_respawns_v55(delta)

    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        configured_scene_id = 0
        branch_nodes.clear()
        return

    var scene_id: int = int(scene.get_instance_id())
    if configured_scene_id == scene_id:
        return
    configured_scene_id = scene_id
    branch_nodes.clear()
    call_deferred("_configure_forest_v55", scene)

func request_branch_gather(resource_id: String, _world_position: Vector3 = Vector3.ZERO) -> void:
    if resource_id.is_empty():
        return
    if _network_online_v55() and not _is_authoritative_v55():
        _request_branch_gather_v55_remote.rpc_id(1, resource_id)
        return
    _handle_branch_request_v55(_local_peer_id_v55(), resource_id)

func get_save_state() -> Dictionary:
    return {"respawn_remaining": respawn_remaining.duplicate(true)}

func restore_save_state(state: Dictionary) -> void:
    respawn_remaining.clear()
    var remaining_value: Variant = state.get("respawn_remaining", {})
    if remaining_value is Dictionary:
        var restored: Dictionary = Dictionary(remaining_value)
        for key_value: Variant in restored.keys():
            var resource_id: String = str(key_value)
            var remaining: float = maxf(0.0, float(restored.get(key_value, 0.0)))
            if remaining > 0.0:
                respawn_remaining[resource_id] = remaining
    call_deferred("_refresh_all_branch_nodes_v55")

func reset_progress() -> void:
    respawn_remaining.clear()
    gather_claims.clear()
    call_deferred("_refresh_all_branch_nodes_v55")

func _configure_forest_v55(scene: Node) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if scene == null or not is_instance_valid(scene) or get_tree().current_scene != scene:
        return
    var outside_root: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if outside_root == null or branch_script == null:
        return

    for data: Dictionary in BRANCH_SPECS:
        var resource_id: String = str(data.get("id", ""))
        if resource_id.is_empty():
            continue
        var node_name: String = "RenewableBranch_%s" % resource_id
        var branch: StaticBody3D = outside_root.get_node_or_null(NodePath(node_name)) as StaticBody3D
        if branch == null:
            branch = StaticBody3D.new()
            branch.name = StringName(node_name)
            branch.set_script(branch_script)
            branch.set("resource_id", resource_id)
            branch.position = Vector3(data.get("position", Vector3.ZERO))
            outside_root.add_child(branch)
        branch_nodes[resource_id] = branch
        _apply_branch_availability_v55(resource_id)

func _tick_respawns_v55(delta: float) -> void:
    if delta <= 0.0 or respawn_remaining.is_empty():
        return
    var ready_ids: Array[String] = []
    for key_value: Variant in respawn_remaining.keys():
        var resource_id: String = str(key_value)
        var remaining: float = maxf(0.0, float(respawn_remaining.get(resource_id, 0.0)) - delta)
        if remaining <= 0.0:
            ready_ids.append(resource_id)
        else:
            respawn_remaining[resource_id] = remaining
    for resource_id: String in ready_ids:
        respawn_remaining.erase(resource_id)
        gather_claims.erase(resource_id)
        _broadcast_branch_state_v55(resource_id, true)

func _handle_branch_request_v55(peer_id: int, resource_id: String) -> void:
    if not _is_authoritative_v55() or peer_id <= 0:
        return
    if float(respawn_remaining.get(resource_id, 0.0)) > 0.0:
        _message_peer_v55(peer_id, "Those fallen branches have already been gathered. Search farther into the forest.")
        return
    if int(gather_claims.get(resource_id, 0)) != 0:
        _message_peer_v55(peer_id, "Another survivor is already gathering those branches.")
        return

    var branch: Node3D = branch_nodes.get(resource_id, null) as Node3D
    if branch == null or not is_instance_valid(branch) or not branch.visible:
        return
    var peer_position_value: Variant = _peer_position_v55(peer_id)
    if not (peer_position_value is Vector3):
        return
    var peer_position: Vector3 = peer_position_value
    if peer_position.distance_to(branch.global_position) > GATHER_DISTANCE:
        _message_peer_v55(peer_id, "Move closer to the fallen branches.")
        return

    var wood_yield: int = _wood_yield_v55()
    if not _network_online_v55() or peer_id == _local_peer_id_v55():
        var player: CharacterBody3D = _local_player_v55()
        if not _grant_wood_v55(player, wood_yield):
            _message_peer_v55(peer_id, "Wood carry limit reached. Store supplies before gathering more.")
            return
        _complete_branch_gather_v55(resource_id, peer_id, wood_yield)
        return

    gather_claims[resource_id] = peer_id
    _attempt_branch_grant_v55_remote.rpc_id(peer_id, resource_id, wood_yield)

func _complete_branch_gather_v55(resource_id: String, peer_id: int, wood_yield: int) -> void:
    gather_claims.erase(resource_id)
    respawn_remaining[resource_id] = _branch_respawn_seconds_v55()
    _broadcast_branch_state_v55(resource_id, false)
    _message_peer_v55(peer_id, "GATHER: collected Wood x%d. Fallen branches regrow slowly; keep moving between gathering sites." % wood_yield)
    _request_autosave_v55("Renewable wood gathered")

func _branch_respawn_seconds_v55() -> float:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var full_day_seconds: float = maxf(60.0, float(outside.get("full_day_seconds"))) if outside != null else 720.0
    var game_hours: float = 6.0 if _party_size_v55() >= 3 else 8.0
    return full_day_seconds * game_hours / 24.0

func _wood_yield_v55() -> int:
    return 3 if _party_size_v55() >= 3 else 2

func _party_size_v55() -> int:
    if not _network_online_v55():
        return 1
    return maxi(1, 1 + multiplayer.get_peers().size())

func _grant_wood_v55(player: CharacterBody3D, amount: int) -> bool:
    if player == null or amount <= 0:
        return false
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry != null and carry.has_method("grant_item"):
        return bool(carry.call("grant_item", player, "wood", "Wood", amount))
    if not player.has_method("add_item"):
        return false
    var granted: int = 0
    for _index: int in range(amount):
        if not bool(player.call("add_item", "wood", "Wood")):
            for _refund: int in range(granted):
                if player.has_method("remove_item"):
                    player.call("remove_item", "wood")
            return false
        granted += 1
    return true

func _broadcast_branch_state_v55(resource_id: String, available: bool) -> void:
    if _network_online_v55():
        _set_branch_state_v55_remote.rpc(resource_id, available)
    else:
        _set_branch_state_v55_remote(resource_id, available)

@rpc("any_peer", "call_remote", "reliable", 46)
func _request_branch_gather_v55_remote(resource_id: String) -> void:
    if not _is_authoritative_v55():
        return
    _handle_branch_request_v55(multiplayer.get_remote_sender_id(), resource_id)

@rpc("authority", "call_remote", "reliable", 47)
func _attempt_branch_grant_v55_remote(resource_id: String, wood_yield: int) -> void:
    var success: bool = _grant_wood_v55(_local_player_v55(), clampi(wood_yield, 1, 4))
    if not success:
        var player: CharacterBody3D = _local_player_v55()
        if player != null:
            var objective: Label = player.get_node_or_null("HUD/Objective") as Label
            if objective != null:
                objective.text = "Wood carry limit reached. The branches remain available."
    _complete_branch_grant_v55_remote.rpc_id(1, resource_id, success, wood_yield)

@rpc("any_peer", "call_remote", "reliable", 48)
func _complete_branch_grant_v55_remote(resource_id: String, success: bool, wood_yield: int) -> void:
    if not _is_authoritative_v55():
        return
    var sender_peer_id: int = multiplayer.get_remote_sender_id()
    if int(gather_claims.get(resource_id, 0)) != sender_peer_id:
        return
    gather_claims.erase(resource_id)
    if success:
        _complete_branch_gather_v55(resource_id, sender_peer_id, clampi(wood_yield, 1, 4))

@rpc("authority", "call_local", "reliable", 49)
func _set_branch_state_v55_remote(resource_id: String, available: bool) -> void:
    if available:
        respawn_remaining.erase(resource_id)
    elif _network_online_v55() and not _is_authoritative_v55():
        # Clients keep an unavailable visual sentinel across scene changes.
        # The HOST owns the real countdown and clears this marker when ready.
        respawn_remaining[resource_id] = 999999.0
    var branch: Node = branch_nodes.get(resource_id, null) as Node
    if branch != null and is_instance_valid(branch) and branch.has_method("set_available_v55"):
        branch.call("set_available_v55", available)

func _apply_branch_availability_v55(resource_id: String) -> void:
    var branch: Node = branch_nodes.get(resource_id, null) as Node
    if branch == null or not is_instance_valid(branch) or not branch.has_method("set_available_v55"):
        return
    branch.call("set_available_v55", float(respawn_remaining.get(resource_id, 0.0)) <= 0.0)

func _refresh_all_branch_nodes_v55() -> void:
    for resource_id_value: Variant in branch_nodes.keys():
        _apply_branch_availability_v55(str(resource_id_value))

func _on_peer_connected_v55(peer_id: int) -> void:
    if not _is_authoritative_v55() or peer_id <= 1:
        return
    call_deferred("_send_branch_state_to_peer_v55", peer_id)

func _send_branch_state_to_peer_v55(peer_id: int) -> void:
    await get_tree().process_frame
    if not _is_authoritative_v55() or not _network_online_v55():
        return
    for data: Dictionary in BRANCH_SPECS:
        var resource_id: String = str(data.get("id", ""))
        var available: bool = float(respawn_remaining.get(resource_id, 0.0)) <= 0.0
        _set_branch_state_v55_remote.rpc_id(peer_id, resource_id, available)

func _peer_position_v55(peer_id: int) -> Variant:
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if not _network_online_v55() or player.get_multiplayer_authority() == peer_id:
            return player.global_position

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        var targets_value: Variant = network.get("remote_targets")
        if targets_value is Dictionary:
            var state_value: Variant = Dictionary(targets_value).get(peer_id, null)
            if state_value is Dictionary:
                var transform_value: Variant = Dictionary(state_value).get("transform", null)
                if transform_value is Transform3D:
                    var peer_transform: Transform3D = transform_value
                    return peer_transform.origin
    return null

func _local_player_v55() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
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

func _local_peer_id_v55() -> int:
    return multiplayer.get_unique_id() if _network_online_v55() else 1

func _network_online_v55() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative_v55() -> bool:
    if not _network_online_v55():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _message_peer_v55(peer_id: int, text: String) -> void:
    if not _network_online_v55() or peer_id == _local_peer_id_v55():
        var player: CharacterBody3D = _local_player_v55()
        if player != null:
            var objective: Label = player.get_node_or_null("HUD/Objective") as Label
            if objective != null:
                objective.text = text
        return
    _branch_message_v55_remote.rpc_id(peer_id, text)

@rpc("authority", "call_remote", "reliable", 50)
func _branch_message_v55_remote(text: String) -> void:
    var player: CharacterBody3D = _local_player_v55()
    if player != null:
        var objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if objective != null:
            objective.text = text

func _request_autosave_v55(reason: String) -> void:
    var save: Node = get_node_or_null("/root/SaveSystem")
    if save != null and save.has_method("request_autosave"):
        save.call("request_autosave", reason)
