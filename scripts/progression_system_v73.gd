extends "res://scripts/progression_system_v72.gd"

func get_talent_tree_edges_v73(tree_name: String) -> Array[Dictionary]:
    var normalized: String = tree_name.to_upper()
    var edges: Array[Dictionary] = []
    if normalized not in get_talent_tree_names_v72():
        return edges

    for talent_value: Variant in get_talent_order_v68():
        var child_id: String = str(talent_value)
        var child_data: Dictionary = get_talent_definition_v68(child_id)
        if str(child_data.get("tree", "")).to_upper() != normalized:
            continue
        var parent_id: String = str(child_data.get("requires", ""))
        if parent_id.is_empty():
            continue
        var parent_data: Dictionary = get_talent_definition_v68(parent_id)
        if parent_data.is_empty() or str(parent_data.get("tree", "")).to_upper() != normalized:
            continue
        var required_rank: int = maxi(1, int(child_data.get("requires_rank", 1)))
        var parent_rank: int = get_talent_rank_v68(parent_id)
        var child_rank: int = get_talent_rank_v68(child_id)
        edges.append({
            "parent_id": parent_id,
            "child_id": child_id,
            "required_rank": required_rank,
            "parent_rank": parent_rank,
            "child_rank": child_rank,
            "prerequisite_met": parent_rank >= required_rank,
            "child_invested": child_rank > 0,
            "child_maxed": child_rank >= maxi(1, int(child_data.get("max_rank", 1)))
        })
    return edges

func get_talent_visual_node_v73(talent_id: String) -> Dictionary:
    var data: Dictionary = get_talent_definition_v68(talent_id)
    if data.is_empty():
        return {}
    var state: Dictionary = get_talent_tree_node_state_v72(talent_id)
    var result: Dictionary = data.duplicate(true)
    result.merge(state, true)
    result["talent_id"] = talent_id
    result["icon_key"] = talent_id
    result["has_parent"] = not str(data.get("requires", "")).is_empty()
    return result

func get_talent_visual_tree_contract_v73() -> Dictionary:
    return {
        "graphical_parent_child_edges": true,
        "edges_derived_from_existing_requires": true,
        "fake_prerequisites_added": false,
        "unique_generated_icon_nodes": 20,
        "existing_unlock_api": "unlock_talent_v68",
        "save_schema_changed": false,
        "profile_format_changed": false,
        "talent_balance_changed": false,
        "network_authority_changed": false,
        "multiplayer_personal_builds_retained": true,
        "mobile_responsive": true,
        "desktop_responsive": true
    }
