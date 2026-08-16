extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"

var last_stage: int = -1
var pending_rebuild_frames: int = 0

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        last_stage = -1
        pending_rebuild_frames = 0
        return

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null or scene.get_node_or_null("Arc1Expansion") == null:
        return

    var stage: int = int(arc.get("current_stage"))
    if last_stage < 0:
        last_stage = stage
    elif stage != last_stage:
        last_stage = stage
        if stage >= 2:
            pending_rebuild_frames = 4

    if pending_rebuild_frames <= 0:
        return
    pending_rebuild_frames -= 1
    if pending_rebuild_frames > 0:
        return

    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation == null:
        return
    navigation.set("graph_ready", false)
    navigation.set("graph_retry_timer", 0.0)
    navigation.set("graph_point_count", 0)
    var graph_value: Variant = navigation.get("nav_graph")
    if graph_value is AStar3D:
        var graph: AStar3D = graph_value
        graph.clear()
