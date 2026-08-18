extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        return

    var outside_root: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if outside_root == null:
        return

    _disable_boundary(outside_root.get_node_or_null("ForestEntryBoundary"))
    _disable_boundary(outside_root.get_node_or_null("LeftBoundary"))
    _disable_boundary(outside_root.get_node_or_null("RightBoundary"))
    _disable_boundary(outside_root.get_node_or_null("FarBoundary"))

    var expansion: Node3D = outside_root.get_node_or_null("ExteriorExpansion") as Node3D
    if expansion == null:
        return
    _disable_boundary(expansion.get_node_or_null("ExpansionLeftBoundary"))
    _disable_boundary(expansion.get_node_or_null("ExpansionRightBoundary"))
    _disable_boundary(expansion.get_node_or_null("ExpansionFarBoundary"))

func _disable_boundary(node: Node) -> void:
    var spatial: Node3D = node as Node3D
    if spatial == null:
        return
    spatial.visible = false

    if spatial is CSGBox3D:
        (spatial as CSGBox3D).use_collision = false
        return

    for child: Node in spatial.get_children():
        if child is CollisionShape3D:
            (child as CollisionShape3D).disabled = true
