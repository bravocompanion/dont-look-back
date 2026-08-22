extends "res://scripts/investigation_system_v5_english.gd"

# v0.58 gameplay-depth investigation pass:
# - remote evidence collection is validated against scene, target node and distance
# - the Forest opening supports House/Gas Station in either order
# - the Ranger Case Board becomes an actual synthesis step before Mine access
# - optional Water Sample produces a tangible Mine lighting advantage

const EVIDENCE_TARGETS_V58: Dictionary = {
    "survey_manifest": {"scene": FOREST_SCENE_PATH, "node": "EvidenceSurveyManifest"},
    "radio_trace": {"scene": FOREST_SCENE_PATH, "node": "EvidenceRadioTrace"},
    "maintenance_map": {"scene": FOREST_SCENE_PATH, "node": "EvidenceMaintenanceMap"},
    "water_sample": {"scene": FOREST_SCENE_PATH, "node": "EvidenceWaterSample"},
    "foreman_log": {"scene": MINE_SCENE_PATH, "node": "EvidenceForemanLog"},
    "sealed_shaft_report": {"scene": MINE_SCENE_PATH, "node": "EvidenceShaftReport"},
    "facility_badge": {"scene": MINE_SCENE_PATH, "node": "EvidenceFacilityBadge"},
    "facility_terminal": {"scene": FACILITY_SCENE_PATH, "node": "EvidenceFacilityTerminal"}
}

const FOREST_SYNTHESIS_FLAG_V58: String = "forest_clues_synthesized_v58"
const WATER_SAMPLE_BONUS_FLAG_V58: String = "water_sample_stabilization_v58"

@export var evidence_interaction_distance_v58: float = 3.4
@export var case_board_interaction_distance_v58: float = 3.6

func interact_with(kind: String, interaction_id: String, source: Node) -> void:
    if kind == "case_board":
        request_case_board_synthesis_v58()
        return
    super.interact_with(kind, interaction_id, source)

func can_enter_mine() -> bool:
    return has_evidence("maintenance_map") and bool(progress_flags.get(FOREST_SYNTHESIS_FLAG_V58, false))

func get_current_objective() -> String:
    var scene: Node = get_tree().current_scene
    var path: String = scene.scene_file_path if scene != null else ""
    if path != FOREST_SCENE_PATH:
        return super.get_current_objective()

    var has_manifest: bool = has_evidence("survey_manifest")
    var has_radio: bool = has_evidence("radio_trace")
    var synthesized: bool = bool(progress_flags.get(FOREST_SYNTHESIS_FLAG_V58, false))

    if not has_manifest and not has_radio:
        return "CASE 01: Investigate either the Abandoned House or Old Gas Station. Both may hold traces of the missing survey team."
    if not has_manifest:
        return "CASE 01B: The radio trace is logged. Search the Abandoned House for the missing team's route and mine markings."
    if not has_radio:
        return "CASE 01B: The manifest is logged. Search the Old Gas Station for the team's radio/communications trail."
    if not synthesized:
        return "CASE BOARD: Return to the Ranger Cabin and cross-check the manifest with the radio trace."
    if not has_evidence("maintenance_map"):
        return "CLUE SYNTHESIS: The mine symbol and maintenance frequency converge on the old Warehouse. Find the underground access map."
    if not has_evidence("water_sample"):
        return "OLD MINE REVEALED: Mine access is ready. Optional: inspect the Water Pump; its anomalous sample may help stabilize mine lighting."
    return "OLD MINE REVEALED: Water analysis is logged. Prepare supplies, then follow the Warehouse trail to Shaft 03."

func request_case_board_synthesis_v58() -> void:
    if _network_online() and not _is_authoritative():
        _request_case_board_synthesis_remote_v58.rpc_id(1)
        return
    _synthesize_case_board_authoritative_v58(_local_peer_id())

@rpc("any_peer", "call_remote", "reliable", 58)
func _request_case_board_synthesis_remote_v58() -> void:
    if not _is_authoritative():
        return
    var peer_id: int = multiplayer.get_remote_sender_id()
    if peer_id <= 1:
        return
    _synthesize_case_board_authoritative_v58(peer_id)

func _synthesize_case_board_authoritative_v58(peer_id: int) -> void:
    if not _validate_named_interaction_v58(peer_id, FOREST_SCENE_PATH, "RangerCaseBoard", case_board_interaction_distance_v58):
        _feedback_peer(peer_id, "CASE BOARD: Move closer to the Ranger Case Board before cross-checking evidence.")
        return
    if not has_evidence("survey_manifest") or not has_evidence("radio_trace"):
        _feedback_peer(peer_id, "CASE BOARD: You still need both the Survey Manifest and the broken radio trace.")
        return
    if bool(progress_flags.get(FOREST_SYNTHESIS_FLAG_V58, false)):
        _feedback_peer(peer_id, get_current_objective())
        return

    progress_flags[FOREST_SYNTHESIS_FLAG_V58] = true
    if _network_online():
        _sync_investigation_state.rpc(evidence.duplicate(true), progress_flags.duplicate(true))
    _feedback_peer(peer_id, "CLUE SYNTHESIS: Mine markings + maintenance frequency point to the old Warehouse. Find the underground access map.")
    _request_autosave("Forest clue synthesis")

func _collect_evidence_authoritative(evidence_id: String, collector_peer_id: int) -> void:
    if not _validate_evidence_collection_v58(evidence_id, collector_peer_id):
        _feedback_peer(collector_peer_id, "EVIDENCE REJECTED: Move to the physical evidence before recording it.")
        return

    if evidence_id == "water_sample":
        progress_flags[WATER_SAMPLE_BONUS_FLAG_V58] = true

    super._collect_evidence_authoritative(evidence_id, collector_peer_id)

func has_water_sample_bonus_v58() -> bool:
    return has_evidence("water_sample") and bool(progress_flags.get(WATER_SAMPLE_BONUS_FLAG_V58, false))

func _validate_evidence_collection_v58(evidence_id: String, peer_id: int) -> bool:
    if not EVIDENCE_TARGETS_V58.has(evidence_id):
        return false
    var data: Dictionary = Dictionary(EVIDENCE_TARGETS_V58.get(evidence_id, {}))
    return _validate_named_interaction_v58(
        peer_id,
        str(data.get("scene", "")),
        str(data.get("node", "")),
        evidence_interaction_distance_v58
    )

func _validate_named_interaction_v58(peer_id: int, expected_scene: String, node_name: String, max_distance: float) -> bool:
    if expected_scene.is_empty() or node_name.is_empty() or peer_id <= 0:
        return false
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != expected_scene:
        return false
    var target: Node3D = scene.get_node_or_null(NodePath(node_name)) as Node3D
    if target == null or not is_instance_valid(target):
        return false
    var position_result: Dictionary = _peer_position_v58(peer_id)
    if not bool(position_result.get("valid", false)):
        return false
    var position_value: Variant = position_result.get("position", null)
    if not (position_value is Vector3):
        return false
    var player_position: Vector3 = position_value
    return player_position.distance_to(target.global_position) <= maxf(1.0, max_distance)

func _peer_position_v58(peer_id: int) -> Dictionary:
    if not _network_online() or peer_id == _local_peer_id():
        var player: CharacterBody3D = _local_player()
        if player == null:
            return {"valid": false}
        return {"valid": true, "position": player.global_position}

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return {"valid": false}
    var states_value: Variant = coop.get("survivor_states")
    if not (states_value is Dictionary):
        return {"valid": false}
    var states: Dictionary = Dictionary(states_value)
    var state_value: Variant = states.get(peer_id, {})
    if not (state_value is Dictionary):
        return {"valid": false}
    var state: Dictionary = Dictionary(state_value)
    if state.is_empty() or bool(state.get("downed", false)):
        return {"valid": false}
    var transform_value: Variant = state.get("transform", null)
    if not (transform_value is Transform3D):
        return {"valid": false}
    var survivor_transform: Transform3D = transform_value
    return {"valid": true, "position": survivor_transform.origin}
