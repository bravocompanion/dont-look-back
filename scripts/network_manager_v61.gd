extends "res://scripts/network_manager_v60.gd"

# v0.74.2: reject impossible Forest transforms on the host so a peer that
# briefly loses local floor contact cannot make its remote avatar disappear
# below/outside the expanded map for the rest of the party.

const FOREST_MIN_X_V742: float = -224.0
const FOREST_MAX_X_V742: float = 224.0
const FOREST_NEAR_Z_V742: float = -52.0
const FOREST_FAR_Z_V742: float = -660.0
const FOREST_REMOTE_BOUND_MARGIN_V742: float = 0.20
const FOREST_REMOTE_BELOW_TERRAIN_V742: float = 1.20
const FOREST_REMOTE_ABOVE_TERRAIN_V742: float = 14.0

func _validate_remote_transform_v57(peer_id: int, player_transform: Transform3D) -> bool:
    if not super._validate_remote_transform_v57(peer_id, player_transform):
        return false

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH_V60:
        return true

    var p: Vector3 = player_transform.origin
    if (
        p.x < FOREST_MIN_X_V742 + FOREST_REMOTE_BOUND_MARGIN_V742
        or p.x > FOREST_MAX_X_V742 - FOREST_REMOTE_BOUND_MARGIN_V742
        or p.z < FOREST_FAR_Z_V742 + FOREST_REMOTE_BOUND_MARGIN_V742
        or p.z > FOREST_NEAR_Z_V742 - FOREST_REMOTE_BOUND_MARGIN_V742
    ):
        return false

    var forest_safety: Node = get_node_or_null("/root/ForestWorldExpansion")
    if forest_safety == null or not forest_safety.has_method("sample_terrain_height_v74"):
        return true

    var terrain_y: float = float(forest_safety.call("sample_terrain_height_v74", p.x, p.z))
    if p.y < terrain_y - FOREST_REMOTE_BELOW_TERRAIN_V742:
        return false
    if p.y > terrain_y + FOREST_REMOTE_ABOVE_TERRAIN_V742:
        return false
    return true

func get_forest_remote_transform_contract_v742() -> Dictionary:
    return {
        "host_rejects_out_of_bounds": true,
        "host_rejects_below_terrain": true,
        "bound_margin_m": FOREST_REMOTE_BOUND_MARGIN_V742,
        "below_terrain_tolerance_m": FOREST_REMOTE_BELOW_TERRAIN_V742,
        "above_terrain_tolerance_m": FOREST_REMOTE_ABOVE_TERRAIN_V742
    }
