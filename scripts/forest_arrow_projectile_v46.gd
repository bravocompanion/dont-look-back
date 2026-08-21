extends "res://scripts/forest_arrow_projectile_v44.gd"

# v0.46: recoverable arrows remain embedded in moving wildlife instead of
# freezing in mid-air at the world-space impact point.
var attached_target: Node3D = null
var attached_local_transform: Transform3D = Transform3D.IDENTITY

func _physics_process(delta: float) -> void:
    if flight_active:
        super._physics_process(delta)
        return
    _update_target_attachment()

func resolve_impact_attached(
    impact_position: Vector3,
    impact_normal: Vector3,
    can_recover: bool,
    target_node: Node3D
) -> void:
    super.resolve_impact(impact_position, impact_normal, can_recover)
    if not can_recover or target_node == null or not is_instance_valid(target_node):
        attached_target = null
        return

    # Do not bind to an already-dead/despawned animal. In that case the arrow
    # remains embedded at the final world-space impact point and can still be recovered.
    if not bool(target_node.get("alive")):
        attached_target = null
        return

    attached_target = target_node
    attached_local_transform = attached_target.global_transform.affine_inverse() * global_transform

func detach_from_target() -> void:
    attached_target = null

func _update_target_attachment() -> void:
    if attached_target == null:
        return
    if not is_instance_valid(attached_target):
        attached_target = null
        return

    # Follow translation and rotation of the animal while preserving the exact
    # impact orientation. This makes the arrow look physically embedded.
    global_transform = attached_target.global_transform * attached_local_transform

    # Wildlife becomes invisible/dead immediately on a lethal hit. Detach only
    # after copying its last transform so the recoverable arrow stays in-world.
    if not bool(attached_target.get("alive")) or not attached_target.visible:
        attached_target = null
