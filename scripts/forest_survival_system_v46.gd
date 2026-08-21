extends "res://scripts/forest_survival_system_v45.gd"

const ARROW_PROJECTILE_V46_SCRIPT_PATH: String = "res://scripts/forest_arrow_projectile_v46.gd"

var arrow_impact_target_ids: Dictionary = {}

func _ready() -> void:
    super._ready()
    arrow_projectile_script = load(ARROW_PROJECTILE_V46_SCRIPT_PATH) as Script

func on_arrow_projectile_hit(
    projectile_id: int,
    collider_value: Variant,
    impact_position: Vector3,
    impact_normal: Vector3,
    shooter_peer_id: int,
    within_damage_range: bool
) -> void:
    var animal: Node = _wildlife_from_collider(collider_value)
    if animal != null:
        arrow_impact_target_ids[projectile_id] = str(animal.get("animal_id"))
    else:
        arrow_impact_target_ids.erase(projectile_id)

    # v0.45 still owns HP, draw-power damage, distance falloff and 20% break chance.
    # Our overridden impact broadcaster below adds the target attachment identity.
    super.on_arrow_projectile_hit(
        projectile_id,
        collider_value,
        impact_position,
        impact_normal,
        shooter_peer_id,
        within_damage_range
    )
    arrow_impact_target_ids.erase(projectile_id)

func _broadcast_arrow_impact(
    projectile_id: int,
    impact_position: Vector3,
    impact_normal: Vector3,
    can_recover: bool
) -> void:
    var target_animal_id: String = str(arrow_impact_target_ids.get(projectile_id, ""))
    if _network_online():
        _resolve_arrow_impact_v46_remote.rpc(
            projectile_id,
            impact_position,
            impact_normal,
            can_recover,
            target_animal_id
        )
    else:
        _resolve_arrow_impact_v46_remote(
            projectile_id,
            impact_position,
            impact_normal,
            can_recover,
            target_animal_id
        )

@rpc("authority", "call_local", "reliable", 38)
func _resolve_arrow_impact_v46_remote(
    projectile_id: int,
    impact_position: Vector3,
    impact_normal: Vector3,
    can_recover: bool,
    target_animal_id: String
) -> void:
    var projectile: Node = arrow_projectiles.get(projectile_id, null) as Node
    if projectile == null or not is_instance_valid(projectile):
        arrow_projectiles.erase(projectile_id)
        return

    var target_node: Node3D = null
    if not target_animal_id.is_empty():
        target_node = animals.get(target_animal_id, null) as Node3D

    if projectile.has_method("resolve_impact_attached"):
        projectile.call(
            "resolve_impact_attached",
            impact_position,
            impact_normal,
            can_recover,
            target_node
        )
    elif projectile.has_method("resolve_impact"):
        projectile.call("resolve_impact", impact_position, impact_normal, can_recover)

    if not can_recover:
        arrow_projectiles.erase(projectile_id)
        arrow_claims.erase(projectile_id)
