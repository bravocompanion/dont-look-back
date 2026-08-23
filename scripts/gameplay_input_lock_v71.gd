extends "res://scripts/gameplay_input_lock.gd"

const UI_LOCK_SOURCES_V71: Array[String] = [
    "/root/JournalSystem",
    "/root/CraftingSystem",
    "/root/StashMenuSystem",
    "/root/FieldStatusMenuSystem",
    "/root/SurvivalSystem/InventoryMenuRuntime",
    "/root/ProgressionMenuSystem",
    "/root/FrontEndSystem"
]

func is_locked() -> bool:
    if not manual_locks.is_empty():
        return true
    return _any_ui_open_v71()

func get_active_reasons() -> PackedStringArray:
    var reasons := PackedStringArray()
    for reason_variant: Variant in manual_locks.keys():
        reasons.append(str(reason_variant))
    for path: String in UI_LOCK_SOURCES_V71:
        var source: Node = get_node_or_null(NodePath(path))
        if _source_open_v71(source, path):
            reasons.append(path)
    return reasons

func _any_ui_open_v71() -> bool:
    for path: String in UI_LOCK_SOURCES_V71:
        if _source_open_v71(get_node_or_null(NodePath(path)), path):
            return true
    return false

func _source_open_v71(source: Node, path: String) -> bool:
    if source == null:
        return false
    if path == "/root/FrontEndSystem":
        if source.has_method("is_menu_open"):
            return bool(source.call("is_menu_open"))
        return bool(source.get("menu_open"))
    if source.has_method("is_open"):
        return bool(source.call("is_open"))
    return false

func get_ui_lock_contract_v71() -> Dictionary:
    return {
        "inventory_covered": "/root/SurvivalSystem/InventoryMenuRuntime" in UI_LOCK_SOURCES_V71,
        "progression_covered": "/root/ProgressionMenuSystem" in UI_LOCK_SOURCES_V71,
        "front_end_covered": "/root/FrontEndSystem" in UI_LOCK_SOURCES_V71,
        "crafting_covered": "/root/CraftingSystem" in UI_LOCK_SOURCES_V71,
        "stash_covered": "/root/StashMenuSystem" in UI_LOCK_SOURCES_V71,
        "journal_covered": "/root/JournalSystem" in UI_LOCK_SOURCES_V71,
        "field_status_covered": "/root/FieldStatusMenuSystem" in UI_LOCK_SOURCES_V71,
        "manual_lock_ownership_retained": true
    }
