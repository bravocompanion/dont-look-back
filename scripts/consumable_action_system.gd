extends Node

# v0.58: consumables are vulnerable actions instead of instant stat buttons.
# Items are only consumed after the channel completes. Taking damage, becoming
# downed/dead, changing player instance, or losing the floor interrupts it.

const LOCK_REASON: String = "CONSUMABLE_ACTION"
const ACTION_FOOD: String = "food"
const ACTION_WATER: String = "water"
const ACTION_MEDKIT: String = "medkit"

@export var food_duration: float = 2.0
@export var water_duration: float = 1.4
@export var medkit_duration: float = 3.5

var active_action: String = ""
var action_duration: float = 0.0
var action_remaining: float = 0.0
var action_player_id: int = 0
var action_start_health: float = 0.0
var feedback_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = -20

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    var action: String = ""
    match key_event.physical_keycode:
        KEY_1:
            action = ACTION_FOOD
        KEY_2:
            action = ACTION_WATER
        KEY_3:
            action = ACTION_MEDKIT
        _:
            return

    # Reserve these gameplay hotkeys so the legacy player script cannot apply
    # its old instant-consume behavior in _unhandled_input().
    get_viewport().set_input_as_handled()
    if active_action.is_empty() and not _blocked_by_other_ui():
        _start_action(action)

func _process(delta: float) -> void:
    if active_action.is_empty():
        _consume_mobile_requests()
        return
    _update_active_action(delta)

func is_action_active() -> bool:
    return not active_action.is_empty()

func get_action_progress() -> float:
    if active_action.is_empty() or action_duration <= 0.0:
        return 0.0
    return clampf(1.0 - action_remaining / action_duration, 0.0, 1.0)

func cancel_active_action(reason: String = "Action interrupted.") -> void:
    if active_action.is_empty():
        return
    var player: CharacterBody3D = _local_player()
    active_action = ""
    action_duration = 0.0
    action_remaining = 0.0
    action_player_id = 0
    action_start_health = 0.0
    feedback_timer = 0.0
    _release_lock()
    if player != null and not reason.is_empty():
        _message_player(player, reason)

func _consume_mobile_requests() -> void:
    if _blocked_by_other_ui():
        return
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile == null or not mobile.has_method("is_mobile_active") or not bool(mobile.call("is_mobile_active")):
        return
    if not mobile.has_method("consume_action"):
        return

    if bool(mobile.call("consume_action", ACTION_MEDKIT)):
        _start_action(ACTION_MEDKIT)
        return
    if bool(mobile.call("consume_action", ACTION_FOOD)):
        _start_action(ACTION_FOOD)
        return
    if bool(mobile.call("consume_action", ACTION_WATER)):
        _start_action(ACTION_WATER)

func _start_action(action: String) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null or bool(player.get("is_dead")) or _local_downed():
        return
    if not player.is_on_floor():
        _message_player(player, "Get stable footing before using supplies.")
        return

    var item_id: String = _item_id(action)
    if item_id.is_empty() or not player.has_method("has_item") or not bool(player.call("has_item", item_id)):
        _message_player(player, _missing_message(action))
        return

    if action == ACTION_MEDKIT:
        var health: float = float(player.get("health"))
        var max_health: float = maxf(1.0, float(player.get("max_health")))
        if health >= max_health - 0.5:
            _message_player(player, "You do not need the medkit yet.")
            return
    elif action == ACTION_WATER:
        var thirst: float = float(player.get("thirst"))
        var max_thirst: float = maxf(1.0, float(player.get("max_thirst")))
        if thirst >= max_thirst - 0.5:
            _message_player(player, "You are not thirsty enough to use that water.")
            return
    elif action == ACTION_FOOD:
        var hunger: float = float(player.get("hunger"))
        var max_hunger: float = maxf(1.0, float(player.get("max_hunger")))
        var health_now: float = float(player.get("health"))
        var max_health_now: float = maxf(1.0, float(player.get("max_health")))
        if hunger >= max_hunger - 0.5 and health_now >= max_health_now - 0.5:
            _message_player(player, "You are not hungry enough to use that food.")
            return

    active_action = action
    action_duration = _duration_for(action)
    action_remaining = action_duration
    action_player_id = int(player.get_instance_id())
    action_start_health = float(player.get("health"))
    feedback_timer = 0.0
    _acquire_lock()
    _message_player(player, _progress_message(action, action_duration))

func _update_active_action(delta: float) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null or int(player.get_instance_id()) != action_player_id:
        cancel_active_action("")
        return
    if bool(player.get("is_dead")) or _local_downed():
        cancel_active_action("Supply use interrupted.")
        return
    if not player.is_on_floor():
        cancel_active_action("Supply use interrupted by movement.")
        return
    if float(player.get("health")) < action_start_health - 0.05:
        cancel_active_action("Supply use interrupted by damage.")
        return

    action_remaining = maxf(0.0, action_remaining - delta)
    feedback_timer -= delta
    if feedback_timer <= 0.0 and action_remaining > 0.0:
        feedback_timer = 0.25
        _message_player(player, _progress_message(active_action, action_remaining))

    if action_remaining <= 0.0:
        _complete_action(player)

func _complete_action(player: CharacterBody3D) -> void:
    var action: String = active_action
    var item_id: String = _item_id(action)
    var removed: bool = player.has_method("remove_item") and bool(player.call("remove_item", item_id))
    active_action = ""
    action_duration = 0.0
    action_remaining = 0.0
    action_player_id = 0
    action_start_health = 0.0
    feedback_timer = 0.0
    _release_lock()

    if not removed:
        _message_player(player, "The supply is no longer available.")
        return

    match action:
        ACTION_MEDKIT:
            if player.has_method("heal"):
                player.call("heal", 45.0)
            _message_player(player, "You finish patching your wounds.")
        ACTION_FOOD:
            var max_hunger: float = maxf(1.0, float(player.get("max_hunger")))
            var max_health: float = maxf(1.0, float(player.get("max_health")))
            player.set("hunger", minf(max_hunger, float(player.get("hunger")) + 42.0))
            player.set("health", minf(max_health, float(player.get("health")) + 4.0))
            _refresh_survival_hud(player)
            _message_player(player, "You finish eating the canned food.")
        ACTION_WATER:
            var max_thirst: float = maxf(1.0, float(player.get("max_thirst")))
            player.set("thirst", minf(max_thirst, float(player.get("thirst")) + 55.0))
            _refresh_survival_hud(player)
            _message_player(player, "You finish drinking the water.")

func _duration_for(action: String) -> float:
    match action:
        ACTION_FOOD:
            return maxf(0.2, food_duration)
        ACTION_WATER:
            return maxf(0.2, water_duration)
        ACTION_MEDKIT:
            return maxf(0.2, medkit_duration)
    return 1.0

func _item_id(action: String) -> String:
    match action:
        ACTION_FOOD:
            return "canned_food"
        ACTION_WATER:
            return "bottled_water"
        ACTION_MEDKIT:
            return "medkit"
    return ""

func _missing_message(action: String) -> String:
    match action:
        ACTION_FOOD:
            return "You have no food."
        ACTION_WATER:
            return "You have no water."
        ACTION_MEDKIT:
            return "You have no medkit."
    return "No usable supply."

func _progress_message(action: String, remaining: float) -> String:
    match action:
        ACTION_FOOD:
            return "EATING — exposed for %.1f s" % remaining
        ACTION_WATER:
            return "DRINKING — exposed for %.1f s" % remaining
        ACTION_MEDKIT:
            return "TREATING WOUNDS — exposed for %.1f s" % remaining
    return "USING SUPPLY — %.1f s" % remaining

func _blocked_by_other_ui() -> bool:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock == null or not input_lock.has_method("is_locked"):
        return false
    if not bool(input_lock.call("is_locked")):
        return false
    if input_lock.has_method("is_reason_locked") and bool(input_lock.call("is_reason_locked", LOCK_REASON)):
        return false
    return true

func _acquire_lock() -> void:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock != null and input_lock.has_method("acquire"):
        input_lock.call("acquire", LOCK_REASON)

func _release_lock() -> void:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock != null and input_lock.has_method("release"):
        input_lock.call("release", LOCK_REASON)

func _local_downed() -> bool:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    return coop != null and bool(coop.get("local_downed"))

func _message_player(player: CharacterBody3D, text: String) -> void:
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _refresh_survival_hud(player: CharacterBody3D) -> void:
    if player.has_method("_update_survival_hud"):
        player.call("_update_survival_hud")

func _local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback
