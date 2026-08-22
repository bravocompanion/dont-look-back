extends "res://scripts/investigation_system_v6_gameplay.gd"

func get_interaction_text(kind: String, interaction_id: String, display_name: String) -> String:
    if kind == "facility_route":
        var payoff: Node = get_node_or_null("/root/ResearchFacilityPayoffSystem")
        if payoff != null and payoff.has_method("get_campaign_outcome_v61"):
            var outcome: String = str(payoff.call("get_campaign_outcome_v61"))
            if not outcome.is_empty():
                return "Current campaign complete — %s" % ("RESCUE PRIORITY" if outcome.begins_with("RESCUE") else "ANOMALY PRIORITY")
    return super.get_interaction_text(kind, interaction_id, display_name)

func interact_with(kind: String, interaction_id: String, source: Node) -> void:
    if kind == "facility_route":
        var payoff: Node = get_node_or_null("/root/ResearchFacilityPayoffSystem")
        if payoff != null and payoff.has_method("get_campaign_outcome_v61"):
            var outcome: String = str(payoff.call("get_campaign_outcome_v61"))
            if not outcome.is_empty():
                if outcome.begins_with("RESCUE"):
                    _set_local_objective("CAMPAIGN END — distress carrier acknowledged. Future route priority: FIND THE SURVEY TEAM. Hospital/Museum/Lab/Cave remain sealed for the next content arc.")
                else:
                    _set_local_objective("CAMPAIGN END — containment topology decoded. Future route priority: CONTAIN THE ANOMALY. Hospital/Museum/Lab/Cave remain sealed for the next content arc.")
                return
    super.interact_with(kind, interaction_id, source)
