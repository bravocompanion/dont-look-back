extends "res://scripts/movement_system_v42.gd"

func _physics_process(delta: float) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        super._physics_process(delta)
        return
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression == null:
        super._physics_process(delta)
        return

    var base_drain: float = float(player.get("stamina_drain_per_second"))
    var base_regen: float = float(player.get("stamina_regen_per_second"))
    var drain_multiplier: float = float(progression.call("get_sprint_drain_multiplier_v68")) if progression.has_method("get_sprint_drain_multiplier_v68") else 1.0
    var reserve_bonus: float = 1.0
    if progression.has_method("has_talent_v68") and bool(progression.call("has_talent_v68", "last_reserve", 1)):
        if float(player.get("stamina")) < 15.0 and not bool(player.get("is_sprinting")):
            reserve_bonus = 1.15

    player.set("stamina_drain_per_second", base_drain * drain_multiplier)
    player.set("stamina_regen_per_second", base_regen * reserve_bonus)
    super._physics_process(delta)
    player.set("stamina_drain_per_second", base_drain)
    player.set("stamina_regen_per_second", base_regen)

func get_progression_movement_contract_v68() -> Dictionary:
    return {
        "fitness_speed_per_point": 0.002,
        "pathfinder_speed_per_rank": 0.005,
        "runner_sprint_drain_reduction_per_rank": 0.04,
        "last_reserve_low_stamina_regen_multiplier": 1.15,
        "threat_immunity_granted": false
    }
