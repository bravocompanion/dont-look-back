extends Node

@export var expansion_start_z: float = -132.0
@export var deep_zone_z: float = -175.0

const BASE_THRESHOLD: float = 72.0
const EXPANSION_THRESHOLD: float = 58.0
const DEEP_THRESHOLD: float = 52.0
const BASE_COOP_SPEED: float = 2.15
const EXPANSION_COOP_SPEED: float = 2.65
const DEEP_COOP_SPEED: float = 2.85
const BASE_COOP_DAMAGE: float = 18.0
const EXPANSION_COOP_DAMAGE: float = 20.0
const DEEP_COOP_DAMAGE: float = 22.0

func _process(_delta: float) -> void:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null or not outside.has_method("is_outside_active") or not bool(outside.call("is_outside_active")):
        _apply_base_threat()
        return

    var night: bool = outside.has_method("is_night") and bool(outside.call("is_night"))
    if not night:
        _apply_base_threat()
        return

    var depth: int = _get_farthest_survivor_depth()
    if depth >= 2:
        _apply_threat(DEEP_THRESHOLD, DEEP_COOP_SPEED, DEEP_COOP_DAMAGE, 6.5)
    elif depth == 1:
        _apply_threat(EXPANSION_THRESHOLD, EXPANSION_COOP_SPEED, EXPANSION_COOP_DAMAGE, 8.0)
    else:
        _apply_base_threat()

func _get_farthest_survivor_depth() -> int:
    var depth: int = 0
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        depth = maxi(depth, _depth_for_z(player.global_position.z))

    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    var hosting: bool = network != null and network.has_method("is_server") and bool(network.call("is_server"))
    if not online or not hosting:
        return depth

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return depth

    var states: Dictionary = Dictionary(coop.get("survivor_states"))
    for state_variant: Variant in states.values():
        var state: Dictionary = Dictionary(state_variant)
        if state.is_empty() or bool(state.get("downed", false)):
            continue
        var survivor_transform: Transform3D = state.get("transform", Transform3D.IDENTITY)
        depth = maxi(depth, _depth_for_z(survivor_transform.origin.z))
    return depth

func _depth_for_z(z_position: float) -> int:
    if z_position <= deep_zone_z:
        return 2
    if z_position <= expansion_start_z:
        return 1
    return 0

func _apply_base_threat() -> void:
    _apply_threat(BASE_THRESHOLD, BASE_COOP_SPEED, BASE_COOP_DAMAGE, 11.0)

func _apply_threat(threshold: float, coop_speed: float, coop_damage: float, solo_cooldown: float) -> void:
    var darkness: Node = get_node_or_null("/root/DarknessDirector")
    if darkness != null:
        darkness.set("spawn_threshold", threshold)
        darkness.set("spawn_cooldown_seconds", solo_cooldown)

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        coop.set("dark_spawn_threshold", threshold)
        coop.set("dark_move_speed", coop_speed)
        coop.set("dark_attack_damage", coop_damage)

    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online:
        return

    var creature: Node = get_tree().get_first_node_in_group("darkness_creature")
    if creature != null:
        creature.set("move_speed", coop_speed)
        creature.set("attack_damage", coop_damage)
        creature.set("max_lifetime", 22.0 if threshold < BASE_THRESHOLD else 18.0)
