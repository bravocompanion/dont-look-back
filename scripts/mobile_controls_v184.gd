extends "res://scripts/mobile_controls_v183.gd"

# v0.58: the same GameplayInputLock used by desktop movement also gates touch
# look, movement, sprint and action buttons. This is independent from the base
# external_blocked flag so map transitions/front-end systems keep ownership of
# their own mobile block state.

var last_gameplay_lock_v184: bool = false

func _process(delta: float) -> void:
    super._process(delta)
    var locked: bool = _gameplay_locked_v184()
    if locked != last_gameplay_lock_v184:
        last_gameplay_lock_v184 = locked
        _clear_touch_state()
        if locked:
            queued_actions.clear()
        _update_action_visibility()

func get_move_vector() -> Vector2:
    if _gameplay_locked_v184():
        return Vector2.ZERO
    return super.get_move_vector()

func consume_look_delta() -> Vector2:
    if _gameplay_locked_v184():
        look_delta = Vector2.ZERO
        return Vector2.ZERO
    return super.consume_look_delta()

func is_sprint_pressed() -> bool:
    return not _gameplay_locked_v184() and super.is_sprint_pressed()

func consume_action(action: String) -> bool:
    if _gameplay_locked_v184():
        queued_actions.erase(action)
        return false
    return super.consume_action(action)

func _queue_action(action: String) -> void:
    if _gameplay_locked_v184():
        return
    super._queue_action(action)

func _set_sprint(value: bool) -> void:
    if _gameplay_locked_v184():
        sprint_pressed = false
        return
    super._set_sprint(value)

func _update_action_visibility() -> void:
    super._update_action_visibility()
    if not _gameplay_locked_v184() or interact_button == null:
        return
    joystick_base.visible = false
    joystick_knob.visible = false
    interact_button.visible = false
    sprint_button.visible = false
    flashlight_button.visible = false
    battery_button.visible = false
    food_button.visible = false
    water_button.visible = false
    medkit_button.visible = false

func _gameplay_locked_v184() -> bool:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock != null and input_lock.has_method("is_locked") and bool(input_lock.call("is_locked")):
        return true

    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition != null and bool(transition.get("transitioning")):
        return true

    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return true

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    return coop != null and bool(coop.get("local_downed"))
