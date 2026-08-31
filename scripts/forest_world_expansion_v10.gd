extends "res://scripts/forest_world_expansion_v9.gd"

# v0.74.5 — natural forest presentation: no authored road/path meshes.
# Traversal smoothing from v0.74.3 remains in the terrain height function so
# quest movement stays comfortable, but there is no visible ribbon geometry and
# no artificial long tree-free corridor between mission locations.

const V745_LEGACY_TRAIL_NAMES: Array[String] = [
    "TrailCabinToHouse",
    "TrailHouseToGas",
    "TrailGasToWarehouse",
    "TrailWarehouseToMine",
    "TrailMineToPumpOptional"
]

func _build_long_distance_trails() -> void:
    # Intentionally no road mesh. If a path is reintroduced in a future art
    # pass it must be color/material-only on the terrain surface, never a raised
    # ribbon or separate collision/geometry strip.
    _remove_legacy_trail_meshes_v745()
    if world_root != null:
        world_root.set_meta("forest_path_visual_mode", "none")
        world_root.set_meta("forest_path_geometry", false)
        world_root.set_meta("forest_path_color_only_allowed", true)

func _remove_legacy_trail_meshes_v745() -> void:
    if world_root == null:
        return
    for trail_name: String in V745_LEGACY_TRAIL_NAMES:
        var trail: Node = world_root.get_node_or_null(trail_name)
        if trail != null:
            trail.queue_free()

func _tree_position_clear_v74(point: Vector2) -> bool:
    # Keep authored yards/POIs readable, but do not reserve a long invisible
    # corridor between them. Decorative MultiMesh trees have no per-tree
    # collision, so natural scatter can cross the former route safely.
    for data: Dictionary in V74_SAFE_PLATEAUS:
        var center: Vector2 = Vector2(data.get("center", Vector2.ZERO))
        var clearance: float = float(data.get("outer", 20.0)) + 2.0
        if point.distance_to(center) <= clearance:
            return false
    return true

func get_forest_path_contract_v745() -> Dictionary:
    var legacy_mesh_count: int = 0
    if world_root != null:
        for trail_name: String in V745_LEGACY_TRAIL_NAMES:
            if world_root.get_node_or_null(trail_name) != null:
                legacy_mesh_count += 1

    return {
        "revision": "0.74.5",
        "visual_path_mode": "none",
        "separate_path_geometry": false,
        "separate_path_collision": false,
        "legacy_path_mesh_count": legacy_mesh_count,
        "route_tree_clearance_removed": true,
        "terrain_traversal_smoothing_preserved": true,
        "future_path_policy": "terrain color/material only",
        "terrain_material_v744_preserved": true,
        "falloff_v742_preserved": true
    }

func get_forest_map_contract_v74() -> Dictionary:
    var contract: Dictionary = super.get_forest_map_contract_v74()
    contract["revision"] = "0.74.5"
    contract["path_visual_mode"] = "none"
    contract["path_geometry"] = false
    contract["path_tree_corridor"] = false
    contract["future_path_policy"] = "color/material only"
    # Trail material remains in the repository only as a dormant optional
    # resource for a possible future terrain-color treatment.
    contract["trail_material_active"] = false
    return contract
