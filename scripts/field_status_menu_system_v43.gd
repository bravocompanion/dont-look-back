extends "res://scripts/field_status_menu_system_v42.gd"

func _refresh_status(player: CharacterBody3D) -> void:
    super._refresh_status(player)
    if player == null or condition_label == null:
        return
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression == null or not progression.has_method("get_progression_summary_v68"):
        return
    var summary: Dictionary = Dictionary(progression.call("get_progression_summary_v68"))
    var base_condition: String = condition_label.text
    _set_label_text(
        condition_label,
        "%s\nLevel %d  •  Talent Pts %d  •  Stat Pts %d  •  Knowledge %d/%d" % [
            base_condition,
            int(summary.get("level", 1)),
            int(summary.get("talent_points", 0)),
            int(summary.get("stat_points", 0)),
            int(summary.get("knowledge_count", 0)),
            int(summary.get("knowledge_total", 0))
        ]
    )

func get_field_status_progression_contract_v68() -> Dictionary:
    return {
        "shows_level": true,
        "shows_unspent_talent_points": true,
        "shows_unspent_stat_points": true,
        "shows_knowledge_completion": true
    }
