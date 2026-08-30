extends SceneTree

const FOREST_SCENE: String = "res://scenes/forest.tscn"
const TERRAIN_MATERIAL_PATH: String = "res://assets/materials/terrain/forest_ground_opaque_v744.tres"
const TRAIL_MATERIAL_PATH: String = "res://assets/materials/terrain/forest_trail_opaque_v744.tres"
const TRAIL_NAMES: Array[String] = [
    "TrailCabinToHouse",
    "TrailHouseToGas",
    "TrailGasToWarehouse",
    "TrailWarehouseToMine",
    "TrailMineToPumpOptional"
]

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[TERRAIN MATERIAL v0.74.4] starting")
    _check_material_resource(TERRAIN_MATERIAL_PATH, "terrain")
    _check_material_resource(TRAIL_MATERIAL_PATH, "trail")

    var change_error: Error = change_scene_to_file(FOREST_SCENE)
    if change_error != OK:
        _fail("forest scene load failed: %s" % error_string(change_error))
        _finish()
        return

    var expansion: Node = null
    var ready: bool = false
    for _frame: int in range(420):
        await process_frame
        expansion = root.get_node_or_null("ForestWorldExpansion")
        if expansion == null:
            continue
        if expansion.has_method("is_forest_terrain_ready_v742") and bool(expansion.call("is_forest_terrain_ready_v742")):
            ready = true
            break

    if not ready or expansion == null:
        _fail("forest terrain did not become ready")
        _finish()
        return

    if not expansion.has_method("get_terrain_material_contract_v744"):
        _fail("ForestWorldExpansion v0.74.4 material contract missing")
    else:
        var contract: Dictionary = Dictionary(expansion.call("get_terrain_material_contract_v744"))
        if str(contract.get("revision", "")) != "0.74.4":
            _fail("unexpected material revision: %s" % str(contract.get("revision", "missing")))
        if not bool(contract.get("terrain_visible", false)):
            _fail("terrain contract reports invisible mesh")
        if not bool(contract.get("surface_material_opaque", false)):
            _fail("terrain surface material is not opaque")
        if not bool(contract.get("override_material_opaque", false)):
            _fail("terrain override material is not opaque")

    _check_runtime_terrain()
    _check_runtime_trails()
    _finish()

func _check_material_resource(path: String, label: String) -> void:
    if not ResourceLoader.exists(path):
        _fail("%s material resource missing: %s" % [label, path])
        return
    var loaded: Resource = load(path)
    if not (loaded is StandardMaterial3D):
        _fail("%s resource is not StandardMaterial3D" % label)
        return
    _check_standard_material(loaded as StandardMaterial3D, "%s resource" % label)

func _check_runtime_terrain() -> void:
    var scene: Node = current_scene
    if scene == null:
        _fail("current forest scene missing")
        return

    var mesh_instance: MeshInstance3D = scene.get_node_or_null(
        "OutsideWorld/ForestMegaExpansionV2/ForestTerrainV74/TerrainMesh"
    ) as MeshInstance3D
    if mesh_instance == null:
        _fail("runtime TerrainMesh missing")
        return
    if not mesh_instance.visible:
        _fail("runtime TerrainMesh is hidden")
    if not is_zero_approx(mesh_instance.transparency):
        _fail("runtime TerrainMesh transparency is %.3f" % mesh_instance.transparency)
    if mesh_instance.mesh == null or mesh_instance.mesh.get_surface_count() <= 0:
        _fail("runtime TerrainMesh has no surface")
        return

    var surface_material: Material = mesh_instance.mesh.surface_get_material(0)
    var override_material: Material = mesh_instance.get_surface_override_material(0)
    if not (surface_material is StandardMaterial3D):
        _fail("runtime terrain surface material is not StandardMaterial3D")
    else:
        _check_standard_material(surface_material as StandardMaterial3D, "runtime terrain surface")
    if not (override_material is StandardMaterial3D):
        _fail("runtime terrain override material is not StandardMaterial3D")
    else:
        _check_standard_material(override_material as StandardMaterial3D, "runtime terrain override")

func _check_runtime_trails() -> void:
    var scene: Node = current_scene
    if scene == null:
        return
    var world: Node = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2")
    if world == null:
        _fail("ForestMegaExpansionV2 root missing")
        return

    for trail_name: String in TRAIL_NAMES:
        var trail: MeshInstance3D = world.get_node_or_null(trail_name) as MeshInstance3D
        if trail == null:
            _fail("trail missing: %s" % trail_name)
            continue
        if not trail.visible:
            _fail("trail hidden: %s" % trail_name)
        if trail.mesh == null or trail.mesh.get_surface_count() <= 0:
            _fail("trail has no material surface: %s" % trail_name)
            continue
        var material: Material = trail.mesh.surface_get_material(0)
        if not (material is StandardMaterial3D):
            _fail("trail material is not StandardMaterial3D: %s" % trail_name)
            continue
        _check_standard_material(material as StandardMaterial3D, "trail %s" % trail_name)

func _check_standard_material(material: StandardMaterial3D, label: String) -> void:
    if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
        _fail("%s transparency is enabled" % label)
    if material.cull_mode != BaseMaterial3D.CULL_DISABLED:
        _fail("%s is not double-sided" % label)
    if material.albedo_color.a < 0.999:
        _fail("%s alpha is %.3f" % [label, material.albedo_color.a])

func _fail(message: String) -> void:
    failures.append(message)
    push_error("[TERRAIN MATERIAL v0.74.4] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[TERRAIN MATERIAL v0.74.4] PASS — terrain and trails are visible, double-sided, and fully opaque")
        quit(0)
        return
    push_error("[TERRAIN MATERIAL v0.74.4] FAIL — %d issue(s)" % failures.size())
    quit(1)
