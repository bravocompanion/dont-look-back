extends "res://scripts/map_transition_system_v2.gd"

# v0.74.2: Forest is not considered ready until the expanded terrain collision
# and emergency underlay exist. The legacy ForestGround only covers the cabin
# sector and is insufficient for deep-forest return spawns such as Z=-334.

func _scene_world_ready(scene: Node, scene_path: String) -> bool:
    if scene_path != RANGER_FOREST_SCENE:
        return super._scene_world_ready(scene, scene_path)
    if scene == null:
        return false

    var terrain: StaticBody3D = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2/ForestTerrainV74") as StaticBody3D
    if terrain == null:
        return false
    var terrain_collision: CollisionShape3D = terrain.get_node_or_null("TerrainCollision") as CollisionShape3D
    if terrain_collision == null or terrain_collision.shape == null or terrain_collision.disabled:
        return false

    var underlay: StaticBody3D = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2/TerrainSafetyUnderlayV742") as StaticBody3D
    if underlay == null:
        return false
    var underlay_collision: CollisionShape3D = underlay.get_node_or_null("UnderlayCollision") as CollisionShape3D
    if underlay_collision == null or underlay_collision.shape == null or underlay_collision.disabled:
        return false

    var forest_safety: Node = get_node_or_null("/root/ForestWorldExpansion")
    if forest_safety != null and forest_safety.has_method("is_forest_terrain_ready_v742"):
        return bool(forest_safety.call("is_forest_terrain_ready_v742"))
    return true

func get_forest_transition_readiness_contract_v742() -> Dictionary:
    return {
        "legacy_forest_ground_is_sufficient": false,
        "requires_expanded_terrain_collision": true,
        "requires_emergency_underlay": true,
        "deep_return_spawn": FOREST_MINE_RETURN_SPAWN
    }
