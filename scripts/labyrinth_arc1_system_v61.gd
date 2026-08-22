extends "res://scripts/labyrinth_arc1_system.gd"

func is_objective_available(objective_id: String) -> bool:
    var available: bool = super.is_objective_available(objective_id)
    if not available or not objective_id.begins_with("breaker_"):
        return available
    var rules: Node = get_node_or_null("/root/LabyrinthGameplayRules")
    if rules != null and rules.has_method("can_use_breakers_v61"):
        return bool(rules.call("can_use_breakers_v61"))
    return available

func get_objective_prompt(objective_id: String, display_name: String) -> String:
    if objective_id.begins_with("breaker_") and current_stage == 3:
        var rules: Node = get_node_or_null("/root/LabyrinthGameplayRules")
        if rules != null and rules.has_method("can_use_breakers_v61") and not bool(rules.call("can_use_breakers_v61")):
            var status: String = str(rules.call("get_breaker_requirement_text_v61")) if rules.has_method("get_breaker_requirement_text_v61") else "stabilizers required"
            return "%s locked — %s" % [display_name, status]
    return super.get_objective_prompt(objective_id, display_name)

func get_enemy_aggression_multiplier() -> float:
    var multiplier: float = super.get_enemy_aggression_multiplier()
    var rules: Node = get_node_or_null("/root/LabyrinthGameplayRules")
    if rules != null and rules.has_method("get_enemy_pressure_bonus_v61"):
        multiplier += maxf(0.0, float(rules.call("get_enemy_pressure_bonus_v61")))
    return multiplier
