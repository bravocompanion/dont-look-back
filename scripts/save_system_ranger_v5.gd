extends "res://scripts/save_system_ranger_v4.gd"

func _collect_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_state(player)
    var world: Dictionary = Dictionary(state.get("world", {})).duplicate(true)

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter != null:
        world["generator_condition_v55"] = float(shelter.get("generator_condition_v55"))
        world["generator_broken_v55"] = bool(shelter.get("generator_broken_v55"))
    state["world"] = world

    var renewable: Node = get_node_or_null("/root/RenewableResourceSystem")
    if renewable != null and renewable.has_method("get_save_state"):
        var renewable_value: Variant = renewable.call("get_save_state")
        if renewable_value is Dictionary:
            state["renewable_resources_v55"] = Dictionary(renewable_value).duplicate(true)
    return state

func _prepare_clean_reload() -> void:
    super._prepare_clean_reload()

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter != null:
        shelter.set("generator_condition_v55", 100.0)
        shelter.set("generator_broken_v55", false)

    var renewable: Node = get_node_or_null("/root/RenewableResourceSystem")
    if renewable != null and renewable.has_method("reset_progress"):
        renewable.call("reset_progress")

func _restore_state(state: Dictionary) -> void:
    super._restore_state(state)

    var world: Dictionary = Dictionary(state.get("world", {}))
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter != null:
        var condition_max: float = float(shelter.get("generator_condition_max_v55")) if shelter.get("generator_condition_max_v55") != null else 100.0
        var condition: float = clampf(float(world.get("generator_condition_v55", condition_max)), 0.0, condition_max)
        var broken: bool = bool(world.get("generator_broken_v55", false)) or condition <= 0.0
        shelter.set("generator_condition_v55", condition)
        shelter.set("generator_broken_v55", broken)
        if broken:
            shelter.set("generator_running", false)
        if shelter.has_method("_sync_generator_state"):
            shelter.call("_sync_generator_state")
        if shelter.has_method("_broadcast_generator_condition_v55"):
            shelter.call("_broadcast_generator_condition_v55")

    var renewable: Node = get_node_or_null("/root/RenewableResourceSystem")
    var renewable_value: Variant = state.get("renewable_resources_v55", {})
    if renewable != null and renewable.has_method("restore_save_state") and renewable_value is Dictionary:
        renewable.call("restore_save_state", Dictionary(renewable_value))
