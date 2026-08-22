extends "res://scripts/coop_horror_system.gd"

# v0.51 authority guard for the new Tenant rules. Clients may request an
# encounter, but the HOST validates night, world light and global respawn cooldown.
@export var tenant_night_start_minutes_v51: float = 1200.0
@export var tenant_night_end_minutes_v51: float = 300.0
@export var tenant_respawn_min_seconds_v51: float = 15.0
@export var tenant_respawn_max_seconds_v51: float = 60.0

var tenant_respawn_cooldown_v51: float = 0.0
var tenant_rng_v51: RandomNumberGenerator = RandomNumberGenerator.new()
var tenant_target_selection_v51: bool = false

func _ready() -> void:
    super._ready()
    tenant_rng_v51.randomize()

func _process(delta: float) -> void:
    tenant_respawn_cooldown_v51 = maxf(0.0, tenant_respawn_cooldown_v51 - delta)
    super._process(delta)

func _collect_local_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_local_state(player)
    state["world_light"] = _player_near_world_light_v51(player)
    return state

func _server_start_tenant(trigger_peer_id: int) -> void:
    if tenant_active or tenant_respawn_cooldown_v51 > 0.0 or not _tenant_night_allowed_v51():
        return

    var trigger_state: Dictionary = _get_survivor_state(trigger_peer_id)
    if trigger_state.is_empty() or bool(trigger_state.get("downed", false)):
        return
    if bool(trigger_state.get("world_light", false)):
        return

    super._server_start_tenant(trigger_peer_id)

func _server_stop_tenant() -> void:
    var was_active: bool = tenant_active
    super._server_stop_tenant()
    if was_active:
        tenant_respawn_cooldown_v51 = tenant_rng_v51.randf_range(
            minf(tenant_respawn_min_seconds_v51, tenant_respawn_max_seconds_v51),
            maxf(tenant_respawn_min_seconds_v51, tenant_respawn_max_seconds_v51)
        )

func _update_tenant(delta: float) -> void:
    if not tenant_active:
        return
    if not _tenant_night_allowed_v51():
        _server_stop_tenant()
        return
    if not _has_dark_survivor_v51():
        _server_stop_tenant()
        return

    # Only Tenant target selection is filtered by world light. Darkness Creature
    # targeting keeps the original selector and behavior.
    tenant_target_selection_v51 = true
    super._update_tenant(delta)
    tenant_target_selection_v51 = false

func _select_nearest_survivor(origin: Vector3) -> int:
    if not tenant_target_selection_v51:
        return super._select_nearest_survivor(origin)

    var best_peer_id: int = 0
    var best_distance: float = INF
    for peer_id: int in _get_active_peer_ids():
        var state: Dictionary = _get_survivor_state(peer_id)
        if state.is_empty() or bool(state.get("downed", false)) or bool(state.get("world_light", false)):
            continue
        var survivor_transform: Transform3D = state.get("transform", Transform3D.IDENTITY)
        var distance: float = origin.distance_to(survivor_transform.origin)
        if distance < best_distance:
            best_distance = distance
            best_peer_id = peer_id
    return best_peer_id

func _has_dark_survivor_v51() -> bool:
    for peer_id: int in _get_active_peer_ids():
        var state: Dictionary = _get_survivor_state(peer_id)
        if state.is_empty() or bool(state.get("downed", false)):
            continue
        if not bool(state.get("world_light", false)):
            return true
    return false

func _tenant_night_allowed_v51() -> bool:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null or not outside.has_method("get_time_minutes"):
        return false
    var minutes: float = fposmod(float(outside.call("get_time_minutes")), 1440.0)
    return minutes >= tenant_night_start_minutes_v51 or minutes < tenant_night_end_minutes_v51

func _player_near_world_light_v51(target_player: CharacterBody3D) -> bool:
    if target_player == null:
        return false
    var scene: Node = get_tree().current_scene
    if scene == null:
        return false
    if target_player.has_method("_has_nearby_world_light"):
        return bool(target_player.call("_has_nearby_world_light", scene))
    return false
