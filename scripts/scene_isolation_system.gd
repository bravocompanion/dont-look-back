extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const LABYRINTH_RUNTIME_ROOTS: Array[String] = [
    "LabyrinthEncounterDirector",
    "LabyrinthExplorationSystem",
    "LabyrinthCoopSystem",
    "LabyrinthMajorSystem",
    "LabyrinthMajorGatekeeper",
    "LabyrinthEvacuationSystem",
    "LabyrinthEvacuationWardenSystem"
]
const LABYRINTH_SCENE_NODES: Array[String] = [
    "LabyrinthExpansion",
    "Arc1Expansion",
    "MineAssetLayer"
]

var check_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 90

func _process(delta: float) -> void:
    check_timer -= delta
    if check_timer > 0.0:
        return
    check_timer = 0.35

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == LABYRINTH_SCENE_PATH:
        return

    # Dynamic Labyrinth systems are created only when entering main.tscn. Once
    # the player leaves that scene they are destroyed, so their UI/enemies or
    # runtime geometry cannot leak into Forest, Mine, or Research Facility.
    for root_name: String in LABYRINTH_RUNTIME_ROOTS:
        var runtime: Node = get_node_or_null("/root/%s" % root_name)
        if runtime != null and is_instance_valid(runtime):
            runtime.queue_free()

    # Defensive cleanup. Separate scenes should never contain these nodes; if a
    # legacy system injects one, remove it before it can become visible.
    for node_name: String in LABYRINTH_SCENE_NODES:
        var leaked: Node = scene.get_node_or_null(NodePath(node_name))
        if leaked != null and is_instance_valid(leaked):
            leaked.queue_free()
