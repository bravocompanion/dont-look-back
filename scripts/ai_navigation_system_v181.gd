extends "res://scripts/ai_navigation_system.gd"

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"

func _ensure_navigation_graph(delta: float) -> void:
    if graph_ready:
        return
    graph_retry_timer = maxf(0.0, graph_retry_timer - delta)
    if graph_retry_timer > 0.0:
        return

    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    if scene.scene_file_path == LABYRINTH_SCENE_PATH:
        if scene.get_node_or_null("LabyrinthExpansion") == null:
            graph_retry_timer = 0.35
            return
    elif scene.scene_file_path == FOREST_SCENE_PATH:
        if scene.get_node_or_null("OutsideWorld/ExteriorExpansion") == null:
            graph_retry_timer = 0.35
            return
    else:
        graph_retry_timer = 0.55
        return

    _build_navigation_graph()
    if not graph_ready:
        graph_retry_timer = 0.55

func _navigation_points() -> Array[Vector3]:
    var all_points: Array[Vector3] = super._navigation_points()
    var filtered: Array[Vector3] = []
    var scene: Node = get_tree().current_scene
    if scene == null:
        return filtered

    if scene.scene_file_path == LABYRINTH_SCENE_PATH:
        for point: Vector3 in all_points:
            if point.z > -53.0:
                filtered.append(point)
    elif scene.scene_file_path == FOREST_SCENE_PATH:
        for point: Vector3 in all_points:
            if point.z <= -53.0:
                filtered.append(point)
    return filtered
