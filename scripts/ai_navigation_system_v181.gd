extends "res://scripts/ai_navigation_system.gd"

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"

const ARC1_NAV_POINTS: Array[Vector3] = [
    Vector3(-7.0, 0.0, -52.0), Vector3(-7.0, 0.0, -57.5), Vector3(-11.0, 0.0, -61.0),
    Vector3(1.0, 0.0, -62.0), Vector3(11.0, 0.0, -62.0), Vector3(11.0, 0.0, -67.0),
    Vector3(-10.5, 0.0, -68.0), Vector3(-11.0, 0.0, -74.5), Vector3(1.0, 0.0, -74.5),
    Vector3(11.0, 0.0, -77.5), Vector3(0.0, 0.0, -81.5), Vector3(-10.5, 0.0, -84.5),
    Vector3(-11.0, 0.0, -90.0), Vector3(0.5, 0.0, -90.0), Vector3(11.0, 0.0, -91.0),
    Vector3(11.0, 0.0, -96.5), Vector3(-0.5, 0.0, -97.0), Vector3(-11.0, 0.0, -99.0),
    Vector3(-10.5, 0.0, -103.0), Vector3(0.0, 0.0, -104.5), Vector3(0.0, 0.0, -107.0),
    Vector3(-10.5, 0.0, -110.5), Vector3(-5.0, 0.0, -112.5), Vector3(5.0, 0.0, -112.5),
    Vector3(10.5, 0.0, -112.0), Vector3(10.5, 0.0, -118.0), Vector3(4.8, 0.0, -119.0),
    Vector3(-4.8, 0.0, -119.0), Vector3(-10.5, 0.0, -123.5), Vector3(0.0, 0.0, -125.5),
    Vector3(9.5, 0.0, -125.0), Vector3(0.0, 0.0, -128.5), Vector3(-8.0, 0.0, -131.0),
    Vector3(8.0, 0.0, -131.0), Vector3(-9.0, 0.0, -135.5), Vector3(0.0, 0.0, -135.5),
    Vector3(9.0, 0.0, -135.5), Vector3(0.0, 0.0, -139.0)
]

const ARC1_PATROL: Array[Vector3] = [
    Vector3(-7.0, 0.0, -56.0),
    Vector3(10.5, 0.0, -66.5),
    Vector3(-10.5, 0.0, -74.0),
    Vector3(-10.5, 0.0, -88.0),
    Vector3(10.5, 0.0, -98.0),
    Vector3(-9.5, 0.0, -111.0),
    Vector3(9.5, 0.0, -119.0),
    Vector3(-9.5, 0.0, -124.0),
    Vector3(0.0, 0.0, -135.0)
]

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
        if scene.get_node_or_null("LabyrinthExpansion") == null or scene.get_node_or_null("Arc1Expansion") == null:
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
        for point: Vector3 in ARC1_NAV_POINTS:
            filtered.append(point)
    elif scene.scene_file_path == FOREST_SCENE_PATH:
        for point: Vector3 in all_points:
            if point.z <= -53.0:
                filtered.append(point)
    return filtered

func _patrol_for_position(position: Vector3) -> Array[Vector3]:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == LABYRINTH_SCENE_PATH and position.z <= -53.0:
        return ARC1_PATROL.duplicate()
    return super._patrol_for_position(position)

func _clamp_monster_position(position: Vector3) -> Vector3:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == LABYRINTH_SCENE_PATH and position.z <= -53.0:
        return Vector3(
            clampf(position.x, -13.35, 13.35),
            position.y,
            clampf(position.z, -139.5, -52.0)
        )
    return super._clamp_monster_position(position)
