extends "res://scripts/shelter_system_ranger_v4.gd"

# v0.54 turns sleep into a real resource decision instead of a cheap full-night
# skip. Generator draw includes tower load, sleep uses a 35% protection overhead,
# survival meters advance, and Day-3+ radiation is simulated during time skip.
@export var sleep_resource_draw_multiplier_v54: float = 1.35
@export var sleep_min_health_v54: float = 25.0
@export var sleep_min_hunger_v54: float = 15.0
@export var sleep_min_thirst_v54: float = 20.0

const STORAGE_PRIORITY_V54: Array[String] = [
    "generator_fuel", "flashlight_battery", "medkit", "bandage",
    "bottled_water", "canned_food", "firewood_bundle", "wood", "cloth", "scrap",
    "plastic_sheet", "rubber", "electronics", "lead_plate", "copper_wire", "filter",
    "arrow", "raw_meat", "raw_fish", "cooked_meat", "cooked_fish",
    "hide", "bone", "animal_fat"
]

func take_one_supply(player: CharacterBody3D) -> bool:
    if player == null or not player.has_method("add_item"):
        return false

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    for item_id: String in STORAGE_PRIORITY_V54:
        var count: int = int(storage_counts.get(item_id, 0))
        if count <= 0:
            continue
        var display_name: String = str(storage_names.get(item_id, _v41_display_name(item_id)))

        var accepted: bool = false
        if carry != null and carry.has_method("grant_item"):
            accepted = bool(carry.call("grant_item", player, item_id, display_name, 1))
        else:
            accepted = bool(player.call("add_item", item_id, display_name))
        if not accepted:
            _set_objective(player, "Carry limit reached for %s. Leave it in storage or make room." % display_name)
            return false

        count -= 1
        if count <= 0:
            storage_counts.erase(item_id)
            storage_names.erase(item_id)
        else:
            storage_counts[item_id] = count
        _set_objective(player, "Took %s from storage. Chest holds %d items." % [display_name, _storage_total()])
        return true

    _set_objective(player, "The storage chest is empty.")
    return false

func sleep_until_morning(player: CharacterBody3D) -> bool:
    if player == null:
        return false

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return false

    if float(player.get("health")) < sleep_min_health_v54:
        _set_objective(player, "You are too badly hurt to sleep safely. Treat your wounds first.")
        return false
    if float(player.get("hunger")) < sleep_min_hunger_v54:
        _set_objective(player, "You are too hungry to sleep through the night. Eat first.")
        return false
    if float(player.get("thirst")) < sleep_min_thirst_v54:
        _set_objective(player, "You are too thirsty to sleep through the night. Drink first.")
        return false

    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth != null:
        if depth.has_method("get_bleeding") and float(depth.call("get_bleeding")) >= 18.0:
            _set_objective(player, "The bleeding must be controlled before sleeping.")
            return false
        if depth.has_method("get_infection") and float(depth.call("get_infection")) >= 60.0:
            _set_objective(player, "The infection is too severe for safe sleep. Use medical supplies first.")
            return false

    if get_tree().get_first_node_in_group("darkness_creature") != null:
        _set_objective(player, "Something is still outside. Reach protected light before trying to sleep.")
        return false

    var current_minutes: float = float(outside.get("game_minutes"))
    if current_minutes >= 300.0 and current_minutes < 1080.0:
        _set_objective(player, "It is too early to sleep. Prepare the shelter before night.")
        return false

    var sleep_hours: float = 0.0
    var crosses_midnight: bool = false
    if current_minutes >= 1080.0:
        sleep_hours = (1440.0 - current_minutes + 420.0) / 60.0
        crosses_midnight = true
    else:
        sleep_hours = (420.0 - current_minutes) / 60.0

    var full_day_seconds: float = maxf(60.0, float(outside.get("full_day_seconds")))
    var simulated_seconds: float = sleep_hours * full_day_seconds / 24.0
    var resource_multiplier: float = maxf(1.0, sleep_resource_draw_multiplier_v54)

    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    var tower_extra_draw: float = 0.0
    if generator_running and radiation != null and radiation.has_method("is_tower_built") and bool(radiation.call("is_tower_built")):
        tower_extra_draw = 0.35

    var generator_draw_rate: float = resource_multiplier * (1.0 + tower_extra_draw)
    var generator_sim_available: float = 0.0
    if generator_running and generator_fuel_seconds > 0.0:
        generator_sim_available = generator_fuel_seconds / generator_draw_rate
    var fire_sim_available: float = campfire_burn_seconds / resource_multiplier

    if generator_sim_available + fire_sim_available + 0.01 < simulated_seconds:
        _set_objective(
            player,
            "Not enough protected light for a full night. Sleep now needs sustained fuel; refuel the generator or campfire."
        )
        return false

    # The running generator is consumed first because it is actually operating
    # during the time skip and is the only ranger-yard radiation protection.
    var generator_sim_used: float = minf(simulated_seconds, generator_sim_available)
    var fire_sim_used: float = maxf(0.0, simulated_seconds - generator_sim_used)

    if generator_sim_used > 0.0:
        generator_fuel_seconds = maxf(0.0, generator_fuel_seconds - generator_sim_used * generator_draw_rate)
    if fire_sim_used > 0.0:
        campfire_burn_seconds = maxf(0.0, campfire_burn_seconds - fire_sim_used * resource_multiplier)

    var start_day: int = int(outside.get("day_index"))
    _simulate_radiation_timeline_v54(
        player,
        current_minutes,
        start_day,
        full_day_seconds,
        generator_sim_used,
        true
    )
    var minutes_per_second: float = 1440.0 / full_day_seconds
    var after_generator_minutes: float = current_minutes + generator_sim_used * minutes_per_second
    var after_generator_day: int = start_day
    while after_generator_minutes >= 1440.0:
        after_generator_minutes -= 1440.0
        after_generator_day += 1
    _simulate_radiation_timeline_v54(
        player,
        after_generator_minutes,
        after_generator_day,
        full_day_seconds,
        fire_sim_used,
        false
    )

    var metabolic_cost: Vector2 = _sleep_metabolic_cost_v54(
        current_minutes,
        start_day,
        full_day_seconds,
        simulated_seconds
    )
    player.set("hunger", maxf(0.0, float(player.get("hunger")) - metabolic_cost.x))
    player.set("thirst", maxf(0.0, float(player.get("thirst")) - metabolic_cost.y))

    if generator_fuel_seconds <= 0.01:
        generator_fuel_seconds = 0.0
        if generator_running:
            generator_running = false
            _sync_generator_state()
    _apply_campfire_state()

    outside.set("game_minutes", 420.0)
    if crosses_midnight:
        outside.set("day_index", start_day + 1)
    outside.set("cold_exposure", 0.0)

    player.set("stamina", float(player.get("max_stamina")))
    player.set("darkness_exposure", 0.0)
    if float(player.get("hunger")) > 20.0 and float(player.get("thirst")) > 20.0 and not bool(player.get("is_dead")):
        if player.has_method("heal"):
            player.call("heal", 10.0)

    var dark_creature: Node = get_tree().get_first_node_in_group("darkness_creature")
    if dark_creature != null:
        dark_creature.queue_free()

    _save_shelter_checkpoint(player)
    if bool(player.get("is_dead")):
        return true

    _set_objective(
        player,
        "You survived the night. Sleep consumed sustained light fuel and advanced hunger, thirst, and radiation exposure."
    )
    return true

func _simulate_radiation_timeline_v54(
    player: CharacterBody3D,
    start_minutes: float,
    start_day: int,
    full_day_seconds: float,
    duration_seconds: float,
    generator_protected: bool
) -> void:
    if duration_seconds <= 0.001:
        return
    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    if radiation == null or not radiation.has_method("apply_sleep_exposure_v54"):
        return

    var minutes_per_second: float = 1440.0 / maxf(60.0, full_day_seconds)
    var minute: float = fposmod(start_minutes, 1440.0)
    var day: int = start_day
    var remaining: float = duration_seconds

    while remaining > 0.001:
        var seconds_to_midnight: float = (1440.0 - minute) / minutes_per_second
        var step: float = minf(remaining, maxf(0.001, seconds_to_midnight))
        radiation.call("apply_sleep_exposure_v54", player, step, day, generator_protected)
        remaining -= step
        minute += step * minutes_per_second
        if minute >= 1439.999:
            minute = 0.0
            day += 1

func _sleep_metabolic_cost_v54(
    start_minutes: float,
    start_day: int,
    full_day_seconds: float,
    duration_seconds: float
) -> Vector2:
    var escalation: Node = get_node_or_null("/root/SurvivalEscalationSystem")
    var base_hunger: float = 0.055
    var base_thirst: float = 0.082
    if escalation != null:
        base_hunger = float(escalation.get("base_hunger_drain"))
        base_thirst = float(escalation.get("base_thirst_drain"))

    var minutes_per_second: float = 1440.0 / maxf(60.0, full_day_seconds)
    var minute: float = fposmod(start_minutes, 1440.0)
    var day: int = start_day
    var remaining: float = duration_seconds
    var hunger_cost: float = 0.0
    var thirst_cost: float = 0.0

    while remaining > 0.001:
        var seconds_to_midnight: float = (1440.0 - minute) / minutes_per_second
        var step: float = minf(remaining, maxf(0.001, seconds_to_midnight))
        var multiplier: float = _survival_drain_multiplier_v54(day)
        hunger_cost += base_hunger * multiplier * step
        thirst_cost += base_thirst * multiplier * step
        remaining -= step
        minute += step * minutes_per_second
        if minute >= 1439.999:
            minute = 0.0
            day += 1

    return Vector2(hunger_cost, thirst_cost)

func _survival_drain_multiplier_v54(day_index: int) -> float:
    if day_index <= 1:
        return 0.90
    if day_index == 2:
        return 1.00
    if day_index == 3:
        return 1.08
    if day_index == 4:
        return 1.12
    return 1.18
