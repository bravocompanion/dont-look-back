extends "res://scripts/investigation_system.gd"

func _configure_narrative_scope(_scene_path: String) -> void:
    var narrative: Node = get_node_or_null("/root/SurvivalSystem/NarrativeLoreRuntime")
    if narrative == null:
        return
    if narrative.has_method("_hide_narrative_ui"):
        narrative.call("_hide_narrative_ui")
    # The old chapter runtime assumes the player starts trapped in Apartment 03.
    # Ranger v0.28 enters Labyrinth from the Mine, so Journal/Objectives now own
    # the canonical briefing until the narrative script is rewritten fully.
    narrative.set_process(false)
