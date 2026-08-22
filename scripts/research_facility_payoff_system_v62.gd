extends "res://scripts/research_facility_payoff_system_v61.gd"

# v0.62 turns the v0.61 campaign choice into a lasting gameplay tradeoff.
# RESCUE = better decompression at an actually powered Ranger shelter.
# ANOMALY = earlier readable horror-pacing intelligence, no combat stat buff.

func has_rescue_priority_v62() -> bool:
    return response_complete and selected_choice == CHOICE_DISTRESS

func has_anomaly_priority_v62() -> bool:
    return response_complete and selected_choice == CHOICE_CONTAINMENT

func get_consequence_summary_v62() -> String:
    if has_rescue_priority_v62():
        return "RESCUE PRIORITY: powered Ranger shelter accelerates post-encounter recovery by 45%."
    if has_anomaly_priority_v62():
        return "ANOMALY PRIORITY: decoded topology exposes UNEASE / STALK / HUNT / RECOVERY threat-state analysis."
    if not selected_choice.is_empty() and not response_complete:
        return "Research response still resolving; campaign consequence not active yet."
    return "No Research Facility consequence selected."

func get_campaign_outcome_v61() -> String:
    if not response_complete:
        return ""
    if selected_choice == CHOICE_DISTRESS:
        return "RESCUE PRIORITY — survey distress carrier acknowledged. Powered Ranger shelter now improves recovery pacing."
    if selected_choice == CHOICE_CONTAINMENT:
        return "ANOMALY PRIORITY — containment topology decoded. Threat-state analysis is now available."
    return ""
