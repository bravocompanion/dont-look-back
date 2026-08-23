extends "res://scripts/save_system_ranger_v7.gd"

func _collect_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_state(player)
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression != null and progression.has_method("get_save_state"):
        var progression_value: Variant = progression.call("get_save_state")
        if progression_value is Dictionary:
            state["progression_v68"] = Dictionary(progression_value).duplicate(true)
    return state

func _restore_state(state: Dictionary) -> void:
    super._restore_state(state)
    if not state.has("progression_v68"):
        return
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    var progression_value: Variant = state.get("progression_v68", {})
    if progression != null and progression.has_method("restore_save_state") and progression_value is Dictionary:
        progression.call("restore_save_state", Dictionary(progression_value))

func build_checkpoint_shared_snapshot(player: CharacterBody3D) -> Dictionary:
    var snapshot: Dictionary = super.build_checkpoint_shared_snapshot(player)
    # Level/stat/talent/knowledge progression is survivor experience and does not
    # roll back on death/team-wipe checkpoint restoration. Normal world save/load
    # still persists it through progression_v68 above.
    snapshot.erase("progression_v68")
    return snapshot

func delete_save() -> bool:
    var success: bool = super.delete_save()
    if success:
        var progression: Node = get_node_or_null("/root/ProgressionSystem")
        if progression != null:
            if progression.has_method("reset_progression_v68"):
                progression.call("reset_progression_v68")
            if progression.has_method("delete_local_profile_v68"):
                progression.call("delete_local_profile_v68")
    return success

func get_progression_save_contract_v68() -> Dictionary:
    return {
        "normal_save_persists_progression": true,
        "checkpoint_death_rolls_progression_back": false,
        "delete_save_resets_progression": true,
        "delete_save_removes_local_profile": true,
        "legacy_save_without_progression_supported": true,
        "multiplayer_client_profile_supported": true
    }
