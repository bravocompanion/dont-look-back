extends StaticBody3D

var projectile_id: int = 0
var shooter_peer_id: int = 0
var flight_velocity: Vector3 = Vector3.ZERO
var flight_active: bool = false
var recoverable: bool = false
var authoritative_simulation: bool = false
var damage_range: float = 38.0
var gravity_strength: float = 3.4
var max_lifetime: float = 8.0
var lifetime: float = 0.0
var travelled_distance: float = 0.0

var collision_shape: CollisionShape3D
var shaft_mesh: MeshInstance3D

func _ready() -> void:
    collision_layer = 0
    collision_mask = 0
    _build_visual()
    _build_recovery_collision()

func configure(
    id_value: int,
    peer_id: int,
    spawn_position: Vector3,
    launch_direction: Vector3,
    launch_speed: float,
    effective_damage_range: float,
    gravity_value: float,
    lifetime_value: float,
    is_authoritative: bool
) -> void:
    projectile_id = id_value
    shooter_peer_id = peer_id
    global_position = spawn_position
    damage_range = maxf(1.0, effective_damage_range)
    gravity_strength = maxf(0.0, gravity_value)
    max_lifetime = maxf(1.0, lifetime_value)
    authoritative_simulation = is_authoritative
    lifetime = max_lifetime
    travelled_distance = 0.0
    recoverable = false
    flight_active = true

    var direction: Vector3 = launch_direction.normalized()
    if direction.length_squared() <= 0.001:
        direction = Vector3(0.0, 0.0, -1.0)
    flight_velocity = direction * maxf(1.0, launch_speed)
    _orient_to_velocity()

func _physics_process(delta: float) -> void:
    if not flight_active:
        return

    lifetime = maxf(0.0, lifetime - delta)
    if lifetime <= 0.0:
        flight_active = false
        if authoritative_simulation:
            _notify_timeout()
        return

    var previous_position: Vector3 = global_position
    flight_velocity += Vector3.DOWN * gravity_strength * delta
    var next_position: Vector3 = previous_position + flight_velocity * delta
    var step_distance: float = previous_position.distance_to(next_position)

    if authoritative_simulation:
        var world: World3D = get_world_3d()
        if world != null:
            var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(previous_position, next_position)
            query.exclude = [get_rid()]
            query.collide_with_areas = false
            query.collide_with_bodies = true
            var hit: Dictionary = world.direct_space_state.intersect_ray(query)
            if not hit.is_empty():
                flight_active = false
                travelled_distance += previous_position.distance_to(Vector3(hit.get("position", next_position)))
                _notify_impact(hit)
                return

    global_position = next_position
    travelled_distance += step_distance
    _orient_to_velocity()

func resolve_impact(impact_position: Vector3, impact_normal: Vector3, can_recover: bool) -> void:
    flight_active = false
    recoverable = can_recover
    global_position = impact_position + impact_normal.normalized() * 0.025 if impact_normal.length_squared() > 0.001 else impact_position
    _orient_to_velocity()

    if recoverable:
        collision_layer = 1
        if collision_shape != null:
            collision_shape.disabled = false
        return

    collision_layer = 0
    if collision_shape != null:
        collision_shape.disabled = true
    visible = false
    queue_free()

func get_interaction_text() -> String:
    return "Recover Arrow" if recoverable and not flight_active else ""

func interact() -> void:
    if not recoverable or flight_active:
        return
    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system != null and system.has_method("request_arrow_recovery"):
        system.call("request_arrow_recovery", projectile_id)

func is_recoverable_arrow() -> bool:
    return recoverable and not flight_active

func _notify_impact(hit: Dictionary) -> void:
    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system == null or not system.has_method("on_arrow_projectile_hit"):
        queue_free()
        return

    var impact_position: Vector3 = Vector3(hit.get("position", global_position))
    var impact_normal: Vector3 = Vector3(hit.get("normal", Vector3.UP))
    var collider_value: Variant = hit.get("collider", null)
    var within_damage_range: bool = travelled_distance <= damage_range
    system.call(
        "on_arrow_projectile_hit",
        projectile_id,
        collider_value,
        impact_position,
        impact_normal,
        shooter_peer_id,
        within_damage_range
    )

func _notify_timeout() -> void:
    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system != null and system.has_method("on_arrow_projectile_timeout"):
        system.call("on_arrow_projectile_timeout", projectile_id, shooter_peer_id)
    else:
        queue_free()

func _orient_to_velocity() -> void:
    if flight_velocity.length_squared() <= 0.001:
        return
    look_at(global_position + flight_velocity.normalized(), Vector3.UP)

func _build_visual() -> void:
    var wood_material: StandardMaterial3D = StandardMaterial3D.new()
    wood_material.albedo_color = Color(0.24, 0.14, 0.075, 1.0)
    wood_material.roughness = 0.82

    var metal_material: StandardMaterial3D = StandardMaterial3D.new()
    metal_material.albedo_color = Color(0.22, 0.24, 0.25, 1.0)
    metal_material.metallic = 0.72
    metal_material.roughness = 0.36

    shaft_mesh = MeshInstance3D.new()
    shaft_mesh.name = "ArrowShaft"
    var shaft: CylinderMesh = CylinderMesh.new()
    shaft.top_radius = 0.012
    shaft.bottom_radius = 0.012
    shaft.height = 0.72
    shaft.radial_segments = 8
    shaft_mesh.mesh = shaft
    shaft_mesh.material_override = wood_material
    shaft_mesh.rotation.x = deg_to_rad(90.0)
    add_child(shaft_mesh)

    var tip_mesh: MeshInstance3D = MeshInstance3D.new()
    tip_mesh.name = "ArrowTip"
    var tip: CylinderMesh = CylinderMesh.new()
    tip.top_radius = 0.0
    tip.bottom_radius = 0.035
    tip.height = 0.12
    tip.radial_segments = 8
    tip_mesh.mesh = tip
    tip_mesh.material_override = metal_material
    tip_mesh.rotation.x = deg_to_rad(90.0)
    tip_mesh.position.z = -0.42
    add_child(tip_mesh)

    var feather_material: StandardMaterial3D = StandardMaterial3D.new()
    feather_material.albedo_color = Color(0.36, 0.16, 0.10, 1.0)
    feather_material.roughness = 0.9

    var feather: MeshInstance3D = MeshInstance3D.new()
    feather.name = "Fletching"
    var feather_mesh: BoxMesh = BoxMesh.new()
    feather_mesh.size = Vector3(0.095, 0.035, 0.14)
    feather.mesh = feather_mesh
    feather.material_override = feather_material
    feather.position.z = 0.30
    add_child(feather)

func _build_recovery_collision() -> void:
    collision_shape = CollisionShape3D.new()
    collision_shape.name = "RecoveryCollision"
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(0.13, 0.13, 0.78)
    collision_shape.shape = shape
    collision_shape.disabled = true
    add_child(collision_shape)
