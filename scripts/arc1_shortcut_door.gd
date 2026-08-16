extends StaticBody3D

@export var shortcut_id: String = "maintenance_shortcut"
@export var display_name: String = "Service Shortcut"
@export var required_deeper_z: float = -77.2

var unlocked: bool = false
var visual: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready() -> void:
    _build_visual()
    _refresh_state()

func _process(_delta: float) -> void:
    _refresh_state()

func get_interaction_text() -> String:
    if unlocked:
        return "%s — open" % display_name
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return display_name
    if player.global_position.z <= required_deeper_z:
        return "Unlock %s" % display_name
    return "%s — locked from other side" % display_name

func interact() -> void:
    if unlocked:
        return
    var system: Node = get_node_or_null("/root/LabyrinthExplorationSystem")
    if system == null or not system.has_method("request_shortcut_unlock"):
        return
    system.call("request_shortcut_unlock", shortcut_id)

func set_unlocked_state(value: bool) -> void:
    unlocked = value
    if visual != null:
        visual.visible = not unlocked
    if collision_shape != null:
        collision_shape.set_deferred("disabled", unlocked)

func _refresh_state() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthExplorationSystem")
    if system == null or not system.has_method("is_shortcut_unlocked"):
        return
    var state: bool = bool(system.call("is_shortcut_unlocked", shortcut_id))
    if state != unlocked:
        set_unlocked_state(state)

func _build_visual() -> void:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.17, 0.16, 0.14, 1.0)
    material.metallic = 0.58
    material.roughness = 0.54

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(2.4, 2.65, 0.26)
    visual = MeshInstance3D.new()
    visual.name = "DoorVisual"
    visual.mesh = mesh
    visual.material_override = material
    visual.position.y = 1.325
    add_child(visual)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(2.4, 2.65, 0.32)
    collision_shape = CollisionShape3D.new()
    collision_shape.name = "CollisionShape3D"
    collision_shape.shape = shape
    collision_shape.position.y = 1.325
    add_child(collision_shape)
