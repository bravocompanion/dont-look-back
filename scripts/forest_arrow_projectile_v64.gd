extends "res://scripts/forest_arrow_projectile_v46.gd"

# v0.64: a recoverable arrow embedded in living wildlife must remain targetable
# by the interaction ray without becoming a physics obstacle for that wildlife.
# Layer 2 is already used by interaction-only corpse bodies: the player's
# interaction ray sees it, while normal movement/wildlife collision mask 1 does not.
const ATTACHED_ARROW_INTERACTION_LAYER_V64: int = 2

func resolve_impact_attached(
    impact_position: Vector3,
    impact_normal: Vector3,
    can_recover: bool,
    target_node: Node3D
) -> void:
    super.resolve_impact_attached(
        impact_position,
        impact_normal,
        can_recover,
        target_node
    )

    if not can_recover or attached_target == null or not is_instance_valid(attached_target):
        return

    # Parent resolve_impact temporarily schedules collision layer 1 for a
    # recoverable arrow. Override that deferred value in the same frame so the
    # final layer is interaction-only and never an obstacle to the animal.
    set_deferred("collision_layer", ATTACHED_ARROW_INTERACTION_LAYER_V64)
    if collision_shape != null:
        collision_shape.set_deferred("disabled", false)

    # The explicit exception closes the one-frame physics edge case before the
    # deferred layer update is committed and also protects future layer changes.
    if attached_target is PhysicsBody3D:
        var target_body: PhysicsBody3D = attached_target as PhysicsBody3D
        target_body.add_collision_exception_with(self)
        add_collision_exception_with(target_body)

func get_attachment_collision_contract_v64() -> Dictionary:
    return {
        "interaction_layer": ATTACHED_ARROW_INTERACTION_LAYER_V64,
        "blocks_wildlife": false,
        "explicit_collision_exception": true,
        "recoverable_while_attached": true
    }
