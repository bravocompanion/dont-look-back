extends "res://scripts/progression_menu_system_v68.gd"

func _build_overview_tab_v68(progression: Node, summary: Dictionary) -> void:
    super._build_overview_tab_v68(progression, summary)
    if progression == null or not progression.has_method("get_field_intel_cards_v70"):
        return
    var cards_value: Variant = progression.call("get_field_intel_cards_v70", active_player)
    if not (cards_value is Array):
        return
    var cards: Array = Array(cards_value)
    if cards.is_empty():
        return
    _add_section_v68("ACTIVE SPECIALIZATION INTEL")
    for value: Variant in cards:
        if not (value is Dictionary):
            continue
        var card: Dictionary = Dictionary(value)
        _add_card_v68("%s\n%s" % [str(card.get("title", "INTEL")), str(card.get("text", ""))])

func _build_knowledge_tab_v68(progression: Node) -> void:
    super._build_knowledge_tab_v68(progression)
    if progression == null or not progression.has_method("get_specialized_knowledge_analysis_v70"):
        return
    var unlocked: Dictionary = Dictionary(progression.call("get_knowledge_v68"))
    var knowledge_order: Array = Array(progression.call("get_knowledge_order_v68")) if progression.has_method("get_knowledge_order_v68") else []
    var analysis_cards: Array[Dictionary] = []
    for knowledge_value: Variant in knowledge_order:
        var knowledge_id: String = str(knowledge_value)
        if not bool(unlocked.get(knowledge_id, false)):
            continue
        var analysis: String = str(progression.call("get_specialized_knowledge_analysis_v70", knowledge_id, active_player)).strip_edges()
        if analysis.is_empty():
            continue
        var data: Dictionary = Dictionary(progression.call("get_knowledge_definition_v68", knowledge_id))
        analysis_cards.append({
            "title": str(data.get("title", knowledge_id)).to_upper(),
            "analysis": analysis
        })
    if analysis_cards.is_empty():
        return
    _add_section_v68("TALENT ANALYSIS")
    for card: Dictionary in analysis_cards:
        _add_card_v68("%s\n%s" % [str(card.get("title", "ANALYSIS")), str(card.get("analysis", ""))])

func get_progression_menu_intel_contract_v70() -> Dictionary:
    return {
        "active_specialization_cards": true,
        "knowledge_talent_analysis": true,
        "desktop_responsive": true,
        "mobile_responsive": true,
        "input_lock_retained": true,
        "new_art_required": false
    }
