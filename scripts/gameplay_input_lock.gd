extends Node

# Central gameplay input gate for menus and temporary gameplay states.
# Movement/camera/action systems should query this instead of accumulating
# direct dependencies on every individual UI implementation.

const UI_LOCK_SOURCES: Array[String] = [
    "/root/JournalSystem",
    "/root/CraftingSystem",
    "/root/StashMenuSystem",
    "/root/FieldStatusMenuSystem"
]

var manual_locks: Dictionary = {}

func acquire(reason: String) -> void:
    var key: String = reason.strip_edges().to_upper()
    if key.is_empty():
        return
    manual_locks[key] = true

func release(reason: String) -> void:
    var key: String = reason.strip_edges().to_upper()
    if key.is_empty():
        return
    manual_locks.erase(key)

func set_locked(reason: String, locked: bool) -> void:
    if locked:
        acquire(reason)
    else:
        release(reason)

func clear_manual_locks() -> void:
    manual_locks.clear()

func is_locked() -> bool:
    if not manual_locks.is_empty():
        return true
    return _any_ui_open()

func is_reason_locked(reason: String) -> bool:
    return bool(manual_locks.get(reason.strip_edges().to_upper(), false))

func get_active_reasons() -> PackedStringArray:
    var reasons := PackedStringArray()
    for reason_variant: Variant in manual_locks.keys():
        reasons.append(str(reason_variant))
    for path: String in UI_LOCK_SOURCES:
        var source: Node = get_node_or_null(NodePath(path))
        if source != null and source.has_method("is_open") and bool(source.call("is_open")):
            reasons.append(path.get_file().trim_prefix("root/"))
    return reasons

func _any_ui_open() -> bool:
    for path: String in UI_LOCK_SOURCES:
        var source: Node = get_node_or_null(NodePath(path))
        if source == null or not source.has_method("is_open"):
            continue
        if bool(source.call("is_open")):
            return true
    return false
