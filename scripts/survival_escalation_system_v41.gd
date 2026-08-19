extends Node

var tracked_player_id: int = 0
var base_hunger_drain: float = 0.055
var base_thirst_drain: float = 0.082
var base_stamina_regen: float = 18.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 210

func _process(_delta: float) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null:
        tracked_player_id = 0
        return

    var player_id: int = int(player.get_instance_id())
    if player_id != tracked_player_id:
        tracked_player_id = player_id
        base_hunger_drain = float(player.get("hunger_drain_per_second"))
        base_thirst_drain = float(player.get("thirst_drain_per_second"))
        base_stamina_regen = float(player.get("stamina_regen_per_second"))

    var day_index: int = get_day_index()
    var drain_multiplier: float = 1.0
    var regen_multiplier: float = 1.0
    if day_index <= 1:
        drain_multiplier = 0.90
        regen_multiplier = 1.06
    elif day_index == 2:
        drain_multiplier = 1.00
        regen_multiplier = 1.00
    elif day_index == 3:
        drain_multiplier = 1.08
        regen_multiplier = 0.96
    elif day_index == 4:
        drain_multiplier = 1.12
        regen_multiplier = 0.93
    else:
        drain_multiplier = 1.18
        regen_multiplier = 0.90

    player.set("hunger_drain_per_second", base_hunger_drain * drain_multiplier)
    player.set("thirst_drain_per_second", base_thirst_drain * drain_multiplier)
    player.set("stamina_regen_per_second", base_stamina_regen * regen_multiplier)

func get_day_index() -> int:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    return int(outside.get("day_index")) if outside != null else 1

func get_difficulty_name() -> String:
    var day_index: int = get_day_index()
    if day_index <= 1:
        return "PREPARATION"
    if day_index == 2:
        return "PRESSURE"
    if day_index <= 4:
        return "CONTAMINATION"
    return "COLLAPSE"

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
