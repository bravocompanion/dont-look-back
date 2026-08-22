extends "res://scripts/shelter_system_ranger_v7.gd"

# v0.55 P1 infrastructure pressure. Generator wear begins on Day 3, scales
# with storms and tower load, and requires scavenged repair materials instead
# of turning fuel into a permanent solution.
@export var generator_condition_max_v55: float = 100.0
@export var generator_repair_restore_v55: float = 70.0

var generator_condition_v55: float = 100.0
var generator_broken_v55: bool = false
var generator_condition_sync_timer_v55: float = 0.0
var generator_last_warning_band_v55: int = 3

func _ready() -> void:
    super._ready()
    if not multiplayer.peer_connected.is_connected(_on_generator_peer_connected_v55):
        multiplayer.peer_connected.connect(_on_generator_peer_connected_v55)

func _process(delta: float) -> void:
    super._process(delta)
    if not _is_authoritative_generator_v55():
        return

    if generator_running and not generator_broken_v55:
        var drain_rate: float = _generator_condition_drain_rate_v55()
        if drain_rate > 0.0:
            generator_condition_v55 = maxf(0.0, generator_condition_v55 - drain_rate * delta)
            _update_generator_warning_v55()
            if generator_condition_v55 <= 0.0:
                generator_condition_v55 = 0.0
                generator_broken_v55 = true
                generator_running = false
                _sync_generator_state()
                _announce("GENERATOR FAILURE — repair requires 2 Scrap + 1 Electronics.")
                _broadcast_generator_condition_v55()
                return

    generator_condition_sync_timer_v55 -= delta
    if generator_condition_sync_timer_v55 <= 0.0:
        generator_condition_sync_timer_v55 = 1.0
        _broadcast_generator_condition_v55()

func get_generator_condition_percent_v55() -> int:
    if generator_condition_max_v55 <= 0.0:
        return 0
    return int(round(clampf(generator_condition_v55 / generator_condition_max_v55, 0.0, 1.0) * 100.0))

func is_generator_broken_v55() -> bool:
    return generator_broken_v55

func activate_generator(player: CharacterBody3D) -> bool:
    if generator_broken_v55:
        _set_objective(player, "Generator is broken. Repair it with 2 Scrap + 1 Electronics before starting it.")
        return false
    if generator_running:
        return refuel_generator(player)
    if generator_fuel_seconds > 1.0:
        generator_running = true
        _sync_generator_state()
        _set_objective(player, "Generator restarted using the fuel already in the tank.")
        return true
    return super.activate_generator(player)

func refuel_generator(player: CharacterBody3D) -> bool:
    if generator_broken_v55:
        _set_objective(player, "Generator is broken. Repair it before adding more fuel.")
        return false
    return super.refuel_generator(player)

func repair_generator_v55(player: CharacterBody3D) -> bool:
    if player == null:
        return false
    if _network_online_v54() and not _is_host_v54():
        _set_objective(player, "Only the HOST can repair the shared generator.")
        return false
    if not generator_broken_v55 and generator_condition_v55 >= generator_condition_max_v55 - 1.0:
        _set_objective(player, "Generator condition is already stable.")
        return false

    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    if int(counts.get("scrap", 0)) < 2 or int(counts.get("electronics", 0)) < 1:
        _set_objective(player, "Generator repair requires 2 Scrap + 1 Electronics.")
        return false
    if not player.has_method("remove_item"):
        return false

    player.call("remove_item", "scrap")
    player.call("remove_item", "scrap")
    player.call("remove_item", "electronics")

    generator_condition_v55 = minf(
        generator_condition_max_v55,
        maxf(generator_condition_v55, 0.0) + generator_repair_restore_v55
    )
    generator_broken_v55 = false
    generator_running = false
    generator_last_warning_band_v55 = _generator_condition_band_v55(get_generator_condition_percent_v55())
    _sync_generator_state()
    _broadcast_generator_condition_v55()
    _set_objective(
        player,
        "Generator repaired to %d%% condition. Restart it when you are ready to spend fuel." % get_generator_condition_percent_v55()
    )
    _save_shelter_checkpoint(player)
    return true

func sleep_until_morning(player: CharacterBody3D) -> bool:
    if generator_broken_v55 and generator_running:
        generator_running = false
        _sync_generator_state()
    if generator_broken_v55 and campfire_burn_seconds <= 0.0:
        _set_objective(player, "The generator is broken and there is no campfire protection. Repair or fuel the campfire first.")
        return false

    var projected_wear: float = _projected_sleep_generator_wear_v55()
    if projected_wear > 0.0 and generator_condition_v55 <= projected_wear + 3.0:
        if _campfire_can_cover_sleep_v55():
            generator_running = false
            _sync_generator_state()
            projected_wear = 0.0
            _set_objective(player, "Generator preserved due to low condition. Tonight will use campfire protection only.")
        else:
            _set_objective(
                player,
                "Generator condition is too low for the planned sleep and the campfire cannot cover the night. Repair or add firewood first."
            )
            return false

    var success: bool = super.sleep_until_morning(player)
    if not success:
        return false
    if projected_wear > 0.0:
        generator_condition_v55 = maxf(0.0, generator_condition_v55 - projected_wear)
        _update_generator_warning_v55()
        _broadcast_generator_condition_v55()
    return true

func _campfire_can_cover_sleep_v55() -> bool:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return false
    var start_minutes: float = float(outside.get("game_minutes"))
    var full_day_seconds: float = maxf(60.0, float(outside.get("full_day_seconds")))
    var simulated_seconds: float = _sleep_duration_seconds_v54(start_minutes, full_day_seconds)
    var required_fire: float = simulated_seconds * maxf(1.0, sleep_resource_draw_multiplier_v54)
    return campfire_burn_seconds + 0.01 >= required_fire

func _projected_sleep_generator_wear_v55() -> float:
    if not generator_running or generator_broken_v55:
        return 0.0
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return 0.0
    var start_minutes: float = float(outside.get("game_minutes"))
    var full_day_seconds: float = maxf(60.0, float(outside.get("full_day_seconds")))
    var simulated_seconds: float = _sleep_duration_seconds_v54(start_minutes, full_day_seconds)
    if simulated_seconds <= 0.0:
        return 0.0

    var tower_extra_draw: float = 0.0
    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    if radiation != null and radiation.has_method("is_tower_built") and bool(radiation.call("is_tower_built")):
        tower_extra_draw = 0.35
    var generator_draw_rate: float = maxf(1.0, sleep_resource_draw_multiplier_v54) * (1.0 + tower_extra_draw)
    var generator_sim_available: float = generator_fuel_seconds / generator_draw_rate
    var generator_sim_used: float = minf(simulated_seconds, generator_sim_available)
    return _generator_condition_drain_rate_v55() * generator_sim_used

func _generator_condition_drain_rate_v55() -> float:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var day_index: int = int(outside.get("day_index")) if outside != null else 1
    if day_index < 3:
        return 0.0

    var rate: float = 0.075
    if day_index == 4:
        rate = 0.095
    elif day_index >= 5:
        rate = minf(0.16, 0.12 + float(day_index - 5) * 0.01)

    var forest_runtime: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if forest_runtime != null and str(forest_runtime.get("current_weather")) == "storm":
        rate *= 1.45

    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    if radiation != null and radiation.has_method("is_tower_built") and bool(radiation.call("is_tower_built")):
        rate *= 1.25
    return rate

func _update_generator_warning_v55() -> void:
    var band: int = _generator_condition_band_v55(get_generator_condition_percent_v55())
    if band >= generator_last_warning_band_v55:
        return
    generator_last_warning_band_v55 = band
    if band == 2:
        _announce("Generator condition below 50%. Plan a repair before relying on it overnight.")
    elif band == 1:
        _announce("Generator condition CRITICAL — below 25%. Repair materials: 2 Scrap + 1 Electronics.")

func _generator_condition_band_v55(percent: int) -> int:
    if percent <= 25:
        return 1
    if percent <= 50:
        return 2
    return 3

func _broadcast_generator_condition_v55() -> void:
    if not _network_online_v54() or not _is_host_v54():
        return
    _receive_generator_condition_v55.rpc(generator_condition_v55, generator_broken_v55)

@rpc("authority", "call_remote", "reliable", 51)
func _receive_generator_condition_v55(condition_value: float, broken: bool) -> void:
    generator_condition_v55 = clampf(condition_value, 0.0, generator_condition_max_v55)
    generator_broken_v55 = broken
    generator_last_warning_band_v55 = _generator_condition_band_v55(get_generator_condition_percent_v55())
    if generator_broken_v55 and generator_running:
        generator_running = false
        _sync_generator_state()

func _on_generator_peer_connected_v55(peer_id: int) -> void:
    if not _is_authoritative_generator_v55() or peer_id <= 1 or not _network_online_v54():
        return
    _receive_generator_condition_v55.rpc_id(peer_id, generator_condition_v55, generator_broken_v55)

func _is_authoritative_generator_v55() -> bool:
    return not _network_online_v54() or _is_host_v54()
