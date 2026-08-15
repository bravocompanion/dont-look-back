extends Node3D

@export var move_speed: float = 2.15
@export var light_retreat_speed: float = 4.2
@export var attack_damage: float = 18.0
@export var attack_distance: float = 1.15
@export var attack_cooldown: float = 2.0
@export var retreat_distance: float = 2.8
@export var max_lifetime: float = 18.0

var attack_timer: float = 0.0
var light_escape_timer: float = -1.0
var lifetime: float = 18.0

func _ready() -> void:
    add_to_group("darkness_creature")
    lifetime = max_lifetime
    _build_visual()

func _process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    lifetime = maxf(0.0, lifetime - delta)
    if lifetime <= 0.0:
        queue_free()
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        queue_free()
        return

    var in_light: bool = false
    if player.has_method("is_in_light"):
        in_light = bool(player.call("is_in_light"))

    if in_light:
        _retreat_from_light(player, delta)
        return

    light_escape_timer = -1.0
    var target: Vector3 = Vector3(player.global_position.x, global_position.y, player.global_position.z)
    var distance: float = global_position.distance_to(target)

    if distance > 0.05:
        var direction: Vector3 = (target - global_position).normalized()
        global_position += direction * move_speed * delta
        look_at(Vector3(player.global_position.x, global_position.y + 1.15, player.global_position.z), Vector3.UP)

    distance = global_position.distance_to(target)
    if distance <= attack_distance and attack_timer <= 0.0:
        _attack(player, target)

func _retreat_from_light(player: CharacterBody3D, delta: float) -> void:
    if light_escape_timer < 0.0:
        light_escape_timer = 0.72

    light_escape_timer -= delta
    var away: Vector3 = global_position - player.global_position
    away.y = 0.0
    if away.length() <= 0.01:
        away = Vector3(0.0, 0.0, 1.0)
    else:
        away = away.normalized()
    global_position += away * light_retreat_speed * delta

    if light_escape_timer <= 0.0:
        queue_free()

func _attack(player: CharacterBody3D, target: Vector3) -> void:
    attack_timer = attack_cooldown
    var died: bool = false
    if player.has_method("apply_damage"):
        died = bool(player.call("apply_damage", attack_damage, "the darkness"))

    if died:
        queue_free()
        return

    var away: Vector3 = global_position - target
    away.y = 0.0
    if away.length() <= 0.01:
        away = Vector3(0.0, 0.0, 1.0)
    else:
        away = away.normalized()
    global_position += away * retreat_distance

func _build_visual() -> void:
    var body_mesh: CapsuleMesh = CapsuleMesh.new()
    body_mesh.radius = 0.30
    body_mesh.height = 2.35
    body_mesh.radial_segments = 10
    body_mesh.rings = 5

    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.001, 0.001, 0.002, 1.0)
    body_material.roughness = 1.0

    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 1.25, 0.0)
    add_child(body)

    var eye_mesh: SphereMesh = SphereMesh.new()
    eye_mesh.radius = 0.04
    eye_mesh.height = 0.08
    eye_mesh.radial_segments = 8
    eye_mesh.rings = 4

    var eye_material: StandardMaterial3D = StandardMaterial3D.new()
    eye_material.albedo_color = Color(0.68, 0.72, 0.62, 1.0)
    eye_material.emission_enabled = true
    eye_material.emission = Color(0.55, 0.60, 0.48, 1.0)
    eye_material.emission_energy_multiplier = 3.0

    var left_eye: MeshInstance3D = MeshInstance3D.new()
    left_eye.mesh = eye_mesh
    left_eye.material_override = eye_material
    left_eye.position = Vector3(-0.10, 2.02, 0.27)
    add_child(left_eye)

    var right_eye: MeshInstance3D = MeshInstance3D.new()
    right_eye.mesh = eye_mesh
    right_eye.material_override = eye_material
    right_eye.position = Vector3(0.10, 2.02, 0.27)
    add_child(right_eye)
