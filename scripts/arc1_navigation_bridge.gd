extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const ENCOUNTER_DIRECTOR_SCRIPT: String = "res://scripts/labyrinth_encounter_director.gd"

var last_stage: int = -1
var pending_rebuild_frames: int = 0

func _ready() -> void:
    call_deferred("_ensure_encounter_director")

func _process(_delta: float) -> void:
    _ensure_encounter_director()

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

func _ensure_encounter_director() -> void:
    if get_node_or_null("/root/LabyrinthEncounterDirector") != null:
        return
    var director_script: Script = load(ENCOUNTER_DIRECTOR_SCRIPT) as Script
    if director_script == null:
        return
    var director: Node = Node.new()
    director.name = "LabyrinthEncounterDirector"
    director.set_script(director_script)
    get_tree().root.add_child(director)
