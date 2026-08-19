extends "res://scripts/field_status_menu_system_v39_safe.gd"

func _refresh_status(player: CharacterBody3D) -> void:
    super._refresh_status(player)
    var radiation_system: Node = get_node_or_null("/root/RadiationSystem")
    if radiation_system == null:
        return

    var radiation_value: float = 0.0
    var radiation_rate: float = 0.0
    if radiation_system.has_method("get_radiation"):
        radiation_value = float(radiation_system.call("get_radiation"))
    if radiation_system.has_method("get_radiation_rate"):
        radiation_rate = float(radiation_system.call("get_radiation_rate"))

    var gear: PackedStringArray = PackedStringArray()
    if player.has_method("has_item") and bool(player.call("has_item", "raincoat")):
        gear.append("Raincoat")
    if player.has_method("has_item") and bool(player.call("has_item", "radiation_suit")):
        gear.append("Radiation Suit")
    var gear_text: String = ", ".join(gear) if not gear.is_empty() else "none"

    var base_condition: String = condition_label.text if condition_label != null else "CONDITION"
    _set_label_text(
        condition_label,
        "%s\nRadiation %d%%  •  Rate %.2f/s  •  Protection gear: %s" % [base_condition, int(round(radiation_value)), radiation_rate, gear_text]
    )

func _environment_text() -> String:
    var text: String = super._environment_text()
    var escalation: Node = get_node_or_null("/root/SurvivalEscalationSystem")
    if escalation != null and escalation.has_method("get_difficulty_name"):
        text += "\nDifficulty phase: %s" % str(escalation.call("get_difficulty_name"))
    return text

func _shelter_text() -> String:
    var text: String = super._shelter_text()
    var radiation_system: Node = get_node_or_null("/root/RadiationSystem")
    if radiation_system == null:
        return text
    var built: bool = radiation_system.has_method("is_tower_built") and bool(radiation_system.call("is_tower_built"))
    var powered: bool = radiation_system.has_method("is_tower_powered") and bool(radiation_system.call("is_tower_powered"))
    var radius: int = int(round(float(radiation_system.call("get_tower_radius")))) if radiation_system.has_method("get_tower_radius") else 0
    var tower_text: String = "NOT BUILT"
    if built:
        tower_text = "POWERED — %dm protection" % radius if powered else "BUILT — NO POWER"
    return "%s\nAnti-Radiation Tower: %s" % [text, tower_text]

func _other_menu_open() -> bool:
    if super._other_menu_open():
        return true
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
        return true
    var stash: Node = get_node_or_null("/root/StashMenuSystem")
    return stash != null and stash.has_method("is_open") and bool(stash.call("is_open"))
