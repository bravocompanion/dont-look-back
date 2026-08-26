extends "res://scripts/forest_world_expansion_v6.gd"

# v0.74.2 — fall-through/fall-off hardening.
# This revision keeps v0.74.1 terrain shaping, but treats player containment as
# a gameplay invariant instead of relying on a single boundary wall/recovery Y.

const V742_SAFE_MARGIN: float = 1.25
const V742_BELOW_TERRAIN_TOLERANCE: float = 0.72
const V742_RECOVERY_CLEARANCE: float = 0.10
const V742_UNDERLAY_TOP_Y: float = -4.20
const V742_UNDERLAY_THICKNESS: float = 0.60
const V742_EMERGENCY_Y: float = -4.75

var _v742_safe_position: Vector3 = Vector3(14.0, 0.92, -90.0)
var _v742_has_safe_position: bool = false
var _v742_scene_id: int = 0
var _v742_recovery_count: int = 0

func _build_mega_ground() -> void:
    super._build_mega_ground()
    _harden_terrain_collision_v742()
    _build_terrain_underlay_v742()

func _harden_terrain_collision_v742() -> void:
    if world_root == null:
        return
    var terrain: StaticBody3D = world_root.get_node_or_null("ForestTerrainV74") as StaticBody3D
    if terrain == null:
        return

    terrain.collision_layer = 1
    terrain.collision_mask = 1
    var collision: CollisionShape3D = terrain.get_node_or_null("TerrainCollision") as CollisionShape3D
    if collision == null or collision.shape == null:
        return
    collision.disabled = false
    if collision.shape is ConcavePolygonShape3D:
        var concave: ConcavePolygonShape3D = collision.shape as ConcavePolygonShape3D
        concave.backface_collision = true

func _build_terrain_underlay_v742() -> void:
    if world_root == null or world_root.has_node("TerrainSafetyUnderlayV742"):
        return

    # Invisible final catch surface. It is deliberately below the lowest legal
    # terrain height, so it never changes normal walking; its only purpose is to
    # stop a body from falling forever if the trimesh ever misses a contact.
    var body: StaticBody3D = StaticBody3D.new()
    body.name = "TerrainSafetyUnderlayV742"
    body.position = Vector3(
        0.0,
        V742_UNDERLAY_TOP_Y - V742_UNDERLAY_THICKNESS * 0.5,
        V74_MAP_CENTER_Z
    )
    body.collision_layer = 1
    body.collision_mask = 1
    world_root.add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.name = "UnderlayCollision"
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(
        V74_MAP_WIDTH - V742_SAFE_MARGIN * 2.0,
        V742_UNDERLAY_THICKNESS,
        V74_MAP_DEPTH - V742_SAFE_MARGIN * 2.0
    )
    collision.shape = shape
    body.add_child(collision)

func _physics_process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        _reset_forest_safety_state_v742()
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != _v742_scene_id:
        _v742_scene_id = scene_id
        _v742_safe_position = Vector3(14.0, 0.92, -90.0)
        _v742_has_safe_position = false
        _v742_recovery_count = 0

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not is_instance_valid(player):
        return
    enforce_player_safety_v742(player)

func enforce_player_safety_v742(player: CharacterBody3D) -> bool:
    if player == null or not is_instance_valid(player):
        return false
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        return false
    if bool(player.get("is_dead")):
        return false

    var position_value: Vector3 = player.global_position
    if not position_value.is_finite():
        _recover_player_v742(player, true)
        return true

    var half_height: float = _player_half_height_v742(player)

    # Hard horizontal containment runs after locomotion. Physics walls remain
    # the normal blocker, but even tunnelling/edge misses cannot leave bounds.
    var clamped_x: float = clampf(
        position_value.x,
        V74_MAP_MIN_X + V742_SAFE_MARGIN,
        V74_MAP_MAX_X - V742_SAFE_MARGIN
    )
    var clamped_z: float = clampf(
        position_value.z,
        V74_MAP_FAR_Z + V742_SAFE_MARGIN,
        V74_MAP_NEAR_Z - V742_SAFE_MARGIN
    )
    var escaped_horizontal: bool = (
        not is_equal_approx(clamped_x, position_value.x)
        or not is_equal_approx(clamped_z, position_value.z)
    )
    if escaped_horizontal:
        position_value.x = clamped_x
        position_value.z = clamped_z
        var boundary_ground: float = sample_terrain_height_v74(clamped_x, clamped_z)
        position_value.y = maxf(position_value.y, boundary_ground + half_height + V742_RECOVERY_CLEARANCE)
        player.global_position = position_value
        player.velocity.x = 0.0
        player.velocity.z = 0.0
        player.velocity.y = maxf(0.0, player.velocity.y)

    var terrain_y: float = sample_terrain_height_v74(player.global_position.x, player.global_position.z)
    var expected_center_y: float = terrain_y + half_height
    var below_terrain: bool = player.global_position.y < expected_center_y - V742_BELOW_TERRAIN_TOLERANCE
    var emergency_fall: bool = player.global_position.y < V742_EMERGENCY_Y

    if below_terrain or emergency_fall:
        _recover_player_v742(player, false)
        return true

    # Store only positions confirmed by CharacterBody floor contact and still
    # plausible relative to the authored terrain. Building floors are allowed
    # to sit above this reference; under-map/underlay positions are not.
    if player.is_on_floor() and _inside_hard_bounds_v742(player.global_position):
        if player.global_position.y >= expected_center_y - 0.42:
            _v742_safe_position = player.global_position
            _v742_has_safe_position = true
    return escaped_horizontal

func _recover_player_v742(player: CharacterBody3D, force_spawn: bool) -> void:
    var half_height: float = _player_half_height_v742(player)
    var target: Vector3 = Vector3(14.0, 0.92, -90.0)
    if _v742_has_safe_position and not force_spawn:
        target = _v742_safe_position

    target.x = clampf(target.x, V74_MAP_MIN_X + V742_SAFE_MARGIN + 0.5, V74_MAP_MAX_X - V742_SAFE_MARGIN - 0.5)
    target.z = clampf(target.z, V74_MAP_FAR_Z + V742_SAFE_MARGIN + 0.5, V74_MAP_NEAR_Z - V742_SAFE_MARGIN - 0.5)
    var ground_y: float = sample_terrain_height_v74(target.x, target.z)
    target.y = maxf(target.y, ground_y + half_height + V742_RECOVERY_CLEARANCE)

    player.global_position = target
    player.velocity = Vector3.ZERO
    player.reset_physics_interpolation()
    _v742_safe_position = target
    _v742_has_safe_position = true
    _v742_recovery_count += 1

func _inside_hard_bounds_v742(position_value: Vector3) -> bool:
    return (
        position_value.x >= V74_MAP_MIN_X + V742_SAFE_MARGIN
        and position_value.x <= V74_MAP_MAX_X - V742_SAFE_MARGIN
        and position_value.z >= V74_MAP_FAR_Z + V742_SAFE_MARGIN
        and position_value.z <= V74_MAP_NEAR_Z - V742_SAFE_MARGIN
    )

func _player_half_height_v742(player: CharacterBody3D) -> float:
    var collision: CollisionShape3D = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null and collision.shape is CapsuleShape3D:
        var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
        return maxf(0.40, capsule.height * 0.5)
    return 0.875

func _reset_forest_safety_state_v742() -> void:
    _v742_scene_id = 0
    _v742_has_safe_position = false
    _v742_recovery_count = 0

func is_forest_terrain_ready_v742() -> bool:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        return false
    var terrain: StaticBody3D = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2/ForestTerrainV74") as StaticBody3D
    if terrain == null:
        return false
    var collision: CollisionShape3D = terrain.get_node_or_null("TerrainCollision") as CollisionShape3D
    if collision == null or collision.shape == null or collision.disabled:
        return false
    var underlay: StaticBody3D = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2/TerrainSafetyUnderlayV742") as StaticBody3D
    if underlay == null:
        return false
    var underlay_collision: CollisionShape3D = underlay.get_node_or_null("UnderlayCollision") as CollisionShape3D
    return underlay_collision != null and underlay_collision.shape != null and not underlay_collision.disabled

func get_fall_safety_contract_v742() -> Dictionary:
    return {
        "revision": "0.74.2",
        "hard_bounds_margin_m": V742_SAFE_MARGIN,
        "below_terrain_tolerance_m": V742_BELOW_TERRAIN_TOLERANCE,
        "emergency_y": V742_EMERGENCY_Y,
        "underlay_top_y": V742_UNDERLAY_TOP_Y,
        "terrain_backface_collision": true,
        "recovery_count": _v742_recovery_count,
        "terrain_ready": is_forest_terrain_ready_v742()
    }
