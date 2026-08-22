extends "res://scripts/forest_survival_system_v51.gd"

const WILDLIFE_V52_SCRIPT_PATH: String = "res://scripts/wildlife_animal_v52.gd"

# v0.52 bow sway multipliers relative to the original stationary draw sway.
@export var bow_idle_sway_bonus_v52: float = 0.40
@export var bow_walk_sway_bonus_v52: float = 0.80
@export var bow_run_sway_bonus_v52: float = 1.20
@export var corpse_harvest_distance_v52: float = 3.2

var corpse_harvest_claims_v52: Dictionary = {}
var harvested_corpse_ids_v52: Dictionary = {}

func _ready() -> void:
    super._ready()
    wildlife_script = load(WILDLIFE_V52_SCRIPT_PATH) as Script

func _apply_camera_draw_sway() -> void:
    if bow_draw_camera == null or not is_instance_valid(bow_draw_camera):
        return
    var player: CharacterBody3D = _local_player()
    if player == null:
        return

    var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
    var sprinting: bool = bool(player.get("is_sprinting")) and horizontal_speed > 0.25
    var walking: bool = horizontal_speed > 0.25 and not sprinting
    var airborne: bool = not player.is_on_floor()

    # Requested v0.52 tiers: idle 140%, walking 180%, running 220%.
    # They are mutually exclusive, so locomotion never stacks multiple waves.
    var sway_multiplier: float = 1.0 + bow_idle_sway_bonus_v52
    if sprinting:
        sway_multiplier = 1.0 + bow_run_sway_bonus_v52
    elif walking:
        sway_multiplier = 1.0 + bow_walk_sway_bonus_v52

    if airborne and not bow_was_airborne_v51 and player.velocity.y > 0.20:
        bow_jump_kick_strength_v51 = bow_jump_kick_bonus
    bow_was_airborne_v51 = airborne

    var delta: float = maxf(0.0, get_process_delta_time())
    bow_jump_kick_strength_v51 = move_toward(
        bow_jump_kick_strength_v51,
        0.0,
        bow_jump_kick_decay_speed * delta
    )

    var overdraw_seconds: float = maxf(0.0, bow_draw_elapsed - bow_full_draw_seconds)
    var draw_amplitude_degrees: float = lerpf(
        bow_idle_camera_sway_degrees,
        bow_full_draw_camera_sway_degrees,
        bow_draw_power
    )
    draw_amplitude_degrees += minf(0.32, overdraw_seconds * 0.12)
    var amplitude_degrees: float = draw_amplitude_degrees * sway_multiplier

    var phase: float = bow_sway_phase
    var target_rotation: Vector3 = Vector3(
        deg_to_rad(sin(phase * 1.85) * amplitude_degrees * 0.58),
        deg_to_rad(cos(phase * 2.27 + 0.72) * amplitude_degrees * 0.72),
        deg_to_rad(sin(phase * 1.31 + 1.10) * amplitude_degrees * 0.34)
    )

    var position_amplitude: float = bow_camera_position_sway_meters * (0.45 + bow_draw_power * 0.55) * sway_multiplier
    var target_position: Vector3 = Vector3(
        sin(phase * 2.15) * position_amplitude,
        cos(phase * 1.72 + 0.35) * position_amplitude * 0.70,
        0.0
    )

    # Preserve the v0.51 single jump impulse. It is not a periodic sway layer.
    if bow_jump_kick_strength_v51 > 0.001:
        var kick_degrees: float = draw_amplitude_degrees * bow_jump_kick_strength_v51
        target_rotation.x -= deg_to_rad(kick_degrees * 0.95)
        target_rotation.z += deg_to_rad(kick_degrees * 0.32)
        target_position.y += bow_camera_position_sway_meters * bow_jump_kick_strength_v51 * 1.6
        target_position.z += bow_camera_position_sway_meters * bow_jump_kick_strength_v51 * 0.8

    var smoothing_weight: float = clampf(delta * bow_sway_smoothing_speed, 0.0, 1.0)
    bow_smoothed_camera_rotation = bow_smoothed_camera_rotation.lerp(target_rotation, smoothing_weight)
    bow_smoothed_camera_position = bow_smoothed_camera_position.lerp(target_position, smoothing_weight)

    bow_applied_camera_rotation = bow_smoothed_camera_rotation
    bow_applied_camera_position = bow_smoothed_camera_position
    bow_draw_camera.rotation += bow_applied_camera_rotation
    bow_draw_camera.position += bow_applied_camera_position

func on_animal_killed(animal_id: String, animal_kind: String, hunter_peer_id: int, _death_position: Vector3) -> void:
    if not _is_authoritative():
        return

    respawn_timers[animal_id] = animal_respawn_seconds
    harvested_corpse_ids_v52.erase(animal_id)
    corpse_harvest_claims_v52.erase(animal_id)

    var arrow_note: String = str(pending_arrow_recovery_note_by_peer.get(hunter_peer_id, ""))
    pending_arrow_recovery_note_by_peer.erase(hunter_peer_id)
    _message_peer(
        hunter_peer_id,
        "HUNT: %s down. Approach the carcass with a Hunting Knife to harvest it.%s" % [
            animal_kind.capitalize(),
            arrow_note
        ]
    )
    _broadcast_wildlife_state()

func request_corpse_harvest_v52(animal_id: String) -> void:
    if not forest_active or _ui_blocked() or animal_id.is_empty():
        return
    if _network_online() and not _is_authoritative():
        _request_corpse_harvest_v52_remote.rpc_id(1, animal_id)
        return
    _handle_corpse_harvest_v52(_local_peer_id(), animal_id)

@rpc("any_peer", "call_remote", "reliable", 40)
func _request_corpse_harvest_v52_remote(animal_id: String) -> void:
    if not _is_authoritative():
        return
    _handle_corpse_harvest_v52(multiplayer.get_remote_sender_id(), animal_id)

func _handle_corpse_harvest_v52(peer_id: int, animal_id: String) -> void:
    if not _is_authoritative() or peer_id <= 0:
        return
    if bool(harvested_corpse_ids_v52.get(animal_id, false)):
        _message_peer(peer_id, "That carcass has already been harvested.")
        return
    if int(corpse_harvest_claims_v52.get(animal_id, 0)) != 0:
        _message_peer(peer_id, "Another survivor is already harvesting that carcass.")
        return

    var animal: Node3D = animals.get(animal_id, null) as Node3D
    if animal == null or not is_instance_valid(animal) or bool(animal.get("alive")):
        return
    if not animal.visible:
        return

    var peer_position_value: Variant = _peer_position_v52(peer_id)
    if not (peer_position_value is Vector3):
        _message_peer(peer_id, "Unable to verify your position near the carcass.")
        return
    var peer_position: Vector3 = peer_position_value
    if peer_position.distance_to(animal.global_position) > corpse_harvest_distance_v52:
        _message_peer(peer_id, "Move closer to the carcass before harvesting it.")
        return

    var animal_kind: String = str(animal.get("animal_kind"))
    var loot: Dictionary = _loot_for_kind(animal_kind)

    if not _network_online() or peer_id == _local_peer_id():
        var local_player: CharacterBody3D = _local_player()
        if not _can_harvest_loot_v52(local_player, loot):
            return
        _grant_harvest_loot_local_v52(local_player, loot, animal_kind)
        _complete_corpse_harvest_success_v52(animal_id)
        return

    corpse_harvest_claims_v52[animal_id] = peer_id
    _attempt_corpse_harvest_v52_remote.rpc_id(peer_id, animal_id, animal_kind, loot)

@rpc("authority", "call_remote", "reliable", 41)
func _attempt_corpse_harvest_v52_remote(animal_id: String, animal_kind: String, loot: Dictionary) -> void:
    var player: CharacterBody3D = _local_player()
    var success: bool = _can_harvest_loot_v52(player, loot)
    if success:
        _grant_harvest_loot_local_v52(player, loot, animal_kind)
    _complete_corpse_harvest_v52_remote.rpc_id(1, animal_id, success)

@rpc("any_peer", "call_remote", "reliable", 42)
func _complete_corpse_harvest_v52_remote(animal_id: String, success: bool) -> void:
    if not _is_authoritative():
        return
    var sender_peer_id: int = multiplayer.get_remote_sender_id()
    if int(corpse_harvest_claims_v52.get(animal_id, 0)) != sender_peer_id:
        return
    corpse_harvest_claims_v52.erase(animal_id)
    if success:
        _complete_corpse_harvest_success_v52(animal_id)

func _complete_corpse_harvest_success_v52(animal_id: String) -> void:
    harvested_corpse_ids_v52[animal_id] = true
    corpse_harvest_claims_v52.erase(animal_id)
    if _network_online():
        _set_corpse_collected_v52_remote.rpc(animal_id, true)
    else:
        _set_corpse_collected_v52_remote(animal_id, true)

@rpc("authority", "call_local", "reliable", 43)
func _set_corpse_collected_v52_remote(animal_id: String, collected: bool) -> void:
    var animal: Node = animals.get(animal_id, null) as Node
    if animal != null and animal.has_method("set_corpse_collected_v52"):
        animal.call("set_corpse_collected_v52", collected)

func _can_harvest_loot_v52(player: CharacterBody3D, loot: Dictionary) -> bool:
    if player == null or not player.has_method("has_item") or not player.has_method("add_item"):
        return false
    if not bool(player.call("has_item", "hunting_knife")):
        _objective(player, "You need a Hunting Knife to harvest the carcass.")
        return false

    var inventory_value: Variant = player.get("inventory_names")
    if inventory_value is Dictionary:
        var inventory_names: Dictionary = inventory_value
        var missing_unique: int = 0
        for item_value: Variant in loot.keys():
            var item_id: String = str(item_value)
            if not inventory_names.has(item_id):
                missing_unique += 1
        var capacity: int = int(player.get("inventory_capacity"))
        if inventory_names.size() + missing_unique > capacity:
            _objective(player, "Inventory full. Make room before harvesting the carcass.")
            return false
    return true

func _grant_harvest_loot_local_v52(player: CharacterBody3D, loot: Dictionary, animal_kind: String) -> void:
    if player == null:
        return
    for item_value: Variant in loot.keys():
        var item_id: String = str(item_value)
        var count: int = int(loot.get(item_value, 0))
        for _index: int in range(count):
            player.call("add_item", item_id, _display_name(item_id))
    _objective(
        player,
        "HARVEST: %s — collected %s." % [animal_kind.capitalize(), _loot_summary(loot)]
    )

func _peer_position_v52(peer_id: int) -> Variant:
    var peer_player: CharacterBody3D = _player_for_peer(peer_id)
    if peer_player != null:
        return peer_player.global_position

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        var targets_value: Variant = network.get("remote_targets")
        if targets_value is Dictionary:
            var targets: Dictionary = targets_value
            var peer_state_value: Variant = targets.get(peer_id, null)
            if peer_state_value is Dictionary:
                var peer_state: Dictionary = peer_state_value
                var transform_value: Variant = peer_state.get("transform", null)
                if transform_value is Transform3D:
                    var peer_transform: Transform3D = transform_value
                    return peer_transform.origin

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        var survivor_states_value: Variant = coop.get("survivor_states")
        if survivor_states_value is Dictionary:
            var survivor_states: Dictionary = survivor_states_value
            var state_value: Variant = survivor_states.get(peer_id, null)
            if state_value is Dictionary:
                var state: Dictionary = state_value
                var state_transform_value: Variant = state.get("transform", null)
                if state_transform_value is Transform3D:
                    var state_transform: Transform3D = state_transform_value
                    return state_transform.origin
    return null

func _tick_respawns(delta: float) -> void:
    super._tick_respawns(delta)
    var cleared_ids: Array[String] = []
    for id_value: Variant in harvested_corpse_ids_v52.keys():
        var animal_id: String = str(id_value)
        var animal: Node = animals.get(animal_id, null) as Node
        if animal != null and bool(animal.get("alive")):
            cleared_ids.append(animal_id)
    for animal_id: String in cleared_ids:
        harvested_corpse_ids_v52.erase(animal_id)
        corpse_harvest_claims_v52.erase(animal_id)
        if _network_online():
            _set_corpse_collected_v52_remote.rpc(animal_id, false)
        else:
            _set_corpse_collected_v52_remote(animal_id, false)

func _on_peer_connected(peer_id: int) -> void:
    super._on_peer_connected(peer_id)
    call_deferred("_send_harvested_corpses_v52", peer_id)

func _send_harvested_corpses_v52(peer_id: int) -> void:
    await get_tree().process_frame
    if not _is_authoritative() or not _network_online():
        return
    for id_value: Variant in harvested_corpse_ids_v52.keys():
        if bool(harvested_corpse_ids_v52.get(id_value, false)):
            _set_corpse_collected_v52_remote.rpc_id(peer_id, str(id_value), true)
