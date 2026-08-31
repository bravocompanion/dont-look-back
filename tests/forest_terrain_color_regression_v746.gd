extends SceneTree

const FOREST_SCENE: String = "res://scenes/forest.tscn"
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
    print("[TERRAIN COLOR v0.74.6] starting")
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

    _check_contract(expansion)
    _check_runtime_vertex_colors()
    _check_pathless_state()
    _finish()

func _check_contract(expansion: Node) -> void:
    if not expansion.has_method("get_terrain_color_contract_v746"):
        _fail("v0.74.6 terrain color contract missing")
        return
    var contract: Dictionary = Dictionary(expansion.call("get_terrain_color_contract_v746"))
    if str(contract.get("revision", "")) != "0.74.6":
        _fail("unexpected terrain color revision")
    if int(contract.get("vertex_count", 0)) <= 0:
        _fail("terrain vertex count is zero")
    if int(contract.get("color_count", 0)) != int(contract.get("vertex_count", -1)):
        _fail("terrain color count does not match vertex count")
    if not bool(contract.get("vertex_color_use_as_albedo", false)):
        _fail("terrain material does not consume vertex colors")
    if not bool(contract.get("opaque", false)):
        _fail("terrain color contract is not opaque")
    if bool(contract.get("route_coloring", true)):
        _fail("route-based terrain coloring is enabled")
    if bool(contract.get("path_geometry", true)):
        _fail("path geometry returned in v0.74.6")
    if bool(contract.get("path_tree_corridor", true)):
        _fail("path tree corridor returned in v0.74.6")
    if int(contract.get("mobile_extra_texture_samples", -1)) != 0:
        _fail("natural color pass adds texture sampling cost")

func _check_runtime_vertex_colors() -> void:
    var scene: Node = current_scene
    if scene == null:
        _fail("current forest scene missing")
        return
    var mesh_instance: MeshInstance3D = scene.get_node_or_null(
        "OutsideWorld/ForestMegaExpansionV2/ForestTerrainV74/TerrainMesh"
    ) as MeshInstance3D
    if mesh_instance == null or mesh_instance.mesh == null:
        _fail("runtime terrain mesh missing")
        return
    if not mesh_instance.visible or not is_zero_approx(mesh_instance.transparency):
        _fail("runtime terrain mesh is hidden or transparent")

    var arrays: Array = mesh_instance.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
    if colors.size() != vertices.size():
        _fail("runtime vertex/color arrays have different sizes")
        return

    var unique_colors: Dictionary = {}
    var step: int = maxi(1, colors.size() / 320)
    var index: int = 0
    while index < colors.size():
        var color: Color = colors[index]
        if color.a < 0.999:
            _fail("terrain vertex color contains alpha below 1.0")
            break
        var key: String = "%d:%d:%d" % [
            int(round(color.r * 100.0)),
            int(round(color.g * 100.0)),
            int(round(color.b * 100.0))
        ]
        unique_colors[key] = true
        index += step
    if unique_colors.size() < 8:
        _fail("terrain color variation is too uniform: %d sampled colors" % unique_colors.size())

    var material: StandardMaterial3D = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
    if material == null:
        _fail("terrain override material missing")
        return
    if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
        _fail("terrain material transparency is enabled")
    if material.albedo_color.a < 0.999:
        _fail("terrain material alpha is below 1.0")
    if not material.vertex_color_use_as_albedo:
        _fail("terrain override material ignores vertex colors")

func _check_pathless_state() -> void:
    var scene: Node = current_scene
    if scene == null:
        return
    var world: Node = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2")
    if world == null:
        _fail("ForestMegaExpansionV2 root missing")
        return
    for trail_name: String in TRAIL_NAMES:
        if world.get_node_or_null(trail_name) != null:
            _fail("legacy path mesh returned: %s" % trail_name)

func _fail(message: String) -> void:
    failures.append(message)
    push_error("[TERRAIN COLOR v0.74.6] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[TERRAIN COLOR v0.74.6] PASS — natural opaque vertex colors, no route paint/path geometry")
        quit(0)
        return
    push_error("[TERRAIN COLOR v0.74.6] FAIL — %d issue(s)" % failures.size())
    quit(1)
