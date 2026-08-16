extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const WARDEN_SCRIPT_PATH: String = "res://scripts/arc1_evacuation_warden.gd"

var configured_scene_id: int = 0
var warden_script: Script

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    warden_script = load(WARDEN_SCRIPT_PATH) as Script

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        configured_scene_id = 0
        return

    var arc_root: Node3D = scene.get_node_or_null("Arc1Expansion") as Node3D
    if arc_root == null or warden_script == null:
        return

    _suppress_original_warden_during_evacuation()

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        call_deferred("_ensure_warden", scene, arc_root)
        return

    if arc_root.get_node_or_null("EvacuationWarden") == null:
        call_deferred("_ensure_warden", scene, arc_root)

func _suppress_original_warden_during_evacuation() -> void:
    var evacuation: Node = get_node_or_null("/root/LabyrinthEvacuationSystem")
    if evacuation == null or not evacuation.has_method("is_escape_active"):
        return
    if not bool(evacuation.call("is_escape_active")):
        return
    var major: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    if major != null:
        major.set("warden_active", false)

func _ensure_warden(scene: Node, arc_root: Node3D) -> void:
    await get_tree().process_frame
    if not is_instance_valid(scene) or get_tree().current_scene != scene or not is_instance_valid(arc_root):
        return
    if arc_root.get_node_or_null("EvacuationWarden") != null:
        return

    var warden: Node3D = Node3D.new()
    warden.name = "EvacuationWarden"
    warden.position = Vector3(0.0, 0.0, -133.0)
    warden.set_script(warden_script)
    warden.set("move_speed", 1.94)
    warden.set("detection_radius", 38.0)
    arc_root.add_child(warden)
