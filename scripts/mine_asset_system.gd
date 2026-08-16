extends Node

const LABYRINTH_SCENE_PATH := "res://scenes/main.tscn"
const PROP_SCENE_PATH := "res://assets/environment/mine/models/godot/Mines_Runtime.dae"
const MODULAR_SCENE_PATH := "res://assets/environment/mine/models/godot/Mines_Modu_Runtime.dae"
const LAYER_NAME := "MineAssetLayer"

var _configured_scene_id: int = 0
var _check_timer: float = 0.0
var _prop_source: Node3D
var _modular_source: Node3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    _check_timer -= delta
    if _check_timer > 0.0:
        return
    _check_timer = 0.5

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        _configured_scene_id = 0
        return

    var scene_id := int(scene.get_instance_id())
    if scene_id == _configured_scene_id and scene.get_node_or_null(LAYER_NAME) != null:
        return

    var arc_root := scene.get_node_or_null("Arc1Expansion") as Node3D
    if arc_root == null:
        return

    if not _ensure_sources():
        return

    _configured_scene_id = scene_id
    _build_layer(scene, arc_root)

func _ensure_sources() -> bool:
    if _prop_source == null:
        var prop_scene := load(PROP_SCENE_PATH) as PackedScene
        if prop_scene == null:
            push_warning("MineAssetSystem: gagal memuat %s" % PROP_SCENE_PATH)
            return false
        _prop_source = prop_scene.instantiate() as Node3D

    if _modular_source == null:
        var modular_scene := load(MODULAR_SCENE_PATH) as PackedScene
        if modular_scene == null:
            push_warning("MineAssetSystem: gagal memuat %s" % MODULAR_SCENE_PATH)
            return false
        _modular_source = modular_scene.instantiate() as Node3D

    return _prop_source != null and _modular_source != null

func _build_layer(scene: Node, arc_root: Node3D) -> void:
    var old_layer := scene.get_node_or_null(LAYER_NAME)
    if old_layer != null:
        old_layer.free()

    var layer := Node3D.new()
    layer.name = LAYER_NAME
    scene.add_child(layer)

    _dress_maintenance(layer)
    _dress_flooded_service(layer)
    _dress_archive(layer)
    _dress_lockdown(layer)
    _dress_arc_lamps(layer)
    _replace_pickup_visuals(arc_root)

func _dress_maintenance(layer: Node3D) -> void:
    _place_prop(layer, "Generator", Vector3(-9.7, 0.0, -61.0), 90.0)
    _place_prop(layer, "Petrol_Can", Vector3(-8.8, 0.0, -61.8), -20.0)
    _place_prop(layer, "Barrel", Vector3(-8.1, 0.0, -63.0), 0.0)
    _place_prop(layer, "Barrel_01", Vector3(-7.2, 0.0, -63.2), 14.0)
    _place_prop(layer, "Box_Wood", Vector3(-9.0, 0.0, -69.3), 18.0)
    _place_prop(layer, "Box_Wood_01", Vector3(-7.8, 0.0, -69.5), -12.0)
    _place_prop(layer, "Shovel", Vector3(-10.7, 0.0, -70.5), 18.0)
    _place_prop(layer, "Beak", Vector3(-10.25, 0.0, -70.45), -18.0)
    _place_prop(layer, "Mining_Helmet", Vector3(-8.9, 1.18, -69.2), 20.0)
    _place_prop(layer, "Fence", Vector3(9.8, 0.0, -72.5), 90.0)
    _place_modular(layer, "Cables_M", Vector3(-4.5, 2.65, -66.0), 0.0)
    _place_modular(layer, "Wood_T", Vector3(-6.9, 0.0, -58.0), 0.0)
    _place_modular(layer, "Wood_T", Vector3(6.6, 0.0, -72.8), 180.0)

func _dress_flooded_service(layer: Node3D) -> void:
    _place_prop(layer, "Wagon", Vector3(5.5, 0.0, -92.5), 90.0)
    _place_prop(layer, "Barrel_02", Vector3(8.8, 0.0, -87.8), 8.0)
    _place_prop(layer, "Barrel_03", Vector3(9.7, 0.0, -87.7), -10.0)
    _place_prop(layer, "Gravel", Vector3(-8.8, 0.0, -94.8), 0.0)
    _place_prop(layer, "Gravel_01", Vector3(8.7, 0.0, -101.8), 0.0)
    _place_prop(layer, "Rock_04", Vector3(-10.6, 0.0, -88.1), 12.0)
    _place_prop(layer, "Rock_07", Vector3(10.4, 0.0, -99.9), -20.0)
    _place_prop(layer, "Farol", Vector3(-9.5, 0.58, -97.5), 0.0)
    _place_modular(layer, "Rails_M", Vector3(4.7, 0.03, -92.5), 90.0)
    _place_modular(layer, "Rails_M", Vector3(4.7, 0.03, -100.2), 90.0)
    _place_modular(layer, "Cables_M", Vector3(7.5, 2.65, -96.0), 90.0)

func _dress_archive(layer: Node3D) -> void:
    _place_prop(layer, "Locker", Vector3(-12.0, 0.0, -113.0), 90.0)
    _place_prop(layer, "Locker_01", Vector3(-12.0, 0.0, -114.0), 90.0)
    _place_prop(layer, "Shelving", Vector3(11.8, 0.0, -115.0), -90.0)
    _place_prop(layer, "Box_Wood_02", Vector3(9.7, 0.0, -120.5), -14.0)
    _place_prop(layer, "Box_Wood_03", Vector3(8.7, 0.0, -120.7), 12.0)
    _place_prop(layer, "Tray", Vector3(10.8, 0.72, -115.1), 90.0)
    _place_prop(layer, "TNT", Vector3(9.9, 0.45, -123.0), 90.0)
    _place_prop(layer, "TNT_01", Vector3(10.15, 0.45, -123.0), 90.0)
    _place_prop(layer, "Detonator", Vector3(10.6, 0.42, -122.9), 180.0)
    _place_prop(layer, "Cables_Detonator", Vector3(9.8, 0.08, -122.7), 0.0)
    _place_modular(layer, "MetalBeams", Vector3(0.0, 0.0, -116.0), 90.0)

func _dress_lockdown(layer: Node3D) -> void:
    _place_modular(layer, "Elevator", Vector3(0.0, 0.0, -139.0), 0.0)
    _place_modular(layer, "Door_Elevator", Vector3(0.0, 0.0, -137.85), 0.0)
    _place_modular(layer, "Button", Vector3(1.55, 1.05, -137.65), 0.0)
    _place_prop(layer, "Fence_03", Vector3(-5.8, 0.0, -136.8), 0.0)
    _place_prop(layer, "Fence_04", Vector3(5.8, 0.0, -136.8), 180.0)
    _place_prop(layer, "Box", Vector3(-7.8, 0.0, -132.0), 8.0)
    _place_prop(layer, "Rock_10", Vector3(8.5, 0.0, -133.2), -15.0)
    _place_prop(layer, "Rock_11", Vector3(9.4, 0.0, -133.0), 11.0)
    _place_prop(layer, "Rock_12", Vector3(8.9, 0.0, -134.0), 0.0)

func _dress_arc_lamps(layer: Node3D) -> void:
    var positions: Array[Vector3] = [
        Vector3(-6.8, 2.58, -57.0),
        Vector3(7.0, 2.58, -66.0),
        Vector3(-7.0, 2.58, -75.0),
        Vector3(7.0, 2.58, -88.0),
        Vector3(-7.0, 2.58, -97.0),
        Vector3(7.0, 2.58, -110.0),
        Vector3(-7.0, 2.58, -121.0),
        Vector3(0.0, 2.58, -132.0)
    ]
    for i in range(positions.size()):
        _place_prop(layer, "Lamp", positions[i], 90.0 if i % 2 == 0 else -90.0)

func _replace_pickup_visuals(arc_root: Node3D) -> void:
    for child in arc_root.get_children():
        if not child is StaticBody3D or not str(child.name).begins_with("ArcSupply_"):
            continue
        var id := str(child.get("item_id"))
        if id == "medkit":
            _hide_prototype_meshes(child)
            _attach_prop_visual(child as Node3D, "Medical_box", Vector3(0.0, 0.0, 0.0), 0.0, 0.8)

func _hide_prototype_meshes(node: Node) -> void:
    for child in node.get_children():
        if child is MeshInstance3D:
            (child as MeshInstance3D).visible = false

func _place_prop(parent: Node3D, asset_name: String, position: Vector3, yaw_degrees: float, scale_factor: float = 1.0) -> Node3D:
    return _place_from_source(parent, _prop_source, asset_name, position, yaw_degrees, scale_factor)

func _place_modular(parent: Node3D, asset_name: String, position: Vector3, yaw_degrees: float, scale_factor: float = 1.0) -> Node3D:
    return _place_from_source(parent, _modular_source, asset_name, position, yaw_degrees, scale_factor)

func _attach_prop_visual(parent: Node3D, asset_name: String, local_position: Vector3, yaw_degrees: float, scale_factor: float = 1.0) -> Node3D:
    return _place_from_source(parent, _prop_source, asset_name, local_position, yaw_degrees, scale_factor)

func _place_from_source(parent: Node3D, source_root: Node3D, asset_name: String, position: Vector3, yaw_degrees: float, scale_factor: float) -> Node3D:
    if source_root == null:
        return null
    var source_node := source_root.find_child(asset_name, true, false) as Node3D
    if source_node == null:
        push_warning("MineAssetSystem: node asset tidak ditemukan: %s" % asset_name)
        return null

    var holder := Node3D.new()
    holder.name = "Mine_%s_%d" % [asset_name.replace(".", "_"), parent.get_child_count()]
    holder.position = position
    holder.rotation.y = deg_to_rad(yaw_degrees)
    holder.scale = Vector3.ONE * scale_factor
    parent.add_child(holder)

    var copy := source_node.duplicate() as Node3D
    if copy == null:
        holder.queue_free()
        return null

    var source_basis := _basis_relative_to_root(source_node, source_root)
    copy.transform = Transform3D(source_basis, Vector3.ZERO)
    holder.add_child(copy)
    _disable_runtime_cost(copy)
    return holder

func _basis_relative_to_root(node: Node3D, root: Node3D) -> Basis:
    var xform := node.transform
    var parent := node.get_parent() as Node3D
    while parent != null and parent != root:
        xform = parent.transform * xform
        parent = parent.get_parent() as Node3D
    if parent == root:
        xform = root.transform * xform
    return xform.basis

func _disable_runtime_cost(node: Node) -> void:
    node.process_mode = Node.PROCESS_MODE_DISABLED
    for child in node.get_children():
        _disable_runtime_cost(child)
