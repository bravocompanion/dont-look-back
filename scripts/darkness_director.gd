extends Node

@export var spawn_threshold: float = 72.0
@export var minimum_player_z: float = -3.4
@export var spawn_cooldown_seconds: float = 11.0

var creature_script: Script
var spawn_cooldown: float = 5.0

func _ready() -> void:
    creature_script = load("res://scripts/dark_creature.gd") as Script

func _process(delta: float) -> void:
    spawn_cooldown = maxf(0.0, spawn_cooldown - delta)

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    if player.global_position.z > minimum_player_z:
        return
    if spawn_cooldown > 0.0:
        return
    if get_tree().get_first_node_in_group("darkness_creature") != null:
        return
    if not player.has_method("get_darkness_exposure") or not player.has_method("is_in_light"):
        return

    var exposure: float = float(player.call("get_darkness_exposure"))
    var in_light: bool = bool(player.call("is_in_light"))
    if exposure < spawn_threshold or in_light:
        return

    var scene: Node = get_tree().current_scene
    if scene == null or creature_script == null:
        return

    var spawn_position: Vector3 = _find_spawn_position(player)
    var creature: Node3D = Node3D.new()
    creature.name = "DarknessCreature"
    creature.set_script(creature_script)
    scene.add_child(creature)
    creature.global_position = spawn_position
    spawn_cooldown = spawn_cooldown_seconds

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "Something is forming in the dark. GET TO THE LIGHT."

func _find_spawn_position(player: CharacterBody3D) -> Vector3:
    var world: World3D = player.get_world_3d()
    if world == null:
        return player.global_position + Vector3(0.0, 0.0, 4.0)

    var state: PhysicsDirectSpaceState3D = world.direct_space_state
    var base_angle: float = randf_range(0.0, TAU)
    var start: Vector3 = player.global_position + Vector3(0.0, 1.0, 0.0)

    for i: int in range(10):
        var angle: float = base_angle + TAU * float(i) / 10.0
        var distance: float = randf_range(3.5, 5.2)
        var candidate: Vector3 = player.global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
        var horizontal_end: Vector3 = candidate + Vector3(0.0, 1.0, 0.0)

        var horizontal_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, horizontal_end)
        horizontal_query.exclude = [player.get_rid()]
        var horizontal_hit: Dictionary = state.intersect_ray(horizontal_query)
        if not horizontal_hit.is_empty():
            continue

        var floor_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
            candidate + Vector3(0.0, 2.0, 0.0),
            candidate + Vector3(0.0, -2.5, 0.0)
        )
        floor_query.exclude = [player.get_rid()]
        var floor_hit: Dictionary = state.intersect_ray(floor_query)
        if floor_hit.is_empty():
            continue

        var floor_position: Vector3 = floor_hit["position"]
        return floor_position

    return player.global_position + Vector3(0.0, 0.0, 3.8)
