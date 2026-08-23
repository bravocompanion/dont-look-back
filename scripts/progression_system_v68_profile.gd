extends "res://scripts/progression_system_v68.gd"

const PROFILE_PATH_V68: String = "user://dont_look_back_progression_v68.json"
const PROFILE_VERSION_V68: int = 1
var profile_load_started_v68: bool = false

func _ready() -> void:
    super._ready()
    call_deferred("_load_local_profile_v68")

func _request_autosave_v68(reason: String) -> void:
    _save_local_profile_v68()
    super._request_autosave_v68(reason)

func restore_save_state(state: Dictionary) -> void:
    super.restore_save_state(state)
    _save_local_profile_v68()

func delete_local_profile_v68() -> bool:
    if FileAccess.file_exists(PROFILE_PATH_V68):
        var path: String = ProjectSettings.globalize_path(PROFILE_PATH_V68)
        var error: Error = DirAccess.remove_absolute(path)
        if error != OK:
            return false
    return true

func get_stat_ids_v68() -> Array[String]:
    return STAT_IDS.duplicate()

func get_talent_order_v68() -> Array[String]:
    return TALENT_ORDER.duplicate()

func get_knowledge_order_v68() -> Array[String]:
    return KNOWLEDGE_ORDER.duplicate()

func get_max_stat_value_v68() -> int:
    return MAX_STAT_VALUE

func get_max_level_v68() -> int:
    return MAX_LEVEL

func _save_local_profile_v68() -> bool:
    var file: FileAccess = FileAccess.open(PROFILE_PATH_V68, FileAccess.WRITE)
    if file == null:
        return false
    var payload: Dictionary = {
        "profile_version": PROFILE_VERSION_V68,
        "saved_unix_time": int(Time.get_unix_time_from_system()),
        "progression": get_save_state()
    }
    file.store_string(JSON.stringify(payload, "  "))
    file.close()
    return true

func _load_local_profile_v68() -> void:
    if profile_load_started_v68:
        return
    profile_load_started_v68 = true
    if not FileAccess.file_exists(PROFILE_PATH_V68):
        return
    var file: FileAccess = FileAccess.open(PROFILE_PATH_V68, FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not (parsed is Dictionary):
        return
    var payload: Dictionary = Dictionary(parsed)
    if int(payload.get("profile_version", 0)) != PROFILE_VERSION_V68:
        return
    var progression_value: Variant = payload.get("progression", {})
    if progression_value is Dictionary:
        super.restore_save_state(Dictionary(progression_value))

func get_profile_contract_v68() -> Dictionary:
    return {
        "path": PROFILE_PATH_V68,
        "per_survivor_local_profile": true,
        "works_for_multiplayer_clients": true,
        "host_world_save_still_supported": true,
        "profile_contains_world_state": false
    }
