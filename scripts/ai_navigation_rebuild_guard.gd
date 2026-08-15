extends Node

var scene_id: int = 0
var rebuilt_scene_id: int = 0
var ready_frames: int = 0

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var current_id: int = int(scene.get_instance_id())
    if current_id != scene_id:
        scene_id = current_id
        rebuilt_scene_id = 0
        ready_frames = 0

    if rebuilt_scene_id == current_id:
        return

    var labyrinth: Node = scene.get_node_or_null("LabyrinthExpansion")
    var exterior: Node = scene.get_node_or_null("OutsideWorld/ExteriorExpansion")
    if labyrinth == null or exterior == null:
        ready_frames = 0
        return

    ready_frames += 1
    if ready_frames < 4:
        return

    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation == null:
        return

    navigation.set("graph_ready", false)
    navigation.set("graph_retry_timer", 0.0)
    var graph_value: Variant = navigation.get("nav_graph")
    if graph_value is AStar3D:
        var graph: AStar3D = graph_value
        graph.clear()
    navigation.set("graph_point_count", 0)
    rebuilt_scene_id = current_id
