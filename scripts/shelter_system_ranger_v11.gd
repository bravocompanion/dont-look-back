extends "res://scripts/shelter_system_ranger_v10.gd"

func _process(delta: float) -> void:
    var effectiveness: float = _fuel_effectiveness_v68()
    if generator_running and effectiveness > 1.0001 and generator_fuel_seconds > 0.0:
        # Add only the virtual seconds saved this frame. The inherited fuel
        # drain remains the single owner of generator on/off and multiplayer sync.
        generator_fuel_seconds += delta * (1.0 - 1.0 / effectiveness)
    super._process(delta)

func sleep_until_morning(player: CharacterBody3D) -> bool:
    var effectiveness: float = _fuel_effectiveness_v68()
    if effectiveness <= 1.0001 or not generator_running or generator_fuel_seconds <= 0.0:
        return super.sleep_until_morning(player)

    # Sleep simulation consumes generator seconds in bulk. Temporarily expose
    # effective seconds, then convert the remaining effective fuel back to the
    # canonical physical tank value after the inherited transaction finishes.
    generator_fuel_seconds *= effectiveness
    var success: bool = super.sleep_until_morning(player)
    generator_fuel_seconds = maxf(0.0, generator_fuel_seconds / effectiveness)
    if generator_fuel_seconds <= 0.01 and generator_running:
        generator_running = false
        _sync_generator_state()
    return success

func repair_generator_v55(player: CharacterBody3D) -> bool:
    var success: bool = super.repair_generator_v55(player)
    if not success:
        return false
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null:
        var outside: Node = get_node_or_null("/root/OutsideDirector")
        var day_index: int = int(outside.get("day_index")) if outside != null else 1
        if progression.has_method("award_event_once_v68"):
            progression.call("award_event_once_v68", "generator_repair:day:%d" % day_index, 40, "Generator repaired", "survival")
        if progression.has_method("unlock_knowledge_v68"):
            progression.call("unlock_knowledge_v68", "generator_maintenance")
    return true

func _fuel_effectiveness_v68() -> float:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("get_generator_fuel_effectiveness_v68"):
        return clampf(float(progression.call("get_generator_fuel_effectiveness_v68")), 1.0, 1.20)
    return 1.0

func get_technician_shelter_contract_v68() -> Dictionary:
    return {
        "fuel_economy_per_rank": 0.06,
        "fuel_economy_max_rank": 2,
        "repair_xp_per_day": 40,
        "generator_condition_immunity": false,
        "free_fuel": false
    }
