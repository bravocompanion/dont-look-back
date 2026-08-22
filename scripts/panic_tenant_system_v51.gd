extends "res://scripts/panic_tenant_system.gd"

# v0.51 Tenant encounter rules:
# - active/spawn only during the 20:00-05:00 night window
# - flashlight never counts as protection for spawning
# - nearby world OmniLight3D does count as protection
# - each new stillness window rolls a 2-10 second spawn delay
# - after Tenant becomes inactive, respawn is blocked for a random 15-60 seconds
@export var tenant_night_start_minutes: float = 1200.0
@export var tenant_night_end_minutes: float = 300.0
@export var tenant_idle_min_seconds: float = 2.0
@export var tenant_idle_max_seconds: float = 10.0
@export var tenant_respawn_min_seconds: float = 15.0
@export var tenant_respawn_max_seconds: float = 60.0

var tenant_rng_v51: RandomNumberGenerator = RandomNumberGenerator.new()
var tenant_idle_target_v51: float = 2.0
var tenant_stationary_window_v51: bool = false
var tenant_was_active_v51: bool = false

func _ready() -> void:
    super._ready()
    tenant_rng_v51.randomize()
    tenant_idle_target_v51 = _roll_idle_target_v51()
    tenant_was_active_v51 = false

func _process(delta: float) -> void:
    super._process(delta)

    if player == null:
        tenant_was_active_v51 = false
        return

    var active_now: bool = _tenant_active()
    if active_now and not _active_environment_allowed_v51():
        _stop_tenant_for_environment_v51()
        active_now = _tenant_active()

    if tenant_was_active_v51 and not active_now:
        _arm_respawn_cooldown_v51()
    tenant_was_active_v51 = active_now

func _update_idle_tenant(delta: float) -> void:
    if player == null:
        idle_timer = 0.0
        tenant_stationary_window_v51 = false
        return

    # No spawn progress outside the night window or inside world light.
    # The flashlight is intentionally ignored because it is a SpotLight3D and
    # _player_near_world_light_v51 only queries world OmniLight3D sources.
    if not _night_allowed_v51() or _player_near_world_light_v51(player):
        idle_timer = 0.0
        tenant_stationary_window_v51 = false
        return

    if request_cooldown > 0.0 or _tenant_active():
        idle_timer = 0.0
        tenant_stationary_window_v51 = false
        return

    var stationary: bool = current_move_speed <= idle_move_speed and current_look_speed_deg <= idle_look_speed_deg
    if not stationary:
        idle_timer = 0.0
        tenant_stationary_window_v51 = false
        return

    if not tenant_stationary_window_v51:
        tenant_stationary_window_v51 = true
        tenant_idle_target_v51 = _roll_idle_target_v51()
        idle_timer = 0.0

    idle_timer = minf(tenant_idle_target_v51, idle_timer + delta)
    if idle_timer < tenant_idle_target_v51:
        return

    var tenant: Node3D = _tenant_node()
    if tenant == null:
        idle_timer = 0.0
        tenant_stationary_window_v51 = false
        request_cooldown = spawn_request_cooldown
        return

    if _network_online():
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null and coop.has_method("request_tenant_encounter"):
            coop.call("request_tenant_encounter")
    elif tenant.has_method("appear_near_player"):
        tenant.call("appear_near_player")
    elif tenant.has_method("appear"):
        tenant.call("appear")

    idle_timer = 0.0
    tenant_stationary_window_v51 = false
    # Small anti-spam guard if a request is rejected. The true post-encounter
    # cooldown is armed only when an active Tenant becomes inactive.
    request_cooldown = spawn_request_cooldown

func _active_environment_allowed_v51() -> bool:
    if not _night_allowed_v51():
        return false
    if not _network_online():
        return not _player_near_world_light_v51(player)

    # In co-op only the currently hunted local survivor should locally request a
    # light-based stop. The HOST also validates all survivor light states in
    # CoopHorrorSystem v0.51, so another lit teammate cannot incorrectly despawn it.
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return true
    var target_peer: int = int(coop.get("tenant_target_peer"))
    if target_peer <= 0 or target_peer != multiplayer.get_unique_id():
        return true
    return not _player_near_world_light_v51(player)

func _stop_tenant_for_environment_v51() -> void:
    if _network_online():
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null and coop.has_method("request_tenant_stop"):
            coop.call("request_tenant_stop")
        return

    var tenant: Node3D = _tenant_node()
    if tenant != null and tenant.has_method("stop_stalking"):
        tenant.call("stop_stalking")

func _night_allowed_v51() -> bool:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null or not outside.has_method("get_time_minutes"):
        return false
    var minutes: float = fposmod(float(outside.call("get_time_minutes")), 1440.0)
    return minutes >= tenant_night_start_minutes or minutes < tenant_night_end_minutes

func _player_near_world_light_v51(target_player: CharacterBody3D) -> bool:
    if target_player == null:
        return false
    var scene: Node = get_tree().current_scene
    if scene == null:
        return false
    if target_player.has_method("_has_nearby_world_light"):
        return bool(target_player.call("_has_nearby_world_light", scene))
    return false

func _arm_respawn_cooldown_v51() -> void:
    request_cooldown = maxf(request_cooldown, tenant_rng_v51.randf_range(
        minf(tenant_respawn_min_seconds, tenant_respawn_max_seconds),
        maxf(tenant_respawn_min_seconds, tenant_respawn_max_seconds)
    ))
    idle_timer = 0.0
    tenant_stationary_window_v51 = false
    tenant_idle_target_v51 = _roll_idle_target_v51()

func _roll_idle_target_v51() -> float:
    return tenant_rng_v51.randf_range(
        minf(tenant_idle_min_seconds, tenant_idle_max_seconds),
        maxf(tenant_idle_min_seconds, tenant_idle_max_seconds)
    )
