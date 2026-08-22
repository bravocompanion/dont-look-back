extends "res://scripts/save_system_ranger_v6.gd"

func _collect_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_state(player)
    var payoff: Node = get_node_or_null("/root/ResearchFacilityPayoffSystem")
    if payoff != null and payoff.has_method("get_save_state"):
        var payoff_value: Variant = payoff.call("get_save_state")
        if payoff_value is Dictionary:
            state["research_payoff_v61"] = Dictionary(payoff_value).duplicate(true)
    return state

func _prepare_clean_reload() -> void:
    super._prepare_clean_reload()
    var payoff: Node = get_node_or_null("/root/ResearchFacilityPayoffSystem")
    if payoff != null and payoff.has_method("reset_progress"):
        payoff.call("reset_progress")

func _restore_state(state: Dictionary) -> void:
    super._restore_state(state)
    var payoff: Node = get_node_or_null("/root/ResearchFacilityPayoffSystem")
    var payoff_value: Variant = state.get("research_payoff_v61", {})
    if payoff != null and payoff.has_method("restore_save_state") and payoff_value is Dictionary:
        payoff.call("restore_save_state", Dictionary(payoff_value))
