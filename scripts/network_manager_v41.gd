extends "res://scripts/network_manager.gd"

const LABYRINTH_SCENE_PATH_V57: String = "res://scenes/main.tscn"
const FOREST_SCENE_PATH_V57: String = "res://scenes/forest.tscn"
const RELAY_INTERACTION_DISTANCE_V57: float = 3.8
const PICKUP_INTERACTION_DISTANCE_V57: float = 3.8
const MAX_REMOTE_STEP_DISTANCE_V57: float = 8.0
const ALLOWED_SHELTER_ACTIONS_V57: Array[String] = [
    "generator_fuel",
    "campfire_bundle",
    "campfire_wood"
]

func _unhandled_input(event: InputEvent) -> void:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock != null and input_lock.has_method("is_locked") and bool(input_lock.call("is_locked")):
        return

    # Compatibility fallback when GameplayInputLock is unavailable.
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
        return
    var status_menu: Node = get_node_or_null("/root/FieldStatusMenuSystem")
    if status_menu != null and status_menu.has_method("is_open") and bool(status_menu.call("is_open")):
        return
    var stash: Node = get_node_or_null("/root/StashMenuSystem")
    if stash != null and stash.has_method("is_open") and bool(stash.call("is_open")):
        return
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return
    super._unhandled_input(event)

@rpc("any_peer", "call_remote", "unreliable", 0)
func _submit_state(player_transform: Transform3D, camera_pitch: float, flashlight_on: bool, stats: Dictionary) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    if not _validate_remote_transform_v57(sender_id, player_transform):
        return

    var safe_pitch: float = clampf(camera_pitch, -1.55, 1.55)
    var safe_stats: Dictionary = _sanitize_remote_stats_v57(stats)
    _apply_remote_state(sender_id, player_transform, safe_pitch, flashlight_on, safe_stats)
    _receive_state.rpc(sender_id, player_transform, safe_pitch, flashlight_on, safe_stats)

@rpc("any_peer", "call_remote", "reliable", 1)
func _request_relay(relay_id: int) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1 or relay_id < 0 or relay_id > 2:
        return

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH_V57:
        return
    var relay: Node3D = scene.get_node_or_null("LabyrinthExpansion/EmergencyRelay%d" % (relay_id + 1)) as Node3D
    if relay == null or not _peer_is_near_node_v57(sender_id, relay, RELAY_INTERACTION_DISTANCE_V57):
        return

    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth == null:
        return
    var relays: Dictionary = Dictionary(labyrinth.get("active_relays"))
    if bool(relays.get(relay_id, false)):
        return
    _server_activate_relay(relay_id)

@rpc("any_peer", "call_remote", "reliable", 1)
func _request_shelter(action: String) -> void:
    if not hosting or action not in ALLOWED_SHELTER_ACTIONS_V57:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH_V57:
        return
    var peer_position: Variant = _peer_position_v57(sender_id)
    if peer_position == null:
        return

    # v0.57 first authority pass: shelter requests are accepted only from the
    # physical Ranger Yard. Inventory ownership remains a separate authoritative
    # protocol task because legacy clients currently consume items locally.
    var safe_zone: Node = get_node_or_null("/root/RangerSafeZone")
    if safe_zone == null or not safe_zone.has_method("is_position_safe"):
        return
    if not bool(safe_zone.call("is_position_safe", peer_position)):
        return
    _server_shelter_action(action)

@rpc("any_peer", "call_remote", "reliable", 1)
func _request_pickup(pickup_path: String) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return

    var pickup: Node = get_node_or_null(NodePath(pickup_path))
    var accepted: bool = _validate_pickup_request_v57(sender_id, pickup_path, pickup)
    if accepted:
        claimed_pickups[pickup_path] = true
        _despawn_pickup.rpc(pickup_path, sender_id)
    _pickup_result.rpc_id(sender_id, pickup_path, accepted)

func _validate_pickup_request_v57(sender_id: int, pickup_path: String, pickup: Node) -> bool:
    if pickup_path.is_empty() or bool(claimed_pickups.get(pickup_path, false)):
        return false
    if pickup == null or not is_instance_valid(pickup) or not (pickup is Node3D):
        return false
    if not pickup.has_method("complete_network_pickup"):
        return false

    var scene: Node = get_tree().current_scene
    if scene == null or (pickup != scene and not scene.is_ancestor_of(pickup)):
        return false
    return _peer_is_near_node_v57(sender_id, pickup as Node3D, PICKUP_INTERACTION_DISTANCE_V57)

func _peer_is_near_node_v57(peer_id: int, target: Node3D, max_distance: float) -> bool:
    if target == null or not is_instance_valid(target):
        return false
    var peer_position: Variant = _peer_position_v57(peer_id)
    if peer_position == null:
        return false
    return (peer_position as Vector3).distance_to(target.global_position) <= max_distance

func _peer_position_v57(peer_id: int) -> Variant:
    if peer_id == 1:
        var local_player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        return local_player.global_position if local_player != null else null

    var target_variant: Variant = remote_targets.get(peer_id)
    if target_variant == null:
        return null
    var target: Dictionary = Dictionary(target_variant)
    var player_transform: Variant = target.get("transform")
    if player_transform is Transform3D:
        return (player_transform as Transform3D).origin
    return null

func _validate_remote_transform_v57(peer_id: int, player_transform: Transform3D) -> bool:
    if not player_transform.origin.is_finite():
        return false
    var existing_variant: Variant = remote_targets.get(peer_id)
    if existing_variant == null:
        return true
    var existing: Dictionary = Dictionary(existing_variant)
    var previous_variant: Variant = existing.get("transform")
    if not (previous_variant is Transform3D):
        return true
    var previous: Transform3D = previous_variant as Transform3D
    if not previous.origin.is_finite():
        return true
    return previous.origin.distance_to(player_transform.origin) <= MAX_REMOTE_STEP_DISTANCE_V57

func _sanitize_remote_stats_v57(stats: Dictionary) -> Dictionary:
    return {
        "health": clampf(float(stats.get("health", 100.0)), 0.0, 100.0),
        "hunger": clampf(float(stats.get("hunger", 100.0)), 0.0, 100.0),
        "thirst": clampf(float(stats.get("thirst", 100.0)), 0.0, 100.0),
        "stamina": clampf(float(stats.get("stamina", 100.0)), 0.0, 100.0),
        "battery": clampf(float(stats.get("battery", 100.0)), 0.0, 100.0)
    }
