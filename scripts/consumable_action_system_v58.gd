extends "res://scripts/consumable_action_system.gd"

# v0.58 guard: opening another gameplay UI/front-end state while a supply
# channel is active cancels it instead of allowing treatment to finish safely
# behind a paused/menu overlay.

func _update_active_action(delta: float) -> void:
    if _other_blocking_state_v58():
        cancel_active_action("Supply use interrupted.")
        return
    super._update_active_action(delta)

func _blocked_by_other_ui() -> bool:
    return _other_blocking_state_v58()

func _other_blocking_state_v58() -> bool:
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return true

    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition != null and bool(transition.get("transitioning")):
        return true

    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock == null or not input_lock.has_method("is_locked") or not bool(input_lock.call("is_locked")):
        return false

    if input_lock.has_method("get_active_reasons"):
        var reasons_value: Variant = input_lock.call("get_active_reasons")
        if reasons_value is PackedStringArray:
            var reasons: PackedStringArray = reasons_value
            for reason: String in reasons:
                if reason.strip_edges().to_upper() != LOCK_REASON:
                    return true
            return false

    # Fallback for older lock implementations: our own manual lock is allowed;
    # an otherwise locked state is treated as external.
    if input_lock.has_method("is_reason_locked") and bool(input_lock.call("is_reason_locked", LOCK_REASON)):
        return false
    return true
