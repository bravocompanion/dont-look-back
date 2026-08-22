extends "res://scripts/network_manager_v41.gd"

# v0.60 shelter authority foundation.
#
# Normal inventory changes still originate from gameplay on each peer, but every
# successful add/remove is mirrored to the host with an ordered revision. Shared
# shelter mutations (generator fuel/repair and campfire fuel) are then decided,
# consumed, and applied by the host. Clients never pre-consume the resource.
#
# This closes duplicate/race-prone shelter transactions for normal clients. It
# is not competitive anti-cheat yet because the first remote inventory snapshot
# is still supplied by that peer.

const FOREST_SCENE_PATH_V60: String = "res://scenes/forest.tscn"
const SHELTER_INTERACTION_DISTANCE_V60: float = 4.2
const SHELTER_RPC_CHANNEL_V60: int = 63
const SHELTER_ACTION_REQUIREMENTS_V60: Dictionary = {
    "generator_fuel": {"generator_fuel": 1},
    "campfire_bundle": {"firewood_bundle": 1},
    "campfire_wood": {"wood": 1},
    "generator_repair": {"scrap": 2, "electronics": 1}
}

var local_inventory_revision_v60: int = 0
var remote_inventory_revision_v60: Dictionary = {}
var remote_inventory_counts_v60: Dictionary = {}
var remote_inventory_names_v60: Dictionary = {}
var inventory_resync_requested_v60: Dictionary = {}
var shelter_request_nonce_v60: int = 0
var shelter_pending_actions_v60: Dictionary = {}

func disconnect_game(show_message: bool = true) -> void:
    local_inventory_revision_v60 = 0
    remote_inventory_revision_v60.clear()
    remote_inventory_counts_v60.clear()
    remote_inventory_names_v60.clear()
    inventory_resync_requested_v60.clear()
    shelter_request_nonce_v60 = 0
    shelter_pending_actions_v60.clear()
    super.disconnect_game(show_message)

func _on_connected_to_server() -> void:
    super._on_connected_to_server()
    local_inventory_revision_v60 = 0
    call_deferred("_send_inventory_snapshot_when_ready_v60")

func _on_peer_connected(peer_id: int) -> void:
    if hosting and peer_id > 1:
        remote_inventory_revision_v60.erase(peer_id)
        remote_inventory_counts_v60.erase(peer_id)
        remote_inventory_names_v60.erase(peer_id)
        inventory_resync_requested_v60.erase(peer_id)
    super._on_peer_connected(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
    remote_inventory_revision_v60.erase(peer_id)
    remote_inventory_counts_v60.erase(peer_id)
    remote_inventory_names_v60.erase(peer_id)
    inventory_resync_requested_v60.erase(peer_id)
    super._on_peer_disconnected(peer_id)

func notify_local_inventory_delta_v60(item_id: String, delta: int, display_name: String = "") -> void:
    if not online or hosting:
        return
    if item_id.is_empty() or (delta != 1 and delta != -1):
        return
    local_inventory_revision_v60 += 1
    _report_inventory_delta_v60.rpc_id(
        1,
        item_id,
        delta,
        display_name.left(96),
        local_inventory_revision_v60
    )

func request_shared_shelter_action(action: String) -> void:
    if not online:
        return
    if action not in SHELTER_ACTION_REQUIREMENTS_V60:
        return

    if hosting:
        _handle_host_shelter_transaction_v60(1, action, 0, 0)
        return

    if shelter_pending_actions_v60.has(action):
        _objective("Shelter request already pending.")
        return

    shelter_request_nonce_v60 = (shelter_request_nonce_v60 + 1) & 0x7fffffff
    if shelter_request_nonce_v60 <= 0:
        shelter_request_nonce_v60 = 1
    shelter_pending_actions_v60[action] = shelter_request_nonce_v60
    _request_shelter_transaction_v60.rpc_id(
        1,
        action,
        shelter_request_nonce_v60,
        local_inventory_revision_v60
    )
    _objective("Shelter request sent to host...")

# Disable the legacy v0.57 RPC path. v0.60 clients must use the ordered
# transaction protocol below, otherwise resource ownership is not validated.
@rpc("any_peer", "call_remote", "reliable", 1)
func _request_shelter(_action: String) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id > 1:
        _shelter_feedback_v60.rpc_id(sender_id, "Shelter request rejected: inventory authority sync required.")

@rpc("any_peer", "call_remote", "reliable", 63)
func _receive_inventory_snapshot_v60(counts: Dictionary, names: Dictionary, revision: int) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return

    var existing: bool = remote_inventory_counts_v60.has(sender_id)
    var resync_allowed: bool = bool(inventory_resync_requested_v60.get(sender_id, false))
    if existing and not resync_allowed:
        return

    remote_inventory_counts_v60[sender_id] = _sanitize_inventory_counts_v60(counts)
    remote_inventory_names_v60[sender_id] = _sanitize_inventory_names_v60(names)
    remote_inventory_revision_v60[sender_id] = maxi(0, revision)
    inventory_resync_requested_v60.erase(sender_id)

@rpc("any_peer", "call_remote", "reliable", 63)
func _report_inventory_delta_v60(item_id: String, delta: int, display_name: String, revision: int) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1 or item_id.is_empty() or item_id.length() > 96 or (delta != 1 and delta != -1):
        return

    if not remote_inventory_counts_v60.has(sender_id):
        _request_inventory_resync_for_peer_v60(sender_id)
        return

    var previous_revision: int = int(remote_inventory_revision_v60.get(sender_id, -1))
    if revision != previous_revision + 1:
        _request_inventory_resync_for_peer_v60(sender_id)
        return

    var counts: Dictionary = Dictionary(remote_inventory_counts_v60.get(sender_id, {})).duplicate(true)
    var names: Dictionary = Dictionary(remote_inventory_names_v60.get(sender_id, {})).duplicate(true)
    var current: int = clampi(int(counts.get(item_id, 0)), 0, 999)
    var next_count: int = clampi(current + delta, 0, 999)

    # A removal from zero is inconsistent with the host mirror. Resync rather
    # than accepting negative inventory or silently desynchronizing.
    if delta < 0 and current <= 0:
        _request_inventory_resync_for_peer_v60(sender_id)
        return

    if next_count <= 0:
        counts.erase(item_id)
        names.erase(item_id)
    else:
        counts[item_id] = next_count
        if not display_name.is_empty():
            names[item_id] = display_name.left(96)

    remote_inventory_counts_v60[sender_id] = counts
    remote_inventory_names_v60[sender_id] = names
    remote_inventory_revision_v60[sender_id] = revision

@rpc("authority", "call_remote", "reliable", 63)
func _request_inventory_snapshot_v60() -> void:
    call_deferred("_send_inventory_snapshot_when_ready_v60")

@rpc("any_peer", "call_remote", "reliable", 63)
func _request_shelter_transaction_v60(action: String, nonce: int, inventory_revision: int) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1 or action not in SHELTER_ACTION_REQUIREMENTS_V60:
        return

    if not remote_inventory_counts_v60.has(sender_id):
        _request_inventory_resync_for_peer_v60(sender_id)
        _finish_shelter_transaction_v60(sender_id, action, nonce, false, "Inventory sync pending. Try again after the host resyncs your pack.")
        return

    if inventory_revision != int(remote_inventory_revision_v60.get(sender_id, -1)):
        _request_inventory_resync_for_peer_v60(sender_id)
        _finish_shelter_transaction_v60(sender_id, action, nonce, false, "Inventory changed during the request. Host requested a resync.")
        return

    _handle_host_shelter_transaction_v60(sender_id, action, nonce, inventory_revision)

@rpc("authority", "call_remote", "reliable", 63)
func _shelter_transaction_result_v60(
    action: String,
    nonce: int,
    accepted: bool,
    item_counts: Dictionary,
    authoritative_revision: int,
    message: String
) -> void:
    var expected_nonce: int = int(shelter_pending_actions_v60.get(action, -1))
    if expected_nonce < 0 or nonce != expected_nonce:
        return
    shelter_pending_actions_v60.erase(action)

    local_inventory_revision_v60 = maxi(local_inventory_revision_v60, authoritative_revision)
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        _apply_transaction_item_counts_v60(player, item_counts)
    _objective(message)

    if accepted:
        var shelter: Node = get_node_or_null("/root/ShelterSystem")
        if shelter != null:
            _refresh_shelter(shelter)

@rpc("authority", "call_remote", "reliable", 63)
func _shelter_feedback_v60(message: String) -> void:
    _objective(message)

func _handle_host_shelter_transaction_v60(peer_id: int, action: String, nonce: int, inventory_revision: int) -> void:
    if not _peer_can_use_shelter_target_v60(peer_id, action):
        _finish_shelter_transaction_v60(peer_id, action, nonce, false, "Move closer to the shelter equipment before using it.")
        return

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        _finish_shelter_transaction_v60(peer_id, action, nonce, false, "Shelter system is unavailable.")
        return

    if not _shelter_action_state_valid_v60(shelter, action):
        _finish_shelter_transaction_v60(peer_id, action, nonce, false, _invalid_shelter_state_message_v60(shelter, action))
        return

    var requirement: Dictionary = Dictionary(SHELTER_ACTION_REQUIREMENTS_V60[action])
    var counts: Dictionary = _inventory_counts_for_peer_v60(peer_id)
    if not _inventory_has_requirement_v60(counts, requirement):
        _finish_shelter_transaction_v60(peer_id, action, nonce, false, _missing_shelter_resource_message_v60(action))
        return

    if peer_id == 1:
        var local_player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if local_player == null or not _consume_local_requirement_v60(local_player, requirement):
            _finish_shelter_transaction_v60(peer_id, action, nonce, false, _missing_shelter_resource_message_v60(action))
            return
    else:
        _consume_remote_requirement_v60(peer_id, requirement)
        inventory_revision = int(remote_inventory_revision_v60.get(peer_id, inventory_revision)) + 1
        remote_inventory_revision_v60[peer_id] = inventory_revision

    _apply_shelter_world_action_v60(shelter, action)
    _refresh_shelter(shelter)
    if shelter.has_method("_broadcast_generator_condition_v55"):
        shelter.call("_broadcast_generator_condition_v55")
    _report_shelter_noise_v60(action)
    _broadcast_world_state()

    var save: Node = get_node_or_null("/root/SaveSystem")
    if save != null and save.has_method("request_autosave"):
        save.call("request_autosave", "Shelter resource transaction")

    _finish_shelter_transaction_v60(peer_id, action, nonce, true, _accepted_shelter_message_v60(action), inventory_revision)

func _finish_shelter_transaction_v60(
    peer_id: int,
    action: String,
    nonce: int,
    accepted: bool,
    message: String,
    authoritative_revision: int = -1
) -> void:
    var requirement: Dictionary = Dictionary(SHELTER_ACTION_REQUIREMENTS_V60.get(action, {}))
    var touched: Dictionary = {}
    var counts: Dictionary = _inventory_counts_for_peer_v60(peer_id)
    for item_variant: Variant in requirement.keys():
        var item_id: String = str(item_variant)
        touched[item_id] = clampi(int(counts.get(item_id, 0)), 0, 999)

    if peer_id == 1:
        _objective(message)
        return

    var revision: int = authoritative_revision
    if revision < 0:
        revision = int(remote_inventory_revision_v60.get(peer_id, 0))
    _shelter_transaction_result_v60.rpc_id(peer_id, action, nonce, accepted, touched, revision, message)

func _send_inventory_snapshot_when_ready_v60() -> void:
    if not online or hosting:
        return
    var player: CharacterBody3D = null
    for _frame_index: int in range(240):
        await get_tree().process_frame
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if player != null:
            break
    if player == null:
        return

    var counts: Dictionary = Dictionary(player.get("inventory_counts")).duplicate(true)
    var names: Dictionary = Dictionary(player.get("inventory_names")).duplicate(true)
    _receive_inventory_snapshot_v60.rpc_id(1, counts, names, local_inventory_revision_v60)

func _request_inventory_resync_for_peer_v60(peer_id: int) -> void:
    if peer_id <= 1 or not hosting:
        return
    inventory_resync_requested_v60[peer_id] = true
    _request_inventory_snapshot_v60.rpc_id(peer_id)

func _inventory_counts_for_peer_v60(peer_id: int) -> Dictionary:
    if peer_id == 1:
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        return Dictionary(player.get("inventory_counts")).duplicate(true) if player != null else {}
    return Dictionary(remote_inventory_counts_v60.get(peer_id, {})).duplicate(true)

func _inventory_has_requirement_v60(counts: Dictionary, requirement: Dictionary) -> bool:
    for item_variant: Variant in requirement.keys():
        var item_id: String = str(item_variant)
        if int(counts.get(item_id, 0)) < int(requirement.get(item_variant, 0)):
            return false
    return true

func _consume_local_requirement_v60(player: CharacterBody3D, requirement: Dictionary) -> bool:
    if player == null or not player.has_method("remove_item"):
        return false
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    if not _inventory_has_requirement_v60(counts, requirement):
        return false
    for item_variant: Variant in requirement.keys():
        var item_id: String = str(item_variant)
        for _index: int in range(int(requirement.get(item_variant, 0))):
            if not bool(player.call("remove_item", item_id)):
                return false
    return true

func _consume_remote_requirement_v60(peer_id: int, requirement: Dictionary) -> void:
    var counts: Dictionary = Dictionary(remote_inventory_counts_v60.get(peer_id, {})).duplicate(true)
    var names: Dictionary = Dictionary(remote_inventory_names_v60.get(peer_id, {})).duplicate(true)
    for item_variant: Variant in requirement.keys():
        var item_id: String = str(item_variant)
        var remaining: int = maxi(0, int(counts.get(item_id, 0)) - int(requirement.get(item_variant, 0)))
        if remaining <= 0:
            counts.erase(item_id)
            names.erase(item_id)
        else:
            counts[item_id] = remaining
    remote_inventory_counts_v60[peer_id] = counts
    remote_inventory_names_v60[peer_id] = names

func _apply_transaction_item_counts_v60(player: CharacterBody3D, item_counts: Dictionary) -> void:
    if player == null:
        return
    var counts: Dictionary = Dictionary(player.get("inventory_counts")).duplicate(true)
    var names: Dictionary = Dictionary(player.get("inventory_names")).duplicate(true)
    for item_variant: Variant in item_counts.keys():
        var item_id: String = str(item_variant)
        var value: int = clampi(int(item_counts.get(item_variant, 0)), 0, 999)
        if value <= 0:
            counts.erase(item_id)
            names.erase(item_id)
        else:
            counts[item_id] = value
            if not names.has(item_id):
                names[item_id] = _default_item_name_v60(item_id)
    player.set("inventory_counts", counts)
    player.set("inventory_names", names)
    if player.has_method("_update_inventory_hud"):
        player.call("_update_inventory_hud")

func _apply_shelter_world_action_v60(shelter: Node, action: String) -> void:
    match action:
        "generator_fuel":
            var max_fuel: float = float(shelter.get("generator_max_fuel_seconds"))
            var per_can: float = float(shelter.get("generator_fuel_per_can"))
            shelter.set(
                "generator_fuel_seconds",
                minf(max_fuel, float(shelter.get("generator_fuel_seconds")) + per_can)
            )
            shelter.set("generator_running", true)
        "campfire_bundle":
            shelter.set(
                "campfire_burn_seconds",
                minf(
                    float(shelter.get("campfire_max_seconds")),
                    float(shelter.get("campfire_burn_seconds")) + float(shelter.get("campfire_bundle_seconds"))
                )
            )
        "campfire_wood":
            shelter.set(
                "campfire_burn_seconds",
                minf(
                    float(shelter.get("campfire_max_seconds")),
                    float(shelter.get("campfire_burn_seconds")) + float(shelter.get("campfire_wood_seconds"))
                )
            )
        "generator_repair":
            shelter.set(
                "generator_condition_v55",
                minf(
                    float(shelter.get("generator_condition_max_v55")),
                    maxf(0.0, float(shelter.get("generator_condition_v55"))) + float(shelter.get("generator_repair_restore_v55"))
                )
            )
            shelter.set("generator_broken_v55", false)
            shelter.set("generator_running", false)

func _peer_can_use_shelter_target_v60(peer_id: int, action: String) -> bool:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH_V60:
        return false

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null and coop.has_method("is_survivor_downed") and bool(coop.call("is_survivor_downed", peer_id)):
        return false

    var position_variant: Variant = _peer_position_v57(peer_id)
    if position_variant == null or not (position_variant is Vector3):
        return false
    var peer_position: Vector3 = position_variant

    var target_path: String = "OutsideWorld/ShelterCampfire" if action.begins_with("campfire_") else "OutsideWorld/ShelterGenerator"
    var target: Node3D = scene.get_node_or_null(NodePath(target_path)) as Node3D
    if target == null:
        return false
    return peer_position.distance_to(target.global_position) <= SHELTER_INTERACTION_DISTANCE_V60

func _shelter_action_state_valid_v60(shelter: Node, action: String) -> bool:
    match action:
        "generator_fuel":
            if bool(shelter.get("generator_broken_v55")):
                return false
            return float(shelter.get("generator_fuel_seconds")) < float(shelter.get("generator_max_fuel_seconds")) - 1.0
        "campfire_bundle", "campfire_wood":
            return float(shelter.get("campfire_burn_seconds")) < float(shelter.get("campfire_max_seconds")) - 1.0
        "generator_repair":
            return bool(shelter.get("generator_broken_v55")) or float(shelter.get("generator_condition_v55")) < float(shelter.get("generator_condition_max_v55")) - 1.0
    return false

func _report_shelter_noise_v60(action: String) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var target_path: String = "OutsideWorld/ShelterCampfire" if action.begins_with("campfire_") else "OutsideWorld/ShelterGenerator"
    var target: Node3D = scene.get_node_or_null(NodePath(target_path)) as Node3D
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if target == null or noise == null or not noise.has_method("report_noise"):
        return
    var strength: float = 0.72
    var label: String = "campfire fuel"
    if action == "generator_repair":
        strength = 1.05
        label = "generator repair"
    elif action == "generator_fuel":
        strength = 1.20 if not bool(get_node("/root/ShelterSystem").get("generator_running")) else 0.62
        label = "generator fuel"
    noise.call("report_noise", target.global_position, strength, label)

func _accepted_shelter_message_v60(action: String) -> String:
    match action:
        "generator_fuel": return "Host accepted the Fuel Can. Ranger Yard generator updated."
        "campfire_bundle": return "Host accepted the Firewood Bundle. Campfire updated."
        "campfire_wood": return "Host accepted the Wood. Campfire updated."
        "generator_repair": return "Host accepted repair materials. Generator repaired."
    return "Shelter transaction complete."

func _missing_shelter_resource_message_v60(action: String) -> String:
    match action:
        "generator_fuel": return "You have no Fuel Can."
        "campfire_bundle": return "You have no Firewood Bundle."
        "campfire_wood": return "You have no Wood."
        "generator_repair": return "Generator repair requires 2 Scrap + 1 Electronics."
    return "Required shelter resource is missing."

func _invalid_shelter_state_message_v60(shelter: Node, action: String) -> String:
    match action:
        "generator_fuel":
            return "Generator is broken. Repair it first." if bool(shelter.get("generator_broken_v55")) else "Generator fuel tank is full."
        "campfire_bundle", "campfire_wood": return "Campfire fuel reserve is already full."
        "generator_repair": return "Generator condition is already stable."
    return "Shelter state changed before the request completed."

func _sanitize_inventory_counts_v60(value: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    var added: int = 0
    for key_variant: Variant in value.keys():
        if added >= 96:
            break
        var item_id: String = str(key_variant).strip_edges().left(96)
        if item_id.is_empty():
            continue
        var count: int = clampi(int(value.get(key_variant, 0)), 0, 999)
        if count > 0:
            result[item_id] = count
            added += 1
    return result

func _sanitize_inventory_names_v60(value: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    var added: int = 0
    for key_variant: Variant in value.keys():
        if added >= 96:
            break
        var item_id: String = str(key_variant).strip_edges().left(96)
        if item_id.is_empty():
            continue
        result[item_id] = str(value.get(key_variant, item_id)).left(96)
        added += 1
    return result

func _default_item_name_v60(item_id: String) -> String:
    match item_id:
        "generator_fuel": return "Fuel Can"
        "firewood_bundle": return "Firewood Bundle"
        "wood": return "Wood"
        "scrap": return "Scrap"
        "electronics": return "Electronics"
    return item_id.replace("_", " ").capitalize()
