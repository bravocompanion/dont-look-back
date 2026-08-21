extends "res://scripts/forest_survival_system_v41.gd"

const ARROW_PROJECTILE_SCRIPT_PATH: String = "res://scripts/forest_arrow_projectile_v44.gd"
const ARROW_BREAK_CHANCE: float = 0.20

@export var arrow_projectile_speed: float = 48.0
@export var arrow_projectile_gravity: float = 3.4
@export var arrow_projectile_lifetime: float = 8.0

var arrow_projectile_script: Script
var arrow_projectiles: Dictionary = {}
var arrow_claims: Dictionary = {}
var pending_arrow_recovery_note_by_peer: Dictionary = {}
var next_arrow_projectile_id: int = 1

func _ready() -> void:
    super._ready()
    arrow_projectile_script = load(ARROW_PROJECTILE_SCRIPT_PATH) as Script

func _process(delta: float) -> void:
    super._process(delta)
    _cleanup_arrow_projectiles()

func _try_hunt() -> void:
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("has_item"):
        return
    if not bool(player.call("has_item", "hunting_bow")):
        _objective(player, "You need the Hunting Bow from the ranger cache.")
        return
    if not bool(player.call("has_item", "arrow")):
        _objective(player, "No arrows left. Recover intact arrows or craft/find more.")
        return

    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return

    var launch_direction: Vector3 = -camera.global_transform.basis.z.normalized()
    var launch_origin: Vector3 = camera.global_position + launch_direction * 0.72

    if not player.has_method("remove_item") or not bool(player.call("remove_item", "arrow")):
        return

    bow_cooldown = bow_cooldown_seconds
    player.set("stamina", maxf(0.0, float(player.get("stamina")) - 4.0))

    if _network_online() and not _is_authoritative():
        _request_arrow_shot_remote.rpc_id(1, launch_origin, launch_direction)
    else:
        _host_spawn_arrow(_local_peer_id(), launch_origin, launch_direction)

func on_arrow_projectile_hit(
    projectile_id: int,
    collider_value: Variant,
    impact_position: Vector3,
    impact_normal: Vector3,
    shooter_peer_id: int,
    within_damage_range: bool
) -> void:
    if not _is_authoritative():
        return

    var can_recover: bool = weather_rng.randf() >= ARROW_BREAK_CHANCE
    var recovery_note: String = " Arrow intact — recover it from the impact point." if can_recover else " Arrow broke on impact."
    var animal: Node = _wildlife_from_collider(collider_value)
    var animal_killed: bool = false

    if animal != null and within_damage_range and bool(animal.get("alive")) and animal.has_method("take_hunting_damage"):
        pending_arrow_recovery_note_by_peer[shooter_peer_id] = recovery_note
        animal.call("take_hunting_damage", bow_damage, shooter_peer_id)
        animal_killed = not bool(animal.get("alive"))
        if not animal_killed:
            pending_arrow_recovery_note_by_peer.erase(shooter_peer_id)
    elif animal != null and not within_damage_range:
        _message_peer(shooter_peer_id, "The arrow reached the animal beyond effective bow range.%s" % recovery_note)

    _broadcast_arrow_impact(projectile_id, impact_position, impact_normal, can_recover)

    if animal_killed:
        return
    if animal != null and within_damage_range:
        _message_peer(shooter_peer_id, "HIT: %s.%s" % [str(animal.get("animal_kind")).capitalize(), recovery_note])
    elif animal == null:
        _message_peer(shooter_peer_id, "The arrow struck the environment.%s" % recovery_note)

func on_arrow_projectile_timeout(projectile_id: int, shooter_peer_id: int) -> void:
    if not _is_authoritative():
        return
    _broadcast_remove_arrow(projectile_id)
    _message_peer(shooter_peer_id, "The arrow travelled out of reach and was lost.")

func request_arrow_recovery(projectile_id: int) -> void:
    if not forest_active or _ui_blocked():
        return
    if _network_online() and not _is_authoritative():
        _request_arrow_recovery_remote.rpc_id(1, projectile_id)
        return
    _handle_arrow_recovery_request(_local_peer_id(), projectile_id)

func on_animal_killed(animal_id: String, animal_kind: String, hunter_peer_id: int, _death_position: Vector3) -> void:
    if not _is_authoritative():
        return
    respawn_timers[animal_id] = animal_respawn_seconds
    var loot: Dictionary = _loot_for_kind(animal_kind)
    var arrow_note: String = str(pending_arrow_recovery_note_by_peer.get(hunter_peer_id, ""))
    pending_arrow_recovery_note_by_peer.erase(hunter_peer_id)
    _grant_loot_to_peer(
        hunter_peer_id,
        loot,
        "HUNT: %s down. Harvested %s.%s" % [animal_kind.capitalize(), _loot_summary(loot), arrow_note]
    )
    _broadcast_wildlife_state()

@rpc("any_peer", "call_remote", "reliable", 29)
func _request_arrow_shot_remote(launch_origin: Vector3, launch_direction: Vector3) -> void:
    if not _is_authoritative():
        return
    var sender_peer_id: int = multiplayer.get_remote_sender_id()
    if sender_peer_id <= 0 or launch_direction.length_squared() <= 0.25:
        return

    var sender_player: CharacterBody3D = _player_for_peer(sender_peer_id)
    if sender_player != null and sender_player.global_position.distance_to(launch_origin) > 4.0:
        return
    _host_spawn_arrow(sender_peer_id, launch_origin, launch_direction.normalized())

func _host_spawn_arrow(shooter_peer_id: int, launch_origin: Vector3, launch_direction: Vector3) -> void:
    if not _is_authoritative() or not forest_active:
        return
    var projectile_id: int = next_arrow_projectile_id
    next_arrow_projectile_id += 1
    if next_arrow_projectile_id >= 2000000000:
        next_arrow_projectile_id = 1

    if _network_online():
        _spawn_arrow_projectile_remote.rpc(projectile_id, shooter_peer_id, launch_origin, launch_direction.normalized())
    else:
        _spawn_arrow_projectile_remote(projectile_id, shooter_peer_id, launch_origin, launch_direction.normalized())

@rpc("authority", "call_local", "reliable", 30)
func _spawn_arrow_projectile_remote(projectile_id: int, shooter_peer_id: int, launch_origin: Vector3, launch_direction: Vector3) -> void:
    if arrow_projectiles.has(projectile_id):
        return
    if arrow_projectile_script == null:
        arrow_projectile_script = load(ARROW_PROJECTILE_SCRIPT_PATH) as Script
    if arrow_projectile_script == null:
        return

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        return
    var root: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if root == null:
        return

    var projectile: StaticBody3D = StaticBody3D.new()
    projectile.name = "ArrowProjectile_%d" % projectile_id
    projectile.set_script(arrow_projectile_script)
    root.add_child(projectile)
    if projectile.has_method("configure"):
        projectile.call(
            "configure",
            projectile_id,
            shooter_peer_id,
            launch_origin,
            launch_direction,
            arrow_projectile_speed,
            bow_range,
            arrow_projectile_gravity,
            arrow_projectile_lifetime,
            _is_authoritative()
        )
    arrow_projectiles[projectile_id] = projectile

func _broadcast_arrow_impact(projectile_id: int, impact_position: Vector3, impact_normal: Vector3, can_recover: bool) -> void:
    if _network_online():
        _resolve_arrow_impact_remote.rpc(projectile_id, impact_position, impact_normal, can_recover)
    else:
        _resolve_arrow_impact_remote(projectile_id, impact_position, impact_normal, can_recover)

@rpc("authority", "call_local", "reliable", 31)
func _resolve_arrow_impact_remote(projectile_id: int, impact_position: Vector3, impact_normal: Vector3, can_recover: bool) -> void:
    var projectile: Node = arrow_projectiles.get(projectile_id, null) as Node
    if projectile == null or not is_instance_valid(projectile):
        arrow_projectiles.erase(projectile_id)
        return
    if projectile.has_method("resolve_impact"):
        projectile.call("resolve_impact", impact_position, impact_normal, can_recover)
    if not can_recover:
        arrow_projectiles.erase(projectile_id)
        arrow_claims.erase(projectile_id)

@rpc("any_peer", "call_remote", "reliable", 32)
func _request_arrow_recovery_remote(projectile_id: int) -> void:
    if not _is_authoritative():
        return
    _handle_arrow_recovery_request(multiplayer.get_remote_sender_id(), projectile_id)

func _handle_arrow_recovery_request(peer_id: int, projectile_id: int) -> void:
    if not _is_authoritative() or peer_id <= 0:
        return
    var projectile: Node3D = arrow_projectiles.get(projectile_id, null) as Node3D
    if projectile == null or not is_instance_valid(projectile):
        arrow_projectiles.erase(projectile_id)
        return
    if not projectile.has_method("is_recoverable_arrow") or not bool(projectile.call("is_recoverable_arrow")):
        return
    if int(arrow_claims.get(projectile_id, 0)) != 0:
        return

    var peer_player: CharacterBody3D = _player_for_peer(peer_id)
    if peer_player != null and peer_player.global_position.distance_to(projectile.global_position) > 3.4:
        _message_peer(peer_id, "Move closer to the arrow before recovering it.")
        return

    if not _network_online() or peer_id == _local_peer_id():
        var local_player: CharacterBody3D = _local_player()
        if local_player == null or not local_player.has_method("add_item"):
            return
        if not bool(local_player.call("add_item", "arrow", "Arrow")):
            _objective(local_player, "Inventory full. The arrow remains on the ground.")
            return
        _broadcast_remove_arrow(projectile_id)
        _objective(local_player, "Recovered Arrow. The shaft survived the impact.")
        return

    arrow_claims[projectile_id] = peer_id
    _attempt_arrow_recovery_remote.rpc_id(peer_id, projectile_id)

@rpc("authority", "call_remote", "reliable", 33)
func _attempt_arrow_recovery_remote(projectile_id: int) -> void:
    var player: CharacterBody3D = _local_player()
    var success: bool = false
    if player != null and player.has_method("add_item"):
        success = bool(player.call("add_item", "arrow", "Arrow"))
        if success:
            _objective(player, "Recovered Arrow. The shaft survived the impact.")
        else:
            _objective(player, "Inventory full. The arrow remains on the ground.")
    _complete_arrow_recovery_remote.rpc_id(1, projectile_id, success)

@rpc("any_peer", "call_remote", "reliable", 34)
func _complete_arrow_recovery_remote(projectile_id: int, success: bool) -> void:
    if not _is_authoritative():
        return
    var sender_peer_id: int = multiplayer.get_remote_sender_id()
    if int(arrow_claims.get(projectile_id, 0)) != sender_peer_id:
        return
    arrow_claims.erase(projectile_id)
    if success:
        _broadcast_remove_arrow(projectile_id)
    else:
        _message_peer(sender_peer_id, "Inventory full. The arrow remains recoverable.")

func _broadcast_remove_arrow(projectile_id: int) -> void:
    if _network_online():
        _remove_arrow_projectile_remote.rpc(projectile_id)
    else:
        _remove_arrow_projectile_remote(projectile_id)

@rpc("authority", "call_local", "reliable", 35)
func _remove_arrow_projectile_remote(projectile_id: int) -> void:
    arrow_claims.erase(projectile_id)
    var projectile: Node = arrow_projectiles.get(projectile_id, null) as Node
    arrow_projectiles.erase(projectile_id)
    if projectile != null and is_instance_valid(projectile):
        projectile.queue_free()

func _player_for_peer(peer_id: int) -> CharacterBody3D:
    var fallback: CharacterBody3D
    for candidate: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = candidate as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        if not _network_online():
            return player
        if player.get_multiplayer_authority() == peer_id:
            return player
    if peer_id == _local_peer_id():
        return fallback
    return null

func _cleanup_arrow_projectiles() -> void:
    if not forest_active:
        arrow_projectiles.clear()
        arrow_claims.clear()
        return
    var stale_ids: Array = []
    for id_value: Variant in arrow_projectiles.keys():
        var projectile: Node = arrow_projectiles.get(id_value, null) as Node
        if projectile == null or not is_instance_valid(projectile):
            stale_ids.append(id_value)
    for id_value: Variant in stale_ids:
        arrow_projectiles.erase(id_value)
        arrow_claims.erase(id_value)
