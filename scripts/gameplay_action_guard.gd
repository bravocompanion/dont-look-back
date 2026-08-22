extends Node

# v0.58: gameplay input ownership bridge.
# Movement already queries GameplayInputLock. This guard extends the same lock
# to the player's legacy _unhandled_input path without consuming GUI events.

var tracked_player_id: int = 0
var disabled_by_guard: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = -40

func _process(_delta: float) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null:
        tracked_player_id = 0
        disabled_by_guard = false
        return

    var player_id: int = int(player.get_instance_id())
    if tracked_player_id != player_id:
        tracked_player_id = player_id
        disabled_by_guard = false

    var should_block: bool = _actions_blocked(player)
    if should_block:
        if player.is_processing_unhandled_input():
            player.set_process_unhandled_input(false)
            disabled_by_guard = true
        return

    if disabled_by_guard:
        # Restore only if this guard was the system that disabled the input path.
        # Downed/dead states own their own input disable and must stay disabled.
        if not bool(player.get("is_dead")) and not _local_downed():
            player.set_process_unhandled_input(true)
        disabled_by_guard = false

func _actions_blocked(player: CharacterBody3D) -> bool:
    if player == null or bool(player.get("is_dead")):
        return true

    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock != null and input_lock.has_method("is_locked") and bool(input_lock.call("is_locked")):
        return true

    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition != null and bool(transition.get("transitioning")):
        return true

    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return true

    return _local_downed()

func _local_downed() -> bool:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    return coop != null and bool(coop.get("local_downed"))

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
