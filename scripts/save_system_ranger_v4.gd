extends "res://scripts/save_system_ranger_v3.gd"

const RANGER_START_MINUTES_V41: float = 720.0

func _prepare_clean_reload() -> void:
    super._prepare_clean_reload()
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        outside.set("game_minutes", RANGER_START_MINUTES_V41)
        outside.set("day_index", 1)
        outside.set("cold_exposure", 0.0)
    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    if radiation != null and radiation.has_method("reset_progress"):
        radiation.call("reset_progress")

func _collect_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_state(player)
    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    if radiation != null and radiation.has_method("get_save_state"):
        var radiation_value: Variant = radiation.call("get_save_state")
        if radiation_value is Dictionary:
            state["radiation_survival"] = Dictionary(radiation_value).duplicate(true)
    return state

func _restore_state(state: Dictionary) -> void:
    super._restore_state(state)
    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    var radiation_value: Variant = state.get("radiation_survival", {})
    if radiation != null and radiation.has_method("restore_save_state") and radiation_value is Dictionary:
        radiation.call("restore_save_state", Dictionary(radiation_value))
