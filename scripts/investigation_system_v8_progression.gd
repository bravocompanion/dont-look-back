extends "res://scripts/investigation_system_v7_gameplay.gd"

func _collect_evidence_authoritative(evidence_id: String, collector_peer_id: int) -> void:
    var already_had: bool = has_evidence(evidence_id)
    super._collect_evidence_authoritative(evidence_id, collector_peer_id)
    if already_had or not has_evidence(evidence_id):
        return
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("record_evidence_for_peer_v68"):
        progression.call("record_evidence_for_peer_v68", collector_peer_id, evidence_id)

func _synthesize_case_board_authoritative_v58(peer_id: int) -> void:
    var already_synthesized: bool = bool(progress_flags.get(FOREST_SYNTHESIS_FLAG_V58, false))
    super._synthesize_case_board_authoritative_v58(peer_id)
    if already_synthesized or not bool(progress_flags.get(FOREST_SYNTHESIS_FLAG_V58, false)):
        return
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("record_case_synthesis_for_peer_v68"):
        progression.call("record_case_synthesis_for_peer_v68", peer_id)

func get_investigation_progression_contract_v68() -> Dictionary:
    return {
        "evidence_base_xp": 30,
        "case_synthesis_base_xp": 100,
        "evidence_xp_first_claim_only": true,
        "remote_collector_award_supported": true,
        "evidence_analyst_multiplier_applied_on_receiver": true
    }
