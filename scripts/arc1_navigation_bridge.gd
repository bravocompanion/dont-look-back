extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const ENCOUNTER_DIRECTOR_SCRIPT: String = "res://scripts/labyrinth_encounter_director.gd"
const EXPLORATION_SYSTEM_SCRIPT: String = "res://scripts/labyrinth_exploration_system.gd"
const COOP_SYSTEM_SCRIPT: String = "res://scripts/labyrinth_coop_system.gd"
const MAJOR_SYSTEM_SCRIPT: String = "res://scripts/labyrinth_major_system.gd"
const MAJOR_GATEKEEPER_SCRIPT: String = "res://scripts/labyrinth_major_gatekeeper.gd"

var last_stage: int = -1
var pending_rebuild_frames: int = 0

func _ready() -> void:
    call_deferred("_ensure_runtime_systems")

func _process(_delta: float) -> void:
    _ensure_runtime_systems()

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

    _request_navigation_rebuild()

func _ensure_runtime_systems() -> void:
    _ensure_root_system("LabyrinthEncounterDirector", ENCOUNTER_DIRECTOR_SCRIPT)
    _ensure_root_system("LabyrinthExplorationSystem", EXPLORATION_SYSTEM_SCRIPT)
    _ensure_root_system("LabyrinthCoopSystem", COOP_SYSTEM_SCRIPT)
    _ensure_root_system("LabyrinthMajorSystem", MAJOR_SYSTEM_SCRIPT)
    _ensure_root_system("LabyrinthMajorGatekeeper", MAJOR_GATEKEEPER_SCRIPT)

func _ensure_root_system(node_name: String, script_path: String) -> void:
    if get_node_or_null("/root/%s" % node_name) != null:
        return
    var runtime_script: Script = load(script_path) as Script
    if runtime_script == null:
        return
    var runtime_node: Node = Node.new()
    runtime_node.name = node_name
    runtime_node.set_script(runtime_script)
    get_tree().root.add_child(runtime_node)

func _request_navigation_rebuild() -> void:
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
