extends "res://scripts/progression_system_v70.gd"

const TALENT_TREE_ORDER_V72: Array[String] = ["SURVIVAL", "SCOUT", "TECHNICIAN", "INVESTIGATOR"]
const TALENT_TIER_LEVELS_V72: Array[int] = [1, 5, 10, 20]
const TALENT_TIER_NAMES_V72: Dictionary = {
    1: "TIER I — FOUNDATION",
    5: "TIER II — SPECIALIZATION",
    10: "TIER III — ADVANCED",
    20: "TIER IV — SIGNATURE"
}

func get_talent_tree_names_v72() -> Array[String]:
    return TALENT_TREE_ORDER_V72.duplicate()

func get_talent_tree_tiers_v72(tree_name: String) -> Array[Dictionary]:
    var normalized: String = tree_name.to_upper()
    var tiers: Array[Dictionary] = []
    if normalized not in TALENT_TREE_ORDER_V72:
        return tiers

    var talent_order: Array = Array(get_talent_order_v68())
    for tier_level: int in TALENT_TIER_LEVELS_V72:
        var nodes: Array[String] = []
        for talent_value: Variant in talent_order:
            var talent_id: String = str(talent_value)
            var data: Dictionary = get_talent_definition_v68(talent_id)
            if str(data.get("tree", "")).to_upper() != normalized:
                continue
            if int(data.get("min_level", 1)) != tier_level:
                continue
            nodes.append(talent_id)
        tiers.append({
            "level": tier_level,
            "name": str(TALENT_TIER_NAMES_V72.get(tier_level, "TIER")),
            "talents": nodes
        })
    return tiers

func get_talent_tree_node_state_v72(talent_id: String) -> Dictionary:
    var data: Dictionary = get_talent_definition_v68(talent_id)
    if data.is_empty():
        return {}
    var rank: int = get_talent_rank_v68(talent_id)
    var max_rank: int = maxi(1, int(data.get("max_rank", 1)))
    var min_level: int = maxi(1, int(data.get("min_level", 1)))
    var required_id: String = str(data.get("requires", ""))
    var required_rank: int = maxi(1, int(data.get("requires_rank", 1))) if not required_id.is_empty() else 0
    var required_ok: bool = true
    var required_name: String = ""
    if not required_id.is_empty():
        var required_data: Dictionary = get_talent_definition_v68(required_id)
        required_name = str(required_data.get("name", required_id))
        required_ok = get_talent_rank_v68(required_id) >= required_rank

    var maxed: bool = rank >= max_rank
    var level_ok: bool = level >= min_level
    var points_ok: bool = talent_points > 0
    return {
        "talent_id": talent_id,
        "rank": rank,
        "max_rank": max_rank,
        "min_level": min_level,
        "required_id": required_id,
        "required_name": required_name,
        "required_rank": required_rank,
        "required_ok": required_ok,
        "level_ok": level_ok,
        "points_ok": points_ok,
        "maxed": maxed,
        "can_unlock": not maxed and level_ok and required_ok and points_ok
    }

func can_unlock_talent_v72(talent_id: String) -> bool:
    var state: Dictionary = get_talent_tree_node_state_v72(talent_id)
    return not state.is_empty() and bool(state.get("can_unlock", false))

func get_talent_tree_contract_v72() -> Dictionary:
    return {
        "visual_tree_not_list": true,
        "tree_count": TALENT_TREE_ORDER_V72.size(),
        "tier_levels": TALENT_TIER_LEVELS_V72.duplicate(),
        "uses_existing_prerequisites": true,
        "uses_existing_talent_ranks": true,
        "save_schema_changed": false,
        "profile_format_changed": false,
        "network_authority_changed": false,
        "mobile_vertical_tree": true,
        "desktop_horizontal_tree": true
    }
